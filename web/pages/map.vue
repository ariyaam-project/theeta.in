<script setup lang="ts">
import type { MapSpot } from '~/components/LeafletMap.client.vue'

const { user, pending, savedReels, loadSavedReels, logout } = await useTheta()

if (!pending.value && !user.value) {
  await navigateTo('/login')
}

watch(user, (value) => {
  if (!value) navigateTo('/login')
  else loadSavedReels().catch(() => {})
}, { immediate: true })

const spots = computed<MapSpot[]>(() =>
  savedReels.value
    .filter((item) => {
      const r = item.reel.restaurant
      return r && r.lat != null && r.lng != null
    })
    .map((item) => {
      const r = item.reel.restaurant!
      return {
        name: r.name || 'Food spot',
        city: r.city,
        lat: r.lat as number,
        lng: r.lng as number,
        url: item.reel.url
      }
    })
)
</script>

<template>
  <div v-if="user">
    <AppNav :user="user" @logout="logout" />
    <section class="workspace">
      <div class="top-row">
        <div>
          <p class="section-kicker">Map</p>
          <h2>Your resolved food spots</h2>
          <p class="muted">
            {{ spots.length ? `${spots.length} spot${spots.length === 1 ? '' : 's'} on the map.` : 'No located spots yet.' }}
          </p>
        </div>
      </div>

      <div class="map-shell">
        <ClientOnly>
          <LeafletMap :spots="spots" />
          <template #fallback>
            <div class="map-fallback muted">Loading map…</div>
          </template>
        </ClientOnly>
      </div>

      <div v-if="!spots.length" class="empty-state">
        <strong>Nothing to map yet</strong>
        <span>Spots appear once AI resolves a saved reel to a restaurant with a location.</span>
      </div>
    </section>
  </div>
</template>
