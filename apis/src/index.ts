import { Hono } from 'hono'
import { HTTPException } from 'hono/http-exception'
import type { AppEnv } from './types'
import { authRoutes } from './routes/auth'
import { meRoutes } from './routes/me'
import { reelRoutes } from './routes/reels'
import { restaurantRoutes } from './routes/restaurants'
import { surpriseRoutes } from './routes/surprise'
import { listRoutes } from './routes/lists'
import { saveRoutes } from './routes/saves'
import { internalRoutes } from './routes/internal'
import { devPageRoutes, devRoutes } from './routes/dev'

const app = new Hono<AppEnv>()

app.get('/', (c) => c.json({ service: 'theta-api', ok: true }))

app.route('/', devPageRoutes)
app.route('/api/auth', authRoutes)
app.route('/api/dev', devRoutes)
app.route('/api', meRoutes)
app.route('/api/reels', reelRoutes)
app.route('/api/restaurants', restaurantRoutes)
app.route('/api', surpriseRoutes)
app.route('/api/lists', listRoutes)
app.route('/api/saves', saveRoutes)
app.route('/api/internal', internalRoutes)

// Error shape matches the API contract: { statusCode, statusMessage, message }.
app.onError((err, c) => {
  const status = err instanceof HTTPException ? err.status : 500
  const message = err instanceof HTTPException ? err.message : 'Internal Server Error'
  return c.json({ error: true, statusCode: status, statusMessage: message, message }, status as any)
})

app.notFound((c) => c.json({ error: true, statusCode: 404, statusMessage: 'Not found', message: 'Not found' }, 404))

export default app
