export function createToken(bytes = 32) {
  const values = crypto.getRandomValues(new Uint8Array(bytes))
  return Array.from(values, (value) => value.toString(16).padStart(2, '0')).join('')
}

export async function sha256(value: string) {
  const encoded = new TextEncoder().encode(value)
  const hash = await crypto.subtle.digest('SHA-256', encoded)
  return Array.from(new Uint8Array(hash), (byte) => byte.toString(16).padStart(2, '0')).join('')
}

export function newId() {
  return crypto.randomUUID()
}
