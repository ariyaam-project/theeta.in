<script setup lang="ts">
import type { AuthUser } from '~/composables/useTheta'

defineProps<{ user: AuthUser }>()
const emit = defineEmits<{ logout: [] }>()

const links = [
  { to: '/dashboard', label: 'Food' },
  { to: '/map', label: 'Map' },
  { to: '/analytics', label: 'Analytics' },
  { to: '/profile', label: 'Profile' }
]
</script>

<template>
  <header class="dash-nav app-nav">
    <a class="brand-mark" href="/dashboard" aria-label="Theeta home">
      <img src="/images/logo.png" alt="Theeta" />
      <span class="brand-name">theeta.in</span>
    </a>

    <nav class="nav-tabs" aria-label="Sections">
      <NuxtLink v-for="link in links" :key="link.to" :to="link.to" class="nav-tab">
        {{ link.label }}
      </NuxtLink>
    </nav>

    <ProfileMenu :user="user" @logout="emit('logout')" />
  </header>
</template>
