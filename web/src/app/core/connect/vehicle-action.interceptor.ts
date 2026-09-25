import { type Interceptor } from '@connectrpc/connect';

/**
 * VehicleService methods that actuate the physical car and therefore require the short-lived
 * action token on top of the session JWT (uy93.5, restored on Connect by BladeWatch-jwko).
 *
 * This list MUST match `VehicleActionGate.ACTUATING` on the daemon. The server is the one that
 * enforces — a mismatch here does not weaken anything, it just means the call is refused with
 * `permission_denied` because no token was attached. Keeping them in step is what stops the
 * Vehicle page appearing broken after someone adds a command.
 */
const ACTUATING = new Set([
  'SetClimate',
  'MoveWindow',
  'Trunk',
  'SetLights',
  'SetAdas',
  'SetChargeCap',
  'SetScreen',
  'SetMediaVolume',
]);

/** A token, and the moment it stops being usable. */
interface CachedToken {
  token: string;
  expiresAtMs: number;
}

let cached: CachedToken | null = null;
let inFlight: Promise<string | null> | null = null;

/**
 * Discard the cache. Exported for tests — a stale token between tests would let one test's
 * token satisfy another's assertion.
 */
export function resetVehicleActionToken(): void {
  cached = null;
  inFlight = null;
}

/**
 * Fetch a fresh token over the ConnectRPC issuer.
 *
 * Deliberately a plain fetch rather than the typed client: this runs INSIDE an interceptor, and
 * going back through the same transport would re-enter the interceptor chain. IssueActionToken
 * is not itself actuating, so it would not recurse — but relying on that is a trap for whoever
 * next edits the ACTUATING list.
 */
async function fetchToken(): Promise<string | null> {
  try {
    const resp = await fetch('/bladewatch.v1.VehicleService/IssueActionToken', {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'Connect-Protocol-Version': '1',
      },
      body: '{}',
    });
    if (!resp.ok) return null;
    const data = (await resp.json()) as {
      success?: boolean;
      token?: string;
      expiresInSeconds?: number;
    };
    if (!data.success || !data.token) return null;
    // Renew a second early: a token that expires in transit is indistinguishable from a
    // rejected one, and the retry would look to the user like the command silently failed.
    const lifetimeMs = Math.max(0, (data.expiresInSeconds ?? 0) - 1) * 1000;
    cached = { token: data.token, expiresAtMs: Date.now() + lifetimeMs };
    return data.token;
  } catch {
    return null;
  }
}

/** The cached token when it is still good, otherwise a fresh one. */
async function currentToken(): Promise<string | null> {
  if (cached && cached.expiresAtMs > Date.now()) return cached.token;
  // Collapse concurrent commands onto one issue call — tapping two controls at once should
  // not mint two tokens and race them.
  if (!inFlight) {
    inFlight = fetchToken().finally(() => {
      inFlight = null;
    });
  }
  return inFlight;
}

/**
 * Attaches `X-Vehicle-Action-Token` to actuating VehicleService calls.
 *
 * The in-car UI reaches the daemon over loopback and is exempt server-side, so this only
 * matters for a browser over the tunnel or the LAN — which is exactly the threat model the
 * second factor was added for.
 */
export const vehicleActionInterceptor: Interceptor = (next) => async (req) => {
  if (req.service.typeName === 'bladewatch.v1.VehicleService' && ACTUATING.has(req.method.name)) {
    const token = await currentToken();
    // No token attached means the server refuses with permission_denied, which is the correct
    // outcome: failing open here would defeat the whole control.
    if (token) req.header.set('X-Vehicle-Action-Token', token);
  }
  return next(req);
};
