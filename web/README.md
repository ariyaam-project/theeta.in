# Theeta Web

Nuxt test web app for the reel save and AI location-resolution flow.

## Local Run

Start the Worker API first:

```bash
cd ../apis
npm run dev -- --ip 127.0.0.1 --port 8787
```

Then start Nuxt:

```bash
cd ../web
npm install
npm run dev
```

The app proxies `/api/**` to `THETA_API_BASE`, defaulting to `http://127.0.0.1:8787`.

```bash
THETA_API_BASE=http://127.0.0.1:8787 npm run dev
```

Use local dev login on the landing page, paste a reel URL in the dashboard, and watch the saved/processing status.
