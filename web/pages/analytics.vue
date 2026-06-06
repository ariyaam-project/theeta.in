<script setup lang="ts">
const { user, pending, savedReels, loadSavedReels, logout } = await useTheta()

if (!pending.value && !user.value) {
  await navigateTo('/login')
}

watch(user, (value) => {
  if (!value) navigateTo('/login')
  else loadSavedReels().catch(() => {})
}, { immediate: true })

const located = computed(() =>
  savedReels.value.filter((i) => {
    const r = i.reel.restaurant
    return r && r.lat != null && r.lng != null
  })
)

const processing = computed(() =>
  savedReels.value.filter(
    (i) => i.reel.status !== 'complete' && i.reel.status !== 'failed'
  ).length
)

const cities = computed(() => {
  const set = new Set<string>()
  for (const item of located.value) {
    const city = item.reel.restaurant?.city
    if (city) set.add(city)
  }
  return set
})

const avgConfidence = computed(() => {
  const vals = located.value
    .map((i) => i.reel.restaurant?.confidence)
    .filter((v): v is number => typeof v === 'number')
  if (!vals.length) return null
  return vals.reduce((a, b) => a + b, 0) / vals.length
})

const statusBreakdown = computed(() => {
  const counts: Record<string, number> = {}
  for (const item of savedReels.value) {
    const key = item.savedStatus === 'processed' ? 'complete' : item.reel.status
    counts[key] = (counts[key] || 0) + 1
  }
  return Object.entries(counts).sort((a, b) => b[1] - a[1])
})

const topCities = computed(() => {
  const counts: Record<string, number> = {}
  for (const item of located.value) {
    const city = item.reel.restaurant?.city
    if (city) counts[city] = (counts[city] || 0) + 1
  }
  return Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 5)
})

const total = computed(() => savedReels.value.length)

function pct(part: number) {
  return total.value === 0 ? 0 : Math.max(4, Math.round((part / total.value) * 100))
}

function pretty(status: string) {
  return status ? status.charAt(0).toUpperCase() + status.slice(1) : 'Unknown'
}
</script>

<template>
  <div v-if="user">
    <AppNav :user="user" @logout="logout" />
    <section class="workspace">
      <div class="top-row">
        <div>
          <p class="section-kicker">Analytics</p>
          <h2>Your saved spots at a glance</h2>
        </div>
      </div>

      <div class="metric-grid">
        <article><span class="stat-label">Saved</span><strong>{{ total }}</strong></article>
        <article><span class="stat-label">Resolved</span><strong>{{ located.length }}</strong></article>
        <article><span class="stat-label">Processing</span><strong>{{ processing }}</strong></article>
        <article><span class="stat-label">Cities</span><strong>{{ cities.size }}</strong></article>
        <article class="life-card">
          <span class="stat-label">Avg confidence</span>
          <strong>{{ avgConfidence === null ? '—' : `${Math.round(avgConfidence * 100)}%` }}</strong>
        </article>
      </div>

      <div class="panel-grid">
        <div class="panel">
          <p class="section-kicker">By status</p>
          <p v-if="!statusBreakdown.length" class="muted">No reels yet.</p>
          <div v-for="[label, count] in statusBreakdown" :key="label" class="bar-row">
            <div class="bar-head">
              <span>{{ pretty(label) }}</span>
              <b>{{ count }}</b>
            </div>
            <div class="bar-track"><div class="bar-fill" :style="{ width: pct(count) + '%' }" /></div>
          </div>
        </div>

        <div class="panel">
          <p class="section-kicker">Top cities</p>
          <p v-if="!topCities.length" class="muted">No located spots yet.</p>
          <div v-for="[city, count] in topCities" :key="city" class="row-line">
            <span>{{ city }}</span>
            <b>{{ count }}</b>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
