import { HTTPException } from 'hono/http-exception'

/**
 * Throw an API error. Serialized by app.onError into the contract shape:
 * { statusCode, statusMessage, message }.
 */
export function apiError(status: number, message: string): never {
  throw new HTTPException(status as any, { message })
}
