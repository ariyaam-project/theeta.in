export type AuthUser = {
  id: string
  email: string
  displayName: string
  avatarUrl: string | null
}

export type ReelSummary = {
  id: string
  shortcode: string
  url: string
  status: string
  caption: string | null
  thumbnailUrl: string | null
  createdAt: string
  restaurant?: ReelRestaurant | null
}

export type ReelRestaurant = {
  id: string
  slug: string
  name: string
  address: string | null
  area: string | null
  city: string | null
  lat: number | null
  lng: number | null
  confidence?: number | null
}

export type LocationExtraction = {
  restaurantName: string | null
  branchName: string | null
  area: string | null
  city: string | null
  state: string | null
  country: string | null
  suggestedAddress: string | null
  suggestedLat: number | null
  suggestedLng: number | null
  suggestedLocationConfidence: number | null
  landmarks: string[]
  evidence: Array<{ source: string; text: string }>
  confidence: number | null
  resolutionStatus: string | null
}

export type ReelDetail = {
  reel: ReelSummary & {
    postedAt?: string | null
    likeCount?: number | null
    commentCount?: number | null
    creator?: unknown
    transcript?: string | null
    locationExtraction?: LocationExtraction | null
  }
}

export type SavedReel = {
  reelId: string
  savedStatus: string
  savedAt: string
  reel: ReelSummary
}

export type ReelStatus = {
  id: string
  status: string
  savedStatus?: string
  step?: number
  totalSteps?: number
  restaurantSlug?: string | null
  error?: string | null
}

export async function useTheta() {
  const config = useRuntimeConfig()
  const reelUrl = ref('')
  const devEmail = ref('dev@theta.local')
  const currentReelId = ref('')
  const status = ref<ReelStatus | null>(null)
  const detail = ref<ReelDetail | null>(null)
  const savedReels = ref<SavedReel[]>([])
  const actionError = ref('')
  const loading = ref(false)
  const polling = ref(false)
  let pollTimer: ReturnType<typeof setInterval> | null = null

  const { data, pending, error, refresh } = await useFetch<{ user: AuthUser | null }>('/api/me', {
    key: 'theta-me',
    default: () => ({ user: null })
  })

  const user = computed(() => data.value.user)
  const workerBase = computed(() => String(config.public.thetaApiBase).replace(/\/$/, ''))

  async function api<T>(path: string, options: Parameters<typeof $fetch>[1] = {}) {
    return await $fetch<T>(`/api${path}`, {
      credentials: 'include',
      ...options,
      headers: {
        'content-type': 'application/json',
        ...(options?.headers || {})
      }
    })
  }

  function loginWithGoogle() {
    // Same-origin redirect; the Nuxt server route forwards to the API worker
    // using the runtime API base (see server/routes/auth/google.get.ts).
    window.location.href = '/auth/google'
  }

  async function devLogin() {
    actionError.value = ''
    loading.value = true
    try {
      await api<{ user: AuthUser }>('/dev/login', {
        method: 'POST',
        body: { email: devEmail.value }
      })
      await refresh()
    } catch {
      actionError.value = 'Local dev login failed. Make sure the Worker is running on the configured API URL.'
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    actionError.value = ''
    await api('/auth/logout', { method: 'POST', body: {} })
    stopPolling()
    currentReelId.value = ''
    status.value = null
    detail.value = null
    savedReels.value = []
    await refresh()
  }

  async function saveReel() {
    actionError.value = ''
    loading.value = true
    try {
      const response = await api<{ reel: ReelSummary; savedReel?: { reelId: string; status: string } }>('/reels', {
        method: 'POST',
        body: { url: reelUrl.value }
      })

      currentReelId.value = response.reel.id
      status.value = {
        id: response.reel.id,
        status: response.reel.status,
        savedStatus: response.savedReel?.status
      }
      await loadSavedReels()
      startPolling()
    } catch {
      actionError.value = 'Could not save this reel. Check the URL and auth session.'
    } finally {
      loading.value = false
    }
  }

  async function fetchStatus() {
    if (!currentReelId.value) return
    status.value = await api<ReelStatus>(`/reels/${currentReelId.value}/status`)
    if (status.value.status === 'complete' || status.value.status === 'failed') {
      stopPolling()
      await fetchDetail()
      await loadSavedReels()
    }
  }

  async function fetchDetail() {
    if (!currentReelId.value) return
    detail.value = await api<ReelDetail>(`/reels/${currentReelId.value}`)
  }

  async function loadSavedReels() {
    if (!user.value) return
    const response = await api<{ items: SavedReel[] }>('/reels/saved/list')
    savedReels.value = response.items
  }

  function selectSaved(item: SavedReel) {
    currentReelId.value = item.reelId
    status.value = {
      id: item.reelId,
      status: item.reel.status,
      savedStatus: item.savedStatus
    }
    fetchDetail().catch(() => {
      actionError.value = 'Could not load reel detail.'
    })
  }

  function startPolling() {
    if (!currentReelId.value) return
    stopPolling()
    polling.value = true
    pollTimer = setInterval(() => {
      fetchStatus().catch(() => {
        actionError.value = 'Polling failed. Check the Worker logs.'
        stopPolling()
      })
    }, 3000)
  }

  function stopPolling() {
    polling.value = false
    if (pollTimer) clearInterval(pollTimer)
    pollTimer = null
  }

  onBeforeUnmount(stopPolling)

  return {
    user,
    pending,
    error,
    reelUrl,
    devEmail,
    currentReelId,
    status,
    detail,
    savedReels,
    actionError,
    loading,
    polling,
    workerBase,
    loginWithGoogle,
    devLogin,
    logout,
    saveReel,
    fetchStatus,
    fetchDetail,
    loadSavedReels,
    selectSaved,
    startPolling,
    stopPolling
  }
}
