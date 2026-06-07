export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',
  devtools: { enabled: false },
  nitro: {
    preset: 'cloudflare_module'
  },
  experimental: {
    appManifest: false
  },
  runtimeConfig: {
    thetaApiBase: process.env.THETA_API_BASE || 'https://aerosol-reformer-twirl.ngrok-free.dev',
    public: {
      thetaApiBase: process.env.THETA_API_BASE || 'https://aerosol-reformer-twirl.ngrok-free.dev',
      clarityId: process.env.NUXT_PUBLIC_CLARITY_ID || ''
    }
  },
  modules: ['@nuxtjs/google-fonts'],
  googleFonts: {
    families: {
      Inter: [400, 500, 600, 700, 800],
      'Bungee Shade': [400],
      Fraunces: [400, 500, 600, 700, 900]
    },
    display: 'swap'
  },
  app: {
    head: {
      title: 'Theeta',
      meta: [
        {
          name: 'description',
          content: 'Save Instagram reels and resolve restaurant locations with AI.'
        },
        { name: 'theme-color', content: '#d1f64a' }
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon/favicon.ico' },
        { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon/favicon-32x32.png' },
        { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/favicon/favicon-16x16.png' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/favicon/apple-touch-icon.png' },
        { rel: 'manifest', href: '/favicon/site.webmanifest' }
      ]
    }
  }
})
