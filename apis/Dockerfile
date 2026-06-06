# Theta API — Hono on Cloudflare Workers, run locally via `wrangler dev` (workerd).
FROM node:20-slim

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
CMD ["sh", "-c", "npm run db:migrate:local && npx wrangler dev --ip 0.0.0.0 --port 8787"]
