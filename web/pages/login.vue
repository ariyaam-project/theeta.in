<script setup lang="ts">
const {
  user,
  actionError,
  loading,
  loginEmail,
  registerEmail,
  loginWithGoogle,
  devLogin,
  devEmail
} = await useTheta()

watch(user, (value) => {
  if (value) navigateTo('/dashboard')
}, { immediate: true })

const mode = ref<'login' | 'register'>('login')
const name = ref('')
const email = ref('')
const password = ref('')
const localError = ref('')

const isRegister = computed(() => mode.value === 'register')

function toggle() {
  mode.value = isRegister.value ? 'login' : 'register'
  localError.value = ''
}

async function submit() {
  localError.value = ''
  const mail = email.value.trim()
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(mail)) {
    localError.value = 'Enter a valid email address.'
    return
  }
  if (isRegister.value && !name.value.trim()) {
    localError.value = 'Name is required.'
    return
  }
  if (isRegister.value && password.value.length < 8) {
    localError.value = 'Password must be at least 8 characters.'
    return
  }
  if (!password.value) {
    localError.value = 'Password is required.'
    return
  }

  const ok = isRegister.value
    ? await registerEmail(name.value.trim(), mail, password.value)
    : await loginEmail(mail, password.value)
  if (ok) await navigateTo('/dashboard')
}
</script>

<template>
  <div>
    <header class="dash-nav">
      <a class="brand-mark" href="/" aria-label="Theeta home">
        <img src="/images/logo.png" alt="Theeta" />
        <span class="brand-name">theeta.in</span>
      </a>
    </header>

    <section class="workspace auth-wrap">
      <div class="auth-card">
        <p class="section-kicker">{{ isRegister ? 'Create account' : 'Welcome back' }}</p>
        <h2>{{ isRegister ? 'Sign up to save reels' : 'Log in to save reels' }}</h2>

        <div v-if="localError || actionError" class="error-banner">
          {{ localError || actionError }}
        </div>

        <form class="form-grid" @submit.prevent="submit">
          <label v-if="isRegister">
            <span>Name</span>
            <input v-model="name" type="text" autocomplete="name" placeholder="Your name" />
          </label>
          <label>
            <span>Email</span>
            <input v-model="email" type="email" autocomplete="email" placeholder="you@example.com" />
          </label>
          <label>
            <span>Password</span>
            <input
              v-model="password"
              type="password"
              :autocomplete="isRegister ? 'new-password' : 'current-password'"
              placeholder="••••••••"
            />
          </label>
          <button class="primary-button" type="submit" :disabled="loading">
            {{ isRegister ? 'Create account' : 'Log in' }}
          </button>
        </form>

        <button class="link-button" type="button" @click="toggle">
          {{ isRegister ? 'Have an account? Log in' : 'New here? Create an account' }}
        </button>

        <div class="auth-divider"><span>or</span></div>

        <div class="auth-alt">
          <button class="ghost-button" type="button" @click="loginWithGoogle">
            Continue with Google
          </button>
          <details class="dev-login">
            <summary>Use dev login</summary>
            <div class="dev-login-body">
              <input v-model="devEmail" type="email" placeholder="dev@theta.local" />
              <button class="ghost-button compact-button" type="button" :disabled="loading" @click="devLogin">
                Dev sign in
              </button>
            </div>
          </details>
        </div>
      </div>
    </section>
  </div>
</template>
