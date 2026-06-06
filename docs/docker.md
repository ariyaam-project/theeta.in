# Docker

## Local Development

The local compose stack runs the full development surface:

- `api`: Hono API through `wrangler dev` with local D1 exposed through `https://aerosol-reformer-twirl.ngrok-free.dev`
- `transcription-worker`: FastAPI reel processor at `http://192.168.10.101:8001`
- `web`: Nuxt test app at `http://localhost:3000`

```bash
cp .env.example .env
# Fill OPENAI_API_KEY if you want real reel processing.
# For Google login, keep:
# APP_URL=https://aerosol-reformer-twirl.ngrok-free.dev
# FRONTEND_URL=http://localhost:3000
# For push-triggered processing, keep:
# FASTAPI_WORKER_URL=http://192.168.10.101:8001
# POLL_ENABLED=false
docker compose up --build
```

Optional seed data:

```bash
docker compose run --rm api npm run db:seed:local
```

Health checks:

```bash
curl https://aerosol-reformer-twirl.ngrok-free.dev/
curl http://192.168.10.101:8001/health
```

## Production

Production does not need Docker for everything.

The API is a Cloudflare Worker backed by D1, so deploy it with Wrangler:

```bash
cd apis
npm run db:migrate:remote
npm run deploy
```

The FastAPI worker is the part that should run as a production container because
it downloads reels, runs ffmpeg/Whisper, and calls OpenAI:

```bash
cp .env.example .env
# Set API_BASE_URL to the deployed Worker URL.
# Set SERVICE_TOKEN to match the Worker secret.
# Set OPENAI_API_KEY.
docker compose -f docker-compose.prod.yml up -d --build
```

So the short answer is: production needs the FastAPI container, but not only
FastAPI. It also needs the Cloudflare Worker API, D1 migrations, Worker secrets,
and the web/mobile clients pointed at the production API.
