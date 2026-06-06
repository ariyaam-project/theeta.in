<script setup lang="ts">
const { user, pending, savedReels, loadSavedReels, logout } = await useTheta()

if (!pending.value && !user.value) {
  await navigateTo('/login')
}

watch(user, (value) => {
  if (!value) navigateTo('/login')
  else loadSavedReels().catch(() => {})
}, { immediate: true })

const located = computed(
  () =>
    savedReels.value.filter((i) => {
      const r = i.reel.restaurant
      return r && r.lat != null && r.lng != null
    }).length
)

function initial(name: string) {
  return name.trim().charAt(0).toUpperCase() || '?'
}
</script>

<template>
  <div v-if="user">
    <AppNav :user="user" @logout="logout" />
    <section class="workspace">
      <div class="top-row">
        <div>
          <p class="section-kicker">Profile</p>
          <h2>Account</h2>
        </div>
      </div>

      <div class="profile-card">
        <span class="profile-avatar">
          <img v-if="user.avatarUrl" :src="user.avatarUrl" :alt="user.displayName" referrerpolicy="no-referrer" />
          <template v-else>{{ initial(user.displayName) }}</template>
        </span>
        <div>
          <h3>{{ user.displayName }}</h3>
          <p class="muted">{{ user.email }}</p>
        </div>
      </div>

      <div class="metric-grid">
        <article><span class="stat-label">Saved</span><strong>{{ savedReels.length }}</strong></article>
        <article><span class="stat-label">Resolved</span><strong>{{ located }}</strong></article>
      </div>

      <button class="ghost-button danger-button" type="button" @click="logout">
        Log out
      </button>
    </section>
  </div>
</template>
