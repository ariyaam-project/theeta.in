import { Hono } from 'hono'
import type { AppEnv } from '../types'
import { createAuthSession, upsertGoogleUser } from '../lib/auth'
import { apiError } from '../lib/http'
import { assertSameOrigin } from '../lib/security'

export const devRoutes = new Hono<AppEnv>()
export const devPageRoutes = new Hono<AppEnv>()

function assertLocalDev(appUrl: string) {
  const host = new URL(appUrl).hostname
  if (host !== 'localhost' && host !== '127.0.0.1') {
    apiError(404, 'Not found')
  }
}

devRoutes.post('/login', async (c) => {
  assertLocalDev(c.env.APP_URL)
  assertSameOrigin(c)
  const body = await c.req.json<{ email?: string; name?: string }>().catch(() => ({}) as any)
  const email = typeof body.email === 'string' && body.email.trim() ? body.email.trim() : 'dev@theta.local'
  const name = typeof body.name === 'string' && body.name.trim() ? body.name.trim() : 'Theta Dev User'

  const userId = await upsertGoogleUser(c, {
    sub: `dev:${email}`,
    email,
    email_verified: true,
    name
  })
  const session = await createAuthSession(c, userId)
  const user = { id: userId, displayName: name, avatarUrl: null, email }
  return c.json({ ok: true, token: session.token, expiresAt: session.expiresAt, user })
})

devPageRoutes.get('/dev', (c) => {
  assertLocalDev(c.env.APP_URL)
  return c.html(DEV_HTML)
})

const DEV_HTML = String.raw`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Theta API Dev Harness</title>
  <style>
    :root { color-scheme: dark; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    body { margin: 0; background: #0b1117; color: #e6edf3; }
    main { max-width: 1120px; margin: 0 auto; padding: 32px 20px 64px; }
    h1 { margin: 0 0 8px; font-size: 28px; }
    h2 { margin: 0 0 16px; font-size: 18px; }
    p { color: #9aa4b2; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 16px; }
    .card { background: #111923; border: 1px solid #263241; border-radius: 14px; padding: 18px; }
    label { display: block; margin: 12px 0 6px; color: #b7c2d0; font-size: 13px; }
    input, textarea { width: 100%; box-sizing: border-box; border: 1px solid #2f3d4d; border-radius: 10px; background: #0d141c; color: #e6edf3; padding: 11px 12px; font: inherit; }
    textarea { min-height: 92px; resize: vertical; }
    button, a.button { display: inline-block; margin: 8px 8px 0 0; border: 0; border-radius: 999px; background: #2f81f7; color: white; padding: 10px 14px; font: inherit; cursor: pointer; text-decoration: none; }
    button.secondary, a.secondary { background: #263241; }
    button.danger { background: #da3633; }
    .row { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
    .pill { display: inline-block; border: 1px solid #2f3d4d; border-radius: 999px; padding: 4px 10px; color: #b7c2d0; font-size: 12px; }
    pre { white-space: pre-wrap; word-break: break-word; background: #05080d; border: 1px solid #263241; border-radius: 12px; padding: 14px; max-height: 420px; overflow: auto; }
    .ok { color: #3fb950; }
    .warn { color: #d29922; }
  </style>
</head>
<body>
  <main>
    <h1>Theta API Dev Harness</h1>
    <p>Same-origin tester for auth, reel save, async processing status, saved reels, and detail APIs.</p>

    <section class="grid">
      <div class="card">
        <h2>1. Auth</h2>
        <p><span id="authState" class="pill">unknown</span></p>
        <label>Email for local dev login</label>
        <input id="devEmail" value="dev@theta.local" />
        <div class="row">
          <button id="devLogin">Local Dev Login</button>
          <a class="button secondary" href="/api/auth/google">Google OAuth</a>
          <button class="danger" id="logout">Logout</button>
          <button class="secondary" id="me">GET /api/me</button>
        </div>
      </div>

      <div class="card">
        <h2>2. Save Reel</h2>
        <label>Instagram reel URL</label>
        <textarea id="reelUrl" placeholder="https://www.instagram.com/reel/.../"></textarea>
        <div class="row">
          <button id="saveReel">POST /api/reels</button>
          <button class="secondary" id="pollStatus">Poll Status</button>
          <button class="secondary" id="detail">Get Detail</button>
        </div>
        <p>Current reel: <span id="currentReel" class="pill">none</span></p>
      </div>

      <div class="card">
        <h2>3. Saved Reels</h2>
        <button id="savedList">GET /api/reels/saved/list</button>
        <pre id="savedOutput">{}</pre>
      </div>
    </section>

    <section class="card" style="margin-top:16px">
      <h2>API Log</h2>
      <pre id="log">Ready.</pre>
    </section>
  </main>

  <script>
    let currentReelId = localStorage.getItem('theta.currentReelId') || '';
    let pollTimer = null;

    const el = (id) => document.getElementById(id);
    const log = (label, data) => {
      el('log').textContent = label + '\n' + JSON.stringify(data, null, 2);
    };
    const setCurrent = (id) => {
      currentReelId = id || '';
      if (id) localStorage.setItem('theta.currentReelId', id);
      el('currentReel').textContent = id || 'none';
    };

    async function call(path, options = {}) {
      const response = await fetch(path, {
        credentials: 'include',
        headers: { 'content-type': 'application/json', ...(options.headers || {}) },
        ...options
      });
      const text = await response.text();
      let json = null;
      try { json = text ? JSON.parse(text) : null; } catch { json = text; }
      if (!response.ok) throw { status: response.status, body: json };
      return json;
    }

    async function refreshMe() {
      try {
        const data = await call('/api/me');
        el('authState').textContent = data.user ? 'logged in: ' + data.user.email : 'logged out';
        el('authState').className = data.user ? 'pill ok' : 'pill warn';
        return data;
      } catch (error) {
        el('authState').textContent = 'auth check failed';
        throw error;
      }
    }

    async function statusOnce() {
      if (!currentReelId) throw new Error('No current reel id');
      const data = await call('/api/reels/' + currentReelId + '/status');
      log('GET /api/reels/' + currentReelId + '/status', data);
      if (data.status === 'complete' || data.status === 'failed') {
        clearInterval(pollTimer);
        pollTimer = null;
      }
      return data;
    }

    el('devLogin').onclick = async () => {
      try {
        const data = await call('/api/dev/login', {
          method: 'POST',
          body: JSON.stringify({ email: el('devEmail').value })
        });
        log('POST /api/dev/login', data);
        await refreshMe();
      } catch (error) { log('Dev login error', error); }
    };

    el('logout').onclick = async () => {
      try {
        const data = await call('/api/auth/logout', { method: 'POST', body: '{}' });
        log('POST /api/auth/logout', data);
        await refreshMe();
      } catch (error) { log('Logout error', error); }
    };

    el('me').onclick = async () => {
      try { log('GET /api/me', await refreshMe()); } catch (error) { log('Me error', error); }
    };

    el('saveReel').onclick = async () => {
      try {
        const data = await call('/api/reels', {
          method: 'POST',
          body: JSON.stringify({ url: el('reelUrl').value })
        });
        setCurrent(data.reel.id);
        log('POST /api/reels', data);
      } catch (error) { log('Save reel error', error); }
    };

    el('pollStatus').onclick = async () => {
      try {
        await statusOnce();
        clearInterval(pollTimer);
        pollTimer = setInterval(() => statusOnce().catch((error) => log('Poll error', error)), 3000);
      } catch (error) { log('Poll error', error); }
    };

    el('detail').onclick = async () => {
      try {
        if (!currentReelId) throw new Error('No current reel id');
        log('GET /api/reels/' + currentReelId, await call('/api/reels/' + currentReelId));
      } catch (error) { log('Detail error', error); }
    };

    el('savedList').onclick = async () => {
      try {
        const data = await call('/api/reels/saved/list');
        el('savedOutput').textContent = JSON.stringify(data, null, 2);
        log('GET /api/reels/saved/list', data);
      } catch (error) { log('Saved list error', error); }
    };

    setCurrent(currentReelId);
    refreshMe().catch((error) => log('Initial auth error', error));
  </script>
</body>
</html>`
