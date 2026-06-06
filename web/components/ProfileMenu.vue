<script setup lang="ts">
import type { AuthUser } from '~/composables/useTheta'

defineProps<{ user: AuthUser }>()
const emit = defineEmits<{ logout: [] }>()

const open = ref(false)

function initial(name: string) {
  return name.trim().charAt(0).toUpperCase() || '?'
}
</script>

<template>
  <div class="profile-menu">
    <button class="profile-pill" type="button" :aria-expanded="open" @click="open = !open">
      <span class="profile-pic">
        <img v-if="user.avatarUrl" :src="user.avatarUrl" :alt="user.displayName" referrerpolicy="no-referrer" />
        <template v-else>{{ initial(user.displayName) }}</template>
      </span>
      <span class="profile-name">{{ user.displayName }}</span>
    </button>

    <Transition name="pop">
      <div v-if="open" class="profile-dropdown">
        <NuxtLink class="profile-link" to="/dashboard" @click="open = false">Dashboard</NuxtLink>
        <NuxtLink class="profile-link" to="/profile" @click="open = false">Profile</NuxtLink>
        <button class="profile-link" type="button" @click="open = false; emit('logout')">Sign out</button>
      </div>
    </Transition>

    <button v-if="open" class="profile-backdrop" type="button" aria-label="Close menu" @click="open = false" />
  </div>
</template>
