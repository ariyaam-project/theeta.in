<script setup lang="ts">
const {
  user,
  pending,
  error,
  reelUrl,
  mineOnly,
  currentReelId,
  status,
  detail,
  savedReels,
  actionError,
  loading,
  polling,
  logout,
  saveReel,
  setMineOnly,
  fetchStatus,
  fetchDetail,
  loadSavedReels,
  selectSaved,
  startPolling,
  stopPolling
} = await useTheta()

if (!pending.value && !user.value) {
  await navigateTo('/login')
}

watch(user, () => {
  if (!user.value) navigateTo('/login')
})

watch(user, () => {
  if (user.value) {
    loadSavedReels().catch(() => {})
  }
}, { immediate: true })

const statusLabel = computed(() => status.value?.status || 'No reel selected')
const savedLabel = computed(() => status.value?.savedStatus || 'n/a')
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
const notFood = computed(() => detail.value?.reel.isFood === false)
const rejectionReason = computed(() => detail.value?.reel.rejectionReason || 'This reel is not about a food spot, so processing was skipped.')
const commentAnalysis = computed(() => detail.value?.reel.commentAnalysis || null)

function formatSentiment(value: number | null | undefined) {
  if (typeof value !== 'number') return 'n/a'
  const label = value > 0.3 ? 'Positive' : value < -0.3 ? 'Negative' : 'Mixed'
  return `${label} (${value.toFixed(2)})`
}

function formatConfidence(value: number | null | undefined) {
  if (typeof value !== 'number') return 'n/a'
  return `${Math.round(value * 100)}%`
}
</script>

<template>
  <div v-if="user">
    <AppNav :user="user" @logout="logout" />

    <section class="workspace dashboard">
      <div class="top-row">
        <div class="profile-head">
          <img v-if="user.avatarUrl" :src="user.avatarUrl" :alt="`${user.displayName} avatar`" referrerpolicy="no-referrer" />
          <div>
            <p class="section-kicker">Signed in</p>
            <h2>{{ user.displayName }}</h2>
            <p class="muted">{{ user.email }}</p>
          </div>
        </div>
      </div>

      <div v-if="error" class="error-banner">
        Could not sync auth state. Make sure the Worker is running.
      </div>
      <div v-if="actionError" class="error-banner">
        {{ actionError }}
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

      <div class="location-card" :data-empty="notFood || !hasSelectedLocation">
        <div v-if="notFood">
          <p class="section-kicker">Not a food reel</p>
          <h3>Skipped</h3>
          <p class="muted">{{ rejectionReason }}</p>
        </div>
        <div v-else>
          <p class="section-kicker">AI resolved location</p>
          <h3>{{ selectedLocation.name || 'No exact location yet' }}</h3>
          <p class="muted">
            {{ selectedLocation.address || 'The worker will show the address here after AI extraction returns a specific place.' }}
          </p>
        </div>
        <dl v-if="!notFood && hasSelectedLocation" class="location-grid">
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

      <div v-if="commentAnalysis" class="location-card" data-empty="true">
        <div>
          <p class="section-kicker">Comment analysis</p>
          <h3>{{ commentAnalysis.verdict || 'Audience reaction' }}</h3>
          <p class="muted">
            {{ commentAnalysis.analyzedCount }} comments ·
            👍 {{ commentAnalysis.positiveCount }} ·
            👎 {{ commentAnalysis.negativeCount }} ·
            😐 {{ commentAnalysis.neutralCount }}
            <template v-if="commentAnalysis.sponsoredSignal"> · ⚠ sponsored signal</template>
          </p>
          <dl class="location-grid">
            <div>
              <dt>Common praise</dt>
              <dd>{{ commentAnalysis.commonPraise.length ? commentAnalysis.commonPraise.join(', ') : '-' }}</dd>
            </div>
            <div>
              <dt>Common complaints</dt>
              <dd>{{ commentAnalysis.commonComplaints.length ? commentAnalysis.commonComplaints.join(', ') : '-' }}</dd>
            </div>
            <div>
              <dt>Sentiment</dt>
              <dd>{{ formatSentiment(commentAnalysis.sentimentScore) }}</dd>
            </div>
            <div>
              <dt>Authenticity</dt>
              <dd>{{ commentAnalysis.authenticityNote || '-' }}</dd>
            </div>
          </dl>
        </div>
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

        <button class="primary-button" type="submit" :disabled="loading || !reelUrl.trim()">
          Save and process
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
          <h3>Saved reels</h3>
          <div class="filter-chips">
            <button
              class="chip"
              type="button"
              :data-active="!mineOnly"
              @click="setMineOnly(false)"
            >
              Everyone
            </button>
            <button
              class="chip"
              type="button"
              :data-active="mineOnly"
              @click="setMineOnly(true)"
            >
              Saved by me
            </button>
            <button class="ghost-button compact-button" type="button" @click="loadSavedReels">Reload</button>
          </div>
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
              <small v-else-if="item.reel.isFood === false">Not a food reel</small>
              <small v-else-if="item.reel.status === 'complete'">Location needs review</small>
            </button>
            <b>{{ new Date(item.savedAt).toLocaleDateString() }}</b>
          </li>
        </TransitionGroup>

        <div v-else class="empty-state">
          <strong>No saved reels yet</strong>
          <span>Paste a reel URL above to create the first saved reel ref.</span>
        </div>
      </div>
    </section>
  </div>
</template>
