import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { authInterceptor, getCookieValue } from './auth.interceptor';

/**
 * Cookie parsing sits on the auth path: every outgoing RPC depends on it finding the session
 * token. The failure that matters is a regex matching a cookie whose name merely CONTAINS or
 * ENDS WITH the one asked for — the request would then carry a plausible-looking wrong token
 * and fail with permission_denied, which reads like a server problem rather than a client bug.
 */
describe('getCookieValue', () => {
  let cookieJar = '';

  beforeEach(() => {
    cookieJar = '';
    vi.stubGlobal('document', {
      get cookie() {
        return cookieJar;
      },
    });
  });

  afterEach(() => vi.unstubAllGlobals());

  const setCookies = (raw: string) => {
    cookieJar = raw;
  };

  it('reads a cookie that is the only one set', () => {
    setCookies('byd_session=abc123');
    expect(getCookieValue('byd_session')).toBe('abc123');
  });

  it('reads a cookie from the middle of several', () => {
    setCookies('theme=dark; byd_session=abc123; lang=en');
    expect(getCookieValue('byd_session')).toBe('abc123');
  });

  it('reads the first cookie when others follow', () => {
    setCookies('byd_session=abc123; theme=dark');
    expect(getCookieValue('byd_session')).toBe('abc123');
  });

  it('returns null when the cookie is absent', () => {
    setCookies('theme=dark; lang=en');
    expect(getCookieValue('byd_session')).toBeNull();
  });

  it('returns null when nothing is set at all', () => {
    setCookies('');
    expect(getCookieValue('byd_session')).toBeNull();
  });

  /**
   * THE case worth guarding. A name-suffix match would pull "wrong" out of
   * "other_byd_session" and attach it as the bearer token.
   */
  it('does not match a cookie whose name merely ends with the requested one', () => {
    setCookies('other_byd_session=wrong');
    expect(getCookieValue('byd_session')).toBeNull();
  });

  it('prefers the exact name when a decoy is present', () => {
    setCookies('other_byd_session=wrong; byd_session=right');
    expect(getCookieValue('byd_session')).toBe('right');
  });

  /** JWTs are URL-encoded into the cookie; a token handed back still encoded would not auth. */
  it('URL-decodes the value', () => {
    setCookies('byd_session=a%20b%2Bc');
    expect(getCookieValue('byd_session')).toBe('a b+c');
  });

  it('handles an empty value without throwing', () => {
    setCookies('byd_session=');
    expect(getCookieValue('byd_session')).toBe('');
  });

  it('tolerates the space-after-semicolon convention', () => {
    setCookies('theme=dark;byd_session=nospace');
    expect(getCookieValue('byd_session')).toBe('nospace');
  });
});

/**
 * The interceptor itself, which `getCookieValue` only feeds. This is the code that decides
 * whether credentials leave the browser at all, and it had no test — the previous spec covered
 * the cookie parsing underneath it and stopped there.
 *
 * Two failures matter and neither is visible from the parsing tests. Attaching no header when a
 * session exists logs the owner out of a working session. Attaching an EMPTY Bearer header when
 * no session exists is worse than attaching nothing: the server sees a malformed credential
 * rather than an anonymous request, so the response is a parse/auth error instead of the clean
 * permission_denied the pages redirect to /login on.
 */
describe('authInterceptor', () => {
  let cookieJar = '';

  beforeEach(() => {
    cookieJar = '';
    vi.stubGlobal('document', {
      get cookie() {
        return cookieJar;
      },
    });
  });

  afterEach(() => vi.unstubAllGlobals());

  /** Minimal stand-in for a Connect request: only `header` is touched by the interceptor. */
  const makeReq = () => ({ header: new Headers() });

  const run = async () => {
    const req = makeReq();
    const next = vi.fn(async (r: unknown) => ({ ok: true, req: r }));
    // The interceptor's contract is (next) => (req) => response.
    const res = await (authInterceptor as unknown as (n: typeof next) => (r: typeof req) => Promise<unknown>)(next)(req);
    return { req, next, res };
  };

  it('attaches the session cookie as a Bearer token', async () => {
    cookieJar = 'byd_session=abc123';
    const { req } = await run();
    expect(req.header.get('Authorization')).toBe('Bearer abc123');
  });

  it('URL-decodes the token, so a padded or encoded JWT is sent verbatim', async () => {
    cookieJar = 'byd_session=a.b%2Bc%3D';
    const { req } = await run();
    expect(req.header.get('Authorization')).toBe('Bearer a.b+c=');
  });

  it('sends NO Authorization header when there is no session', async () => {
    cookieJar = 'theme=dark';
    const { req } = await run();
    expect(
      req.header.has('Authorization'),
      'an empty Bearer header reads as a malformed credential, not as anonymous',
    ).toBe(false);
  });

  it('sends no header when the session cookie is present but empty', async () => {
    cookieJar = 'byd_session=';
    const { req } = await run();
    expect(req.header.has('Authorization')).toBe(false);
  });

  it('does not mistake a cookie whose name merely ends with the session name', async () => {
    cookieJar = 'not_byd_session=attacker';
    const { req } = await run();
    expect(req.header.has('Authorization')).toBe(false);
  });

  it('always forwards the request to the next interceptor', async () => {
    cookieJar = 'byd_session=abc123';
    const { next, req, res } = await run();
    expect(next).toHaveBeenCalledTimes(1);
    expect(next).toHaveBeenCalledWith(req);
    expect(res).toEqual({ ok: true, req });
  });
});
