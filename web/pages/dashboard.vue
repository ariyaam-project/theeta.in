<script setup lang="ts">
import type { SavedReel } from '~/composables/useTheta'

const {
  user,
  pending,
  error,
  reelUrl,
  mineOnly,
  savedReels,
  actionError,
  loading,
  logout,
  saveReel,
  setMineOnly,
  loadSavedReels
} = await useTheta()

if (!pending.value && !user.value) {
  await navigateTo('/login')
}

watch(user, () => {
  if (!user.value) navigateTo('/login')
}, { immediate: true })

watch(user, () => {
  if (user.value) loadSavedReels().catch(() => {})
}, { immediate: true })

const firstName = computed(() => (user.value?.displayName || 'there').split(' ')[0])

const isLocated = (item: SavedReel) =>
  !!item.reel.restaurant && item.reel.restaurant.lat != null && item.reel.restaurant.lng != null
const isDone = (item: SavedReel) =>
  item.reel.status === 'complete' || item.reel.status === 'failed' || item.reel.isFood === false
const isProcessing = (item: SavedReel) => !isDone(item)

const saved = computed(() => savedReels.value.length)
const onMap = computed(() => savedReels.value.filter(isLocated).length)
const resolving = computed(() => savedReels.value.filter(isProcessing).length)

function badge(item: SavedReel) {
  if (item.reel.isFood === false) return { label: 'Not food', state: 'skip' }
  if (isLocated(item)) return { label: 'Resolved', state: 'done' }
  if (item.reel.status === 'complete') return { label: 'Needs review', state: 'review' }
  return { label: 'Resolving…', state: 'pending' }
}

function subtitle(item: SavedReel) {
  const r = item.reel.restaurant
  if (r) return [r.area, r.city].filter(Boolean).join(' · ') || item.reel.shortcode
  if (item.reel.isFood === false) return 'This reel is not about a food spot'
  return 'AI is finding the restaurant…'
}

async function add() {
  const url = reelUrl.value.trim()
  if (!url) return
  await saveReel()
  if (!actionError.value) reelUrl.value = ''
}

// Quietly keep processing reels fresh.
let timer: ReturnType<typeof setInterval> | null = null
onMounted(() => {
  timer = setInterval(() => {
    if (user.value && savedReels.value.some(isProcessing)) {
      loadSavedReels().catch(() => {})
    }
  }, 6000)
})
onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})
</script>

<template>
  <div v-if="user">
    <AppNav :user="user" @logout="logout" />

    <section class="workspace">
      <div class="profile-head">
        <img
          v-if="user.avatarUrl"
          :src="user.avatarUrl"
          :alt="user.displayName"
          referrerpolicy="no-referrer"
        />
        <div>
          <p class="section-kicker">Welcome back</p>
          <h2>Hey, {{ firstName }}</h2>
          <p class="muted">{{ user.email }}</p>
        </div>
      </div>

      <div v-if="error" class="error-banner">
        Could not reach the server. Try again in a moment.
      </div>
      <div v-if="actionError" class="error-banner">{{ actionError }}</div>

      <div class="metric-grid">
        <article><span class="stat-label">Saved</span><strong>{{ saved }}</strong></article>
        <article><span class="stat-label">On your map</span><strong>{{ onMap }}</strong></article>
        <article><span class="stat-label">Resolving</span><strong>{{ resolving }}</strong></article>
      </div>

      <form class="add-reel" @submit.prevent="add">
        <p class="section-kicker">Add a spot</p>
        <h3>Paste an Instagram food reel</h3>
        <div class="add-reel-row">
          <input
            v-model="reelUrl"
            type="url"
            placeholder="https://www.instagram.com/reel/..."
            autocomplete="off"
          />
          <button class="primary-button" type="submit" :disabled="loading || !reelUrl.trim()">
            {{ loading ? 'Saving…' : 'Save & resolve' }}
          </button>
        </div>
        <p class="add-reel-hint muted">
          We'll find the restaurant and drop it on your map automatically.
        </p>
      </form>

      <div class="history">
        <div class="history-head">
          <h3>Saved spots</h3>
          <div class="filter-chips">
            <button class="chip" type="button" :data-active="!mineOnly" @click="setMineOnly(false)">
              Everyone
            </button>
            <button class="chip" type="button" :data-active="mineOnly" @click="setMineOnly(true)">
              Saved by me
            </button>
          </div>
        </div>

        <TransitionGroup v-if="savedReels.length" name="list" tag="ul">
          <li v-for="item in savedReels" :key="item.reelId">
            <a class="profile-link" :href="item.reel.url" target="_blank" rel="noopener">
              <strong>{{ item.reel.restaurant?.name || 'Resolving…' }}</strong>
              <small>{{ subtitle(item) }}</small>
            </a>
            <span class="reel-badge" :data-state="badge(item).state">{{ badge(item).label }}</span>
          </li>
        </TransitionGroup>

        <div v-else class="empty-state">
          <strong>No spots yet</strong>
          <span>Paste a reel above, or share one to Theeta from Instagram.</span>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.add-reel {
  margin-top: 24px;
  padding: 24px;
  border-radius: 20px;
  background: var(--p-soft);
}

.add-reel h3 {
  margin: 6px 0 14px;
  font-size: 1.35rem;
}

.add-reel-row {
  display: flex;
  gap: 12px;
}

.add-reel-row input {
  flex: 1;
  background: #fff;
}

.add-reel-row .primary-button {
  white-space: nowrap;
}

.add-reel-hint {
  margin: 12px 0 0;
  font-size: 0.92rem;
}

.reel-badge {
  flex: 0 0 auto;
  padding: 6px 14px;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 800;
  white-space: nowrap;
}

.reel-badge[data-state='done'] {
  background: #e4f6ea;
  color: #1f7a45;
}

.reel-badge[data-state='pending'] {
  background: #fdeae2;
  color: #b4502f;
}

.reel-badge[data-state='review'] {
  background: var(--p-soft);
  color: var(--p);
}

.reel-badge[data-state='skip'] {
  background: #eee;
  color: #777;
}

@media (max-width: 640px) {
  .add-reel-row {
    flex-direction: column;
  }

  .add-reel-row .primary-button {
    width: 100%;
  }
}
</style>
