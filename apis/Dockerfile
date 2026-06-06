# Theta API — Hono on Cloudflare Workers, run locally via `wrangler dev` (workerd).
# Node 22+ required by wrangler v4.
FROM node:22-slim

WORKDIR /app

# wrangler/workerd needs CA certs for outbound TLS (Google OAuth, etc).
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

ENV CI=true
ENV WRANGLER_SEND_METRICS=false

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 8787

# Apply local D1 migrations, then serve. --ip 0.0.0.0 so the port is reachable
# from the host. Local D1 + seed state persist in the .wrangler volume.
# wrangler reads worker env from .dev.vars/[vars], NOT the container environment,
# so inject SERVICE_TOKEN (and optional OAuth creds) via --var when present.
CMD ["sh", "-c", "npm run db:migrate:local && exec npx wrangler dev --ip 0.0.0.0 --port 8787 ${SERVICE_TOKEN:+--var SERVICE_TOKEN:$SERVICE_TOKEN} ${APP_URL:+--var APP_URL:$APP_URL} ${FRONTEND_URL:+--var FRONTEND_URL:$FRONTEND_URL} ${FASTAPI_WORKER_URL:+--var FASTAPI_WORKER_URL:$FASTAPI_WORKER_URL} ${GOOGLE_CLIENT_ID:+--var GOOGLE_CLIENT_ID:$GOOGLE_CLIENT_ID} ${GOOGLE_CLIENT_SECRET:+--var GOOGLE_CLIENT_SECRET:$GOOGLE_CLIENT_SECRET}"]
