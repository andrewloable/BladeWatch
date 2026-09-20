import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { vehicleActionInterceptor, resetVehicleActionToken } from './vehicle-action.interceptor';

/**
 * BladeWatch-jwko: actuating vehicle commands carry the second factor.
 *
 * The server enforces; this only decides whether a token is attached. A command that goes out
 * without one is refused with permission_denied, so the failure mode is a Vehicle page that
 * looks broken — not a security hole. The case worth pinning is the opposite: that the
 * interceptor does not attach a token to reads (pointless round trip on every page load) and
 * does not recurse on the issuer itself.
 */
function fakeReq(typeName: string, methodName: string) {
  return {
    service: { typeName },
    method: { name: methodName },
    header: new Headers(),
  } as never;
}

describe('vehicleActionInterceptor', () => {
  let fetchMock: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    resetVehicleActionToken();
    fetchMock = vi.fn(async () =>
      new Response(JSON.stringify({ success: true, token: 'tok-1', expiresInSeconds: 30 }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    vi.stubGlobal('fetch', fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  const run = async (typeName: string, method: string) => {
    const req = fakeReq(typeName, method);
    const next = vi.fn(async (r: never) => r);
    await vehicleActionInterceptor(next)(req);
    return req as unknown as { header: Headers };
  };

  it('attaches the token to an actuating command', async () => {
    const req = await run('bladewatch.v1.VehicleService', 'Trunk');
    expect(req.header.get('X-Vehicle-Action-Token')).toBe('tok-1');
  });

  it('does not attach a token to a read', async () => {
    const req = await run('bladewatch.v1.VehicleService', 'GetState');
    expect(req.header.get('X-Vehicle-Action-Token')).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('does not attach a token when issuing one', async () => {
    // Gating the issuer would make the token unobtainable — you would need one to get one.
    const req = await run('bladewatch.v1.VehicleService', 'IssueActionToken');
    expect(req.header.get('X-Vehicle-Action-Token')).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('leaves other services alone', async () => {
    const req = await run('bladewatch.v1.TripsService', 'DeleteTrip');
    expect(req.header.get('X-Vehicle-Action-Token')).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('reuses a live token instead of minting one per command', async () => {
    await run('bladewatch.v1.VehicleService', 'Trunk');
    await run('bladewatch.v1.VehicleService', 'SetClimate');
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('collapses concurrent commands onto a single issue call', async () => {
    // Tapping two controls at once must not mint two tokens and race them.
    await Promise.all([
      run('bladewatch.v1.VehicleService', 'Trunk'),
      run('bladewatch.v1.VehicleService', 'MoveWindow'),
    ]);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('sends the command without a token when issuing fails, rather than failing open', async () => {
    fetchMock.mockImplementation(async () => new Response('nope', { status: 500 }));
    const req = await run('bladewatch.v1.VehicleService', 'Trunk');
    // No header: the server then refuses. Inventing a header, or skipping the command
    // client-side, would both be worse than letting the server decide.
    expect(req.header.get('X-Vehicle-Action-Token')).toBeNull();
  });
});
