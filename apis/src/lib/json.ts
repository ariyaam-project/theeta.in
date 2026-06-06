/** Parse a JSON-array text column into string[], tolerating null/garbage. */
export function parseStringArray(value: unknown): string[] {
  if (typeof value !== 'string' || !value) return []
  try {
    const parsed = JSON.parse(value)
    return Array.isArray(parsed) ? parsed.map(String) : []
  } catch {
    return []
  }
}

/** Parse a JSON-object text column, returning {} on failure. */
export function parseObject<T = Record<string, unknown>>(value: unknown): T {
  if (typeof value !== 'string' || !value) return {} as T
  try {
    const parsed = JSON.parse(value)
    return parsed && typeof parsed === 'object' ? (parsed as T) : ({} as T)
  } catch {
    return {} as T
  }
}
