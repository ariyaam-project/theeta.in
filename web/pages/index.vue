<script setup lang="ts">
const {
  user,
  pending,
  error,
  devEmail,
  reelUrl,
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
} = await useTheta()

watch(user, () => {
  if (user.value) {
    loadSavedReels().catch(() => {})
  }
}, { immediate: true })

const statusLabel = computed(() => status.value?.status || 'No reel selected')
const savedLabel = computed(() => status.value?.savedStatus || 'n/a')
const detailJson = computed(() => (detail.value ? JSON.stringify(detail.value, null, 2) : 'Select a reel to inspect the stored metadata.'))
const resolvedRestaurant = computed(() => detail.value?.reel.restaurant || null)
const locationExtraction = computed(() => detail.value?.reel.locationExtraction || null)
const selectedLocation = computed(() => {
  const restaurant = resolvedRestaurant.value
  const extraction = locationExtraction.value
  return {
    name: restaurant?.name || extraction?.restaurantName || null,
    address: restaurant?.address || extraction?.suggestedAddress || null,
    area: restaurant?.area || extraction?.area || null,
    city: restaurant?.city || extraction?.city || null,
    lat: restaurant?.lat ?? extraction?.suggestedLat ?? null,
    lng: restaurant?.lng ?? extraction?.suggestedLng ?? null,
    confidence: restaurant?.confidence ?? extraction?.suggestedLocationConfidence ?? extraction?.confidence ?? null,
    status: extraction?.resolutionStatus || (restaurant ? 'ai_suggested' : null)
  }
})
const hasSelectedLocation = computed(() => Boolean(selectedLocation.value.name || selectedLocation.value.address))

function formatConfidence(value: number | null | undefined) {
  if (typeof value !== 'number') return 'n/a'
  return `${Math.round(value * 100)}%`
}
</script>

<template>
  <Transition name="swap" mode="out-in">
    <section v-if="pending" key="loading" class="workspace loading-state">
      <div class="spinner" aria-hidden="true" />
      <p class="muted">Checking your Theeta session...</p>
    </section>

    <div v-else key="home">
      <header class="dash-nav">
        <a class="brand-mark" href="/" aria-label="Theeta home">
          <img src="/images/logo.png" alt="Theeta" />
          <span class="brand-name">theeta.in</span>
        </a>
        <ProfileMenu v-if="user" :user="user" @logout="logout" />
        <button v-else class="nav-cta" type="button" @click="loginWithGoogle">SIGN IN</button>
      </header>

      <section class="workspace dashboard">
        <div class="top-row">
          <div class="profile-head">
            <img src="/images/logo.png" alt="" aria-hidden="true" />
            <div>
              <p class="section-kicker">Reel resolver</p>
              <h2>Paste a reel. Track processing. Reuse saved locations.</h2>
              <p class="muted">
                Worker API: {{ workerBase }}
              </p>
            </div>
          </div>

          <div class="activity">
            <span class="activity-title">Pipeline</span>
            <div class="activity-grid">
              <div v-for="column in 12" :key="column" class="activity-col">
                <span
                  v-for="row in 7"
                  :key="`${column}-${row}`"
                  class="activity-cell"
                  :data-level="status ? Math.min(column % 5, 4) : 0"
                  :data-today="column === 8 && row === 4"
                />
              </div>
            </div>
          </div>
        </div>

        <div v-if="error" class="error-banner">
          Could not sync auth state. Make sure the Worker is running.
        </div>
        <div v-if="actionError" class="error-banner">
          {{ actionError }}
        </div>

        <div v-if="!user" class="log-cta login-strip">
          <div>
            <p class="section-kicker">Login required</p>
            <h3>Sign in to save reels</h3>
            <p class="muted">Use dev login locally or Google OAuth from the Worker.</p>
          </div>
          <form class="inline-login" @submit.prevent="devLogin">
            <input v-model="devEmail" type="email" placeholder="dev@theta.local" autocomplete="email" />
            <button class="primary-button compact-button" type="submit" :disabled="loading">
              Dev login
            </button>
            <button class="google-button compact-button" type="button" @click="loginWithGoogle">
              <span class="google-mark">G</span>
              Google
            </button>
          </form>
        </div>

        <div class="stats-grid">
          <article class="life-card">
            <span class="stat-label">Current reel</span>
            <strong>{{ statusLabel }}</strong>
            <em>{{ currentReelId || 'Paste a reel URL below' }}</em>
          </article>

          <article>
            <span class="stat-label">Saved status</span>
            <strong>{{ savedLabel }}</strong>
          </article>

          <article>
            <span class="stat-label">Step</span>
            <strong>{{ status?.step || '-' }}/{{ status?.totalSteps || '-' }}</strong>
          </article>

          <article>
            <span class="stat-label">Saved reels</span>
            <strong>{{ savedReels.length }}</strong>
          </article>
        </div>

        <div class="location-card" :data-empty="!hasSelectedLocation">
          <div>
            <p class="section-kicker">AI resolved location</p>
            <h3>{{ selectedLocation.name || 'No exact location yet' }}</h3>
            <p class="muted">
              {{ selectedLocation.address || 'The worker will show the address here after AI extraction returns a specific place.' }}
            </p>
          </div>
          <dl v-if="hasSelectedLocation" class="location-grid">
            <div>
              <dt>Area</dt>
              <dd>{{ selectedLocation.area || '-' }}</dd>
            </div>
            <div>
              <dt>City</dt>
              <dd>{{ selectedLocation.city || '-' }}</dd>
            </div>
            <div>
              <dt>Coordinates</dt>
              <dd>
                <template v-if="selectedLocation.lat !== null && selectedLocation.lng !== null">
                  {{ selectedLocation.lat }}, {{ selectedLocation.lng }}
                </template>
                <template v-else>-</template>
              </dd>
            </div>
            <div>
              <dt>Confidence</dt>
              <dd>{{ formatConfidence(selectedLocation.confidence) }}</dd>
            </div>
            <div>
              <dt>Status</dt>
              <dd>{{ selectedLocation.status || '-' }}</dd>
            </div>
          </dl>
        </div>

        <div class="log-cta">
          <div>
            <p class="section-kicker">Reel input</p>
            <h3>Paste an Instagram reel link</h3>
          </div>
        </div>

        <form class="form-grid" @submit.prevent="saveReel">
          <label>
            <span>Reel URL</span>
            <input
              v-model="reelUrl"
              type="url"
              placeholder="https://www.instagram.com/reel/..."
              autocomplete="off"
            />
          </label>

          <button class="primary-button" type="submit" :disabled="loading || !user || !reelUrl.trim()">
            {{ user ? 'Save and process' : 'Login to save reel' }}
          </button>
        </form>

        <div class="log-cta">
          <div>
            <p class="section-kicker">Processing</p>
            <h3>Status controls</h3>
          </div>
          <div class="modal-actions">
            <button class="ghost-button compact-button" type="button" :disabled="!currentReelId" @click="fetchStatus">
              Check status
            </button>
            <button class="ghost-button compact-button" type="button" :disabled="!currentReelId" @click="polling ? stopPolling() : startPolling()">
              {{ polling ? 'Stop polling' : 'Start polling' }}
            </button>
            <button class="ghost-button compact-button" type="button" :disabled="!currentReelId" @click="fetchDetail">
              Load detail
            </button>
          </div>
        </div>

        <div class="history">
          <div class="history-head">
            <h3>Already saved reels</h3>
            <button class="ghost-button compact-button" type="button" :disabled="!user" @click="loadSavedReels">
              Reload
            </button>
          </div>

          <TransitionGroup v-if="savedReels.length" name="list" tag="ul">
            <li v-for="item in savedReels" :key="item.reelId">
              <button class="profile-link" type="button" @click="selectSaved(item)">
                <strong>{{ item.reel.shortcode }}</strong>
                <span>{{ item.savedStatus }} / {{ item.reel.status }}</span>
                <small v-if="item.reel.restaurant">
                  {{ item.reel.restaurant.name }}
                  <template v-if="item.reel.restaurant.city"> · {{ item.reel.restaurant.city }}</template>
                </small>
                <small v-else-if="item.reel.status === 'complete'">Location needs review</small>
              </button>
              <b>{{ new Date(item.savedAt).toLocaleDateString() }}</b>
            </li>
          </TransitionGroup>

          <div v-else class="empty-state">
            <strong>No saved reels loaded</strong>
            <span>{{ user ? 'Paste a reel URL above or reload saved reels.' : 'Login to see your saved reels.' }}</span>
          </div>
        </div>

        <div class="history">
          <div class="history-head">
            <h3>Reel detail</h3>
            <span>raw API response</span>
          </div>
          <pre class="detail-json">{{ detailJson }}</pre>
        </div>
      </section>
    </div>
  </Transition>
</template>
