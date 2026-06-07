<script setup lang="ts">
const { user } = await useTheta()

// Logged-in users skip the marketing page and go to the app.
watch(user, () => {
  if (user.value) navigateTo('/dashboard')
}, { immediate: true })

const features = [
  {
    icon: '🎬',
    title: 'Share a reel',
    body: 'Send any Instagram food reel to Theta — or paste the link. That is the whole job.'
  },
  {
    icon: '✨',
    title: 'AI finds the spot',
    body: 'Theta watches, reads the caption and comments, and resolves the exact restaurant.'
  },
  {
    icon: '📍',
    title: 'Saved on your map',
    body: 'Every spot lands on your personal map and list, ready for the next time you are hungry.'
  }
]
</script>

<template>
  <div class="edu">
    <!-- Nav -->
    <header class="edu-nav">
      <a class="edu-brand" href="/" aria-label="Theeta home">
        <img src="/images/logo.png" alt="" />
        <span>theeta.in</span>
      </a>
      <nav class="edu-links" aria-label="Primary">
        <a href="#top" class="is-active">Home</a>
        <a href="#features">Features</a>
        <a href="#about">About</a>
      </nav>
      <div class="edu-actions">
        <button class="edu-login" type="button" @click="navigateTo('/login')">Login</button>
        <button class="edu-pill-outline" type="button" @click="navigateTo('/login')">Get the App</button>
      </div>
    </header>

    <!-- Hero -->
    <section id="top" class="edu-hero">
      <div class="edu-hero-copy">
        <span class="edu-badge">
          <span class="edu-badge-dot" aria-hidden="true">🍜</span>
          The tastiest reels, resolved
        </span>

        <h1 class="edu-title">
          Turn reels<br />
          into real<br />
          <span class="edu-accent">food spots
            <svg class="edu-squiggle" viewBox="0 0 220 18" fill="none" aria-hidden="true">
              <path d="M3 13c40-12 90-12 130-4s60 8 84-2" stroke="currentColor" stroke-width="5" stroke-linecap="round" />
            </svg></span>!
        </h1>

        <p class="edu-sub">
          Save the Instagram reels you love, and let AI pin the exact restaurant —
          on your map, ready when the craving hits.
        </p>

        <div class="edu-cta">
          <button class="edu-pill-solid" type="button" @click="navigateTo('/login')">Get Started</button>
          <button class="edu-pill-ghost" type="button" @click="navigateTo('/login')">
            <span class="edu-play" aria-hidden="true">▶</span>
            Watch Video
          </button>

          <svg class="edu-arrow" viewBox="0 0 120 96" fill="none" aria-hidden="true">
            <path d="M112 10C70 6 30 30 34 78" stroke="currentColor" stroke-width="6" stroke-linecap="round" />
            <path d="M20 60l14 20 22-10" stroke="currentColor" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
        </div>

        <div class="edu-stat">
          <strong>1k+</strong>
          <p>Food reels turned into<br />real, mapped restaurants.</p>
        </div>
      </div>

      <!-- App preview -->
      <div class="edu-hero-art">
        <span class="edu-spark edu-spark-1" aria-hidden="true">✦</span>
        <span class="edu-spark edu-spark-2" aria-hidden="true">✦</span>
        <img class="edu-hero-img" src="/images/hero.png" alt="Theeta app preview" />
      </div>
    </section>

    <!-- Problem story -->
    <section id="problem" class="edu-problem">
      <p class="edu-eyebrow">Sound familiar?</p>
      <h2 class="edu-h2">The reel was perfect.<br />The plan fell apart.</h2>

      <div class="edu-story">
        <article class="edu-story-card s1">
          <span class="edu-story-emoji" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 2 11 13" /><path d="M22 2 15 22l-4-9-9-4 20-7Z" /></svg>
          </span>
          <span class="edu-story-step">Step 1</span>
          <h3>You share it</h3>
          <p>A friend drops a mouth-watering food reel. You save it for “someday”.</p>
        </article>
        <span class="edu-story-arrow" aria-hidden="true">→</span>
        <article class="edu-story-card s2">
          <span class="edu-story-emoji" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7" /><path d="m21 21-4.3-4.3" /></svg>
          </span>
          <span class="edu-story-step">Step 2</span>
          <h3>You can’t find it</h3>
          <p>Someday comes — now you’re digging through captions, comments and DMs for a location that’s barely there.</p>
        </article>
        <span class="edu-story-arrow" aria-hidden="true">→</span>
        <article class="edu-story-card s3">
          <span class="edu-story-emoji" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.3 3.3 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.3a2 2 0 0 0-3.4 0Z" /><path d="M12 9v4" /><path d="M12 17h.01" /></svg>
          </span>
          <span class="edu-story-step">Step 3</span>
          <h3>You can’t trust it</h3>
          <p>Half the spots are paid promos or staged hype. Was the food even real?</p>
        </article>
      </div>

      <div class="edu-solution">
        <div class="edu-solution-copy">
          <p class="edu-solution-kicker">Where theeta.in comes in</p>
          <h3>Every saved reel → the real spot, on your map.</h3>
          <p class="edu-solution-body">
            We start by killing the worst part: the endless hunt. AI watches each reel and
            resolves the exact restaurant for you. Trust scoring for fake hype and paid
            promos is what we are building next.
          </p>
          <button class="edu-pill-solid" type="button" @click="navigateTo('/login')">Save your first spot</button>
        </div>
        <span class="edu-solution-emoji" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" /><circle cx="12" cy="10" r="3" /></svg>
        </span>
      </div>
    </section>

    <!-- Features -->
    <section id="features" class="edu-features">
      <p class="edu-eyebrow">How it works</p>
      <h2 class="edu-h2">Three taps from reel to restaurant</h2>
      <div class="edu-feature-grid">
        <article v-for="feature in features" :key="feature.title" class="edu-feature">
          <span class="edu-feature-icon" aria-hidden="true">{{ feature.icon }}</span>
          <h3>{{ feature.title }}</h3>
          <p>{{ feature.body }}</p>
        </article>
      </div>
    </section>

    <!-- About / CTA -->
    <section id="about" class="edu-about">
      <div class="edu-about-card">
        <h2>Never lose a food reel again.</h2>
        <p>Theta keeps the spots, the map, and the memory — so you just show up and eat.</p>
        <button class="edu-pill-solid" type="button" @click="navigateTo('/login')">Start saving spots</button>
      </div>
    </section>
  </div>
</template>

<style scoped>
.edu {
  --p: #8b80d6;
  --p2: #a99ff0;
  --p-soft: #ece9fb;
  --peach: #f3a18b;
  --ink: #2c2b3a;
  --muted: #6b6a7c;
  --bg: #f6f5fb;
  --card: #ffffff;
  background: linear-gradient(180deg, #ffffff 0%, var(--bg) 100%);
  color: var(--ink);
  min-height: 100vh;
  padding-bottom: 40px;
  overflow-x: hidden;
}

/* Nav */
.edu-nav {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 22px 48px;
  max-width: 1240px;
  margin: 0 auto;
}

.edu-brand {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
  color: var(--ink);
}

.edu-brand img {
  height: 38px;
  width: auto;
}

.edu-brand span {
  font-size: 1.5rem;
  font-weight: 800;
  letter-spacing: -0.02em;
}

.edu-links {
  display: flex;
  gap: 30px;
  margin: 0 auto;
}

.edu-links a {
  color: var(--ink);
  text-decoration: none;
  font-weight: 600;
  opacity: 0.7;
}

.edu-links a.is-active,
.edu-links a:hover {
  opacity: 1;
  font-weight: 700;
}

.edu-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.edu-login {
  border: 0;
  background: none;
  color: var(--ink);
  font-weight: 700;
  font-size: 1rem;
}

.edu-pill-outline {
  padding: 12px 22px;
  border: 1.5px solid var(--p2);
  border-radius: 999px;
  background: transparent;
  color: var(--p);
  font-weight: 700;
}

.edu-pill-outline:hover {
  background: var(--p-soft);
}

/* Hero */
.edu-hero {
  display: grid;
  grid-template-columns: 1.05fr 0.95fr;
  gap: 40px;
  align-items: center;
  max-width: 1240px;
  margin: 0 auto;
  padding: 30px 48px 60px;
}

.edu-badge {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 8px 16px 8px 8px;
  border-radius: 999px;
  background: var(--p-soft);
  color: var(--ink);
  font-weight: 600;
  font-size: 0.95rem;
}

.edu-badge-dot {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: #fff;
  font-size: 0.95rem;
}

.edu-title {
  font-family: 'Fraunces', Georgia, serif;
  font-weight: 900;
  font-size: clamp(2.8rem, 6vw, 5rem);
  line-height: 1.05;
  letter-spacing: -0.01em;
  margin: 22px 0 46px;
  color: var(--ink);
}

.edu-accent {
  position: relative;
  color: var(--p);
  white-space: nowrap;
}

.edu-squiggle {
  position: absolute;
  left: 0;
  right: 0;
  bottom: -0.22em;
  width: 100%;
  height: 0.34em;
  color: var(--p2);
}

.edu-sub {
  max-width: 460px;
  color: var(--muted);
  font-size: 1.12rem;
  line-height: 1.6;
}

.edu-cta {
  position: relative;
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  margin: 28px 0 34px;
}

.edu-arrow {
  position: absolute;
  left: calc(100% + 8px);
  top: -18px;
  width: 88px;
  height: 70px;
  color: var(--peach);
  transform: rotate(6deg);
}

.edu-pill-solid {
  padding: 16px 32px;
  border: 0;
  border-radius: 999px;
  background: var(--p);
  color: #fff;
  font-weight: 700;
  font-size: 1.02rem;
  box-shadow: 0 12px 24px -10px var(--p);
  transition: transform 140ms ease;
}

.edu-pill-solid:hover {
  transform: translateY(-2px);
}

.edu-pill-ghost {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  padding: 15px 26px;
  border: 1.5px solid #e4e1f2;
  border-radius: 999px;
  background: #fff;
  color: var(--ink);
  font-weight: 700;
  font-size: 1.02rem;
}

.edu-play {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: var(--p-soft);
  color: var(--p);
  font-size: 0.7rem;
}

.edu-stat {
  display: flex;
  align-items: center;
  gap: 18px;
  padding: 18px 22px;
  border-radius: 22px;
  background: #fff;
  box-shadow: 0 20px 40px -28px rgba(44, 43, 58, 0.5);
  width: fit-content;
}

.edu-stat strong {
  font-family: 'Fraunces', serif;
  font-size: 2.4rem;
  font-weight: 800;
  color: var(--p);
}

.edu-stat p {
  margin: 0;
  color: var(--muted);
  font-weight: 600;
  line-height: 1.4;
}

/* Phone art */
.edu-hero-art {
  position: relative;
  display: grid;
  place-items: center;
  padding: 20px;
}

.edu-spark {
  position: absolute;
  color: var(--p2);
  font-size: 1.6rem;
}

.edu-spark-1 {
  top: 6%;
  left: 12%;
  color: var(--peach);
}

.edu-spark-2 {
  top: 18%;
  right: 16%;
}

.edu-hero-img {
  width: 100%;
  max-width: 560px;
  height: auto;
  display: block;
  filter: drop-shadow(0 50px 90px rgba(44, 43, 58, 0.35));
}

.edu-phone {
  width: 320px;
  max-width: 100%;
  padding: 20px;
  border-radius: 36px;
  background: #fff;
  box-shadow: 0 50px 90px -40px rgba(44, 43, 58, 0.55);
  border: 1px solid #efedf8;
}

.edu-phone-status {
  display: flex;
  justify-content: space-between;
  font-size: 0.78rem;
  color: var(--muted);
  font-weight: 600;
  margin-bottom: 16px;
}

.edu-greet {
  margin: 0;
  color: var(--muted);
  font-weight: 600;
}

.edu-greet-name {
  margin: 2px 0 16px;
  font-family: 'Fraunces', serif;
  font-size: 1.6rem;
  font-weight: 700;
}

.edu-highlight {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 16px;
  border-radius: 22px;
  background: var(--p-soft);
  margin-bottom: 16px;
}

.edu-highlight strong {
  display: block;
  font-size: 1.05rem;
}

.edu-highlight p {
  margin: 4px 0 10px;
  color: var(--muted);
  font-size: 0.88rem;
}

.edu-highlight button {
  padding: 8px 16px;
  border: 0;
  border-radius: 999px;
  background: var(--ink);
  color: #fff;
  font-weight: 700;
  font-size: 0.82rem;
}

.edu-highlight-emoji {
  font-size: 2.4rem;
}

.edu-chips {
  display: flex;
  gap: 8px;
  margin-bottom: 18px;
}

.edu-chip {
  padding: 7px 14px;
  border-radius: 999px;
  background: #f4f3fa;
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--muted);
}

.edu-chip.is-on {
  background: var(--p);
  color: #fff;
}

.edu-saved-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.edu-saved-head strong {
  font-size: 1.05rem;
}

.edu-saved-head span {
  color: var(--p);
  font-weight: 700;
  font-size: 0.85rem;
}

.edu-mini-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.edu-mini {
  display: grid;
  gap: 10px;
  padding: 16px;
  border-radius: 20px;
  min-height: 96px;
  align-content: space-between;
}

.edu-mini span {
  font-size: 1.6rem;
}

.edu-mini b {
  font-size: 0.92rem;
}

.edu-mini-a {
  background: #fde7df;
}

.edu-mini-b {
  background: #e6e2fb;
}

/* Problem story */
.edu-problem {
  max-width: 1100px;
  margin: 0 auto;
  padding: 50px 48px 10px;
  text-align: center;
}

.edu-story {
  display: grid;
  grid-template-columns: 1fr auto 1fr auto 1fr;
  align-items: stretch;
  gap: 14px;
  margin: 34px 0 28px;
}

.edu-story-card {
  position: relative;
  padding: 30px 26px;
  border-radius: 26px;
  text-align: left;
  box-shadow: 0 14px 30px -24px rgba(44, 43, 58, 0.3);
  transition: transform 220ms ease, box-shadow 220ms ease;
}

.edu-story-card.s1 {
  background: #ece9fb;
  transform: rotate(-1.6deg);
}

.edu-story-card.s2 {
  background: #e6eefc;
  transform: rotate(1deg);
}

.edu-story-card.s3 {
  background: #fde7df;
  transform: rotate(-1deg);
}

.edu-story-card:hover {
  transform: rotate(0deg) translateY(-5px);
  box-shadow: 0 20px 38px -26px rgba(44, 43, 58, 0.35);
}

.edu-story-emoji {
  display: grid;
  place-items: center;
  width: 56px;
  height: 56px;
  border-radius: 18px;
  background: #fff;
  color: var(--p);
  box-shadow: 0 12px 22px -14px rgba(44, 43, 58, 0.6);
  margin-bottom: 16px;
}

.edu-story-emoji svg {
  width: 27px;
  height: 27px;
}

.s1 .edu-story-emoji {
  color: #8b80d6;
}

.s2 .edu-story-emoji {
  color: #4f8bef;
}

.s3 .edu-story-emoji {
  color: #e8765a;
}

.edu-story-step {
  display: inline-block;
  margin: 0 0 10px;
  padding: 4px 11px;
  border-radius: 999px;
  background: rgba(139, 128, 214, 0.18);
  color: var(--p);
  font-weight: 800;
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.09em;
}

.edu-story-card h3 {
  font-size: 1.3rem;
  margin: 0 0 8px;
}

.edu-story-card p {
  margin: 0;
  color: var(--muted);
  line-height: 1.55;
}

.edu-story-arrow {
  align-self: center;
  color: var(--peach);
  font-size: 2.1rem;
  font-weight: 800;
}

.edu-solution {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  text-align: left;
  padding: 42px 46px;
  border-radius: 32px;
  background: linear-gradient(135deg, #2c2b3a 0%, #4a4373 100%);
  color: #fff;
  box-shadow: 0 40px 70px -40px rgba(44, 43, 58, 0.8);
  overflow: hidden;
}

.edu-solution-kicker {
  color: var(--p2);
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  font-size: 0.8rem;
  margin-bottom: 10px;
}

.edu-solution h3 {
  font-family: 'Fraunces', serif;
  font-weight: 800;
  font-size: clamp(1.5rem, 3vw, 2.1rem);
  margin: 0 0 12px;
  color: #fff;
}

.edu-solution-body {
  max-width: 560px;
  color: rgba(255, 255, 255, 0.82);
  line-height: 1.6;
  margin-bottom: 20px;
}

.edu-solution .edu-pill-solid {
  background: #fff;
  color: var(--p);
  box-shadow: none;
}

.edu-solution-emoji {
  flex: 0 0 auto;
  color: #fff;
  filter: drop-shadow(0 14px 20px rgba(0, 0, 0, 0.35));
}

.edu-solution-emoji svg {
  width: 88px;
  height: 88px;
}

/* Features */
.edu-features {
  max-width: 1100px;
  margin: 0 auto;
  padding: 40px 48px 20px;
  text-align: center;
}

.edu-eyebrow {
  color: var(--p);
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 0.82rem;
  margin-bottom: 8px;
}

.edu-h2 {
  font-family: 'Fraunces', serif;
  font-weight: 800;
  font-size: clamp(1.9rem, 4vw, 2.8rem);
  margin: 0 0 34px;
}

.edu-feature-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 22px;
}

.edu-feature {
  padding: 30px 24px;
  border-radius: 26px;
  background: #fff;
  box-shadow: 0 30px 50px -36px rgba(44, 43, 58, 0.5);
  text-align: left;
}

.edu-feature-icon {
  display: grid;
  place-items: center;
  width: 54px;
  height: 54px;
  border-radius: 16px;
  background: var(--p-soft);
  font-size: 1.6rem;
  margin-bottom: 16px;
}

.edu-feature h3 {
  font-size: 1.25rem;
  margin: 0 0 8px;
}

.edu-feature p {
  margin: 0;
  color: var(--muted);
  line-height: 1.55;
}

/* About / CTA */
.edu-about {
  max-width: 1100px;
  margin: 0 auto;
  padding: 50px 48px;
}

.edu-about-card {
  padding: 56px 40px;
  border-radius: 32px;
  background: linear-gradient(135deg, var(--p) 0%, var(--p2) 100%);
  color: #fff;
  text-align: center;
  box-shadow: 0 40px 70px -40px var(--p);
}

.edu-about-card h2 {
  font-family: 'Fraunces', serif;
  font-weight: 800;
  font-size: clamp(1.9rem, 4vw, 2.8rem);
  margin: 0 0 12px;
}

.edu-about-card p {
  max-width: 460px;
  margin: 0 auto 24px;
  opacity: 0.92;
  font-size: 1.08rem;
}

.edu-about-card .edu-pill-solid {
  background: #fff;
  color: var(--p);
  box-shadow: none;
}

/* Responsive */
@media (max-width: 900px) {
  .edu-hero {
    grid-template-columns: 1fr;
    text-align: center;
    padding-top: 10px;
  }

  .edu-badge,
  .edu-stat {
    margin-left: auto;
    margin-right: auto;
  }

  .edu-sub {
    margin-left: auto;
    margin-right: auto;
  }

  .edu-cta {
    justify-content: center;
  }

  .edu-hero-art {
    order: -1;
  }

  .edu-arrow {
    display: none;
  }

  .edu-story {
    grid-template-columns: 1fr;
  }

  .edu-story-card.s1,
  .edu-story-card.s2,
  .edu-story-card.s3 {
    transform: none;
  }

  .edu-story-arrow {
    display: none;
  }

  .edu-solution {
    flex-direction: column;
    text-align: center;
  }

  .edu-solution-body {
    margin-left: auto;
    margin-right: auto;
  }

  .edu-feature-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 720px) {
  .edu-nav {
    flex-wrap: nowrap;
    justify-content: space-between;
    gap: 12px;
    padding: 16px 18px;
  }

  /* Keep the header on one line — drop the in-page anchors on small screens. */
  .edu-links {
    display: none;
  }

  .edu-brand img {
    height: 30px;
  }

  .edu-brand span {
    font-size: 1.2rem;
  }

  .edu-actions {
    gap: 10px;
  }

  .edu-login {
    font-size: 0.95rem;
  }

  .edu-pill-outline {
    padding: 10px 16px;
    font-size: 0.95rem;
  }

  .edu-hero,
  .edu-features,
  .edu-about {
    padding-left: 22px;
    padding-right: 22px;
  }
}
</style>
