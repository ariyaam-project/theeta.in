import { getQuery, readRawBody, setResponseHeader } from 'h3'

type ApiMethod = 'GET' | 'HEAD' | 'PATCH' | 'POST' | 'PUT' | 'DELETE' | 'CONNECT' | 'OPTIONS' | 'TRACE'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const apiBase = String(config.thetaApiBase).replace(/\/$/, '')
  const path = event.context.params?.path || ''
  const targetPath = Array.isArray(path) ? path.join('/') : path
  const query = getQuery(event)
  const search = new URLSearchParams()

  for (const [key, value] of Object.entries(query)) {
    if (Array.isArray(value)) {
      for (const item of value) search.append(key, String(item))
    } else if (value !== undefined) {
      search.set(key, String(value))
    }
  }

  const url = `${apiBase}/api/${targetPath}${search.size ? `?${search}` : ''}`
  const method = event.method.toUpperCase() as ApiMethod
  const headers: Record<string, string> = {
    'content-type': event.node.req.headers['content-type'] || 'application/json',
    origin: new URL(apiBase).origin
  }

  if (event.node.req.headers.cookie) headers.cookie = event.node.req.headers.cookie
  if (event.node.req.headers.authorization) headers.authorization = event.node.req.headers.authorization

  const body = method === 'GET' || method === 'HEAD' ? undefined : await readRawBody(event)
  const response = await $fetch.raw(url, {
    method,
    headers,
    body,
    ignoreResponseError: true,
    redirect: 'manual'
  })

  const setCookie = response.headers.get('set-cookie')
  if (setCookie) setResponseHeader(event, 'set-cookie', setCookie)
  setResponseHeader(event, 'content-type', response.headers.get('content-type') || 'application/json')
  event.node.res.statusCode = response.status
  return response._data
})
