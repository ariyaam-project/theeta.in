<template>
  <main class="shell">
    <NuxtPage />
    <footer class="site-footer" aria-label="Footer">
      <nav class="footer-links" aria-label="Footer links">
        <NuxtLink to="/privacy">Privacy</NuxtLink>
        <NuxtLink to="/terms">Terms</NuxtLink>
        <a href="mailto:contact@theeta.in">contact@theeta.in</a>
        <a href="https://github.com/" target="_blank" rel="noopener">GitHub</a>
        <a href="https://instagram.com/theetadotin" target="_blank" rel="noopener">Instagram</a>
      </nav>
      <strong aria-hidden="true">THEETA</strong>
    </footer>
  </main>
</template>

<style>
:root {
  color-scheme: light;
  --bg: #050505;
  --cream: #f4f1e9;
  --cream-2: #fbf6ec;
  --ink: #14241a;
  --muted: #5c6b5a;
  --line: #14241a;
  --panel: #f4f1e9;
  --panel-strong: #c8ef4d;
  --accent: #ff6a2b;
  --accent-dark: #14241a;
  --green: #c8ef4d;
  --green-soft: #e3efc7;
  --forest: #1c3a28;
  --lavender: #e3efc7;
  --shadow: 8px 8px 0 #14241a;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-width: 320px;
  background: var(--cream);
  color: var(--ink);
}

button,
input,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

.shell {
  display: flex;
  flex-direction: column;
  width: 100%;
  margin: 0;
  padding: 0;
  min-height: 100vh;
}

.shell > .site-footer {
  margin-top: auto;
}

.landing-frame {
  position: relative;
  border: 2px solid var(--line);
  border-left: 0;
  border-right: 0;
  border-top: 0;
  background: var(--cream);
  overflow: hidden;
  box-shadow: none;
}

.landing-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  min-height: 88px;
  padding: 0 56px;
}

.brand-mark {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  text-decoration: none;
}

.brand-mark img {
  height: 52px;
  width: auto;
  display: block;
}

.brand-name {
  color: var(--ink);
  font-size: 1.6rem;
  font-weight: 900;
  letter-spacing: -0.01em;
}

.nav-cta {
  min-height: 44px;
  padding: 0 24px;
  border: 2px solid var(--line);
  border-radius: 999px;
  background: var(--ink);
  color: #fff;
  font-weight: 900;
  white-space: nowrap;
  text-transform: uppercase;
  box-shadow: 4px 4px 0 var(--line);
  transition: transform 120ms ease, box-shadow 120ms ease;
}

.nav-cta:hover {
  transform: translate(-1px, -1px);
  box-shadow: 6px 6px 0 var(--line);
}

.nav-cta:active {
  transform: translate(2px, 2px);
  box-shadow: 1px 1px 0 var(--line);
}

.profile-menu {
  position: relative;
}

.profile-pill {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  padding: 6px 18px 6px 6px;
  border: 2px solid var(--line);
  border-radius: 999px;
  background: var(--cream);
  box-shadow: 4px 4px 0 var(--line);
}

.profile-pill:active {
  transform: translate(2px, 2px);
  box-shadow: 1px 1px 0 var(--line);
}

.profile-pic {
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  overflow: hidden;
  border: 2px solid var(--line);
  border-radius: 50%;
  background: var(--green);
  color: var(--ink);
  font-weight: 900;
}

.profile-pic img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.profile-name {
  font-size: 1.1rem;
  font-weight: 900;
  text-transform: uppercase;
}

.profile-dropdown {
  position: absolute;
  right: 0;
  top: calc(100% + 10px);
  z-index: 20;
  display: grid;
  min-width: 180px;
  border: 2px solid var(--line);
  background: var(--cream);
  box-shadow: 8px 8px 0 var(--line);
}

.profile-link {
  padding: 14px 18px;
  border: 0;
  border-bottom: 2px solid var(--line);
  background: var(--cream);
  color: var(--ink);
  font-weight: 800;
  text-align: left;
  text-decoration: none;
}

.profile-link:last-child {
  border-bottom: 0;
}

.profile-link:hover {
  background: var(--green);
}

.profile-backdrop {
  position: fixed;
  inset: 0;
  z-index: 10;
  border: 0;
  background: transparent;
}

.pop-enter-active,
.pop-leave-active {
  transition: opacity 140ms ease, transform 140ms ease;
}

.pop-enter-from,
.pop-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

.landing-grid {
  display: grid;
  grid-template-columns: 58% 42%;
  grid-template-rows: 1fr;
  min-height: calc(100vh - 150px);
}

.landing-main,
.landing-side {
  position: relative;
  border-bottom: 2px solid var(--line);
}

.landing-main {
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 56px 44px 64px;
  border-right: 2px solid var(--line);
  background:
    radial-gradient(circle at 10% 10%, rgba(255, 242, 223, 0.8), transparent 24rem),
    var(--cream);
}

.title-row {
  display: flex;
  align-items: flex-start;
  gap: 22px;
  max-width: 640px;
}

.title-row h2 {
  margin: 0;
  font-size: clamp(4.6rem, 9vw, 8.5rem);
  line-height: 0.82;
  letter-spacing: -0.04em;
  font-weight: 900;
  text-transform: uppercase;
}

.hero-caption {
  max-width: 620px;
  margin: 22px 0 0;
  color: var(--muted);
  font-size: 1.7rem;
  font-weight: 800;
  line-height: 1.35;
}

.hero-photo {
  width: 100%;
  max-width: 620px;
  margin: 0;
  object-fit: contain;
}

.hl {
  padding: 0.05em 0.18em;
  background: linear-gradient(transparent 58%, var(--green) 58% 92%, transparent 92%);
  box-decoration-break: clone;
  -webkit-box-decoration-break: clone;
}

.landing-side--photo {
  background: var(--lavender);
}

.area-hero {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 24px;
  align-items: stretch;
  min-height: calc(100vh - 150px);
  padding: 32px 56px 56px;
  background: var(--cream);
}

.area-left {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.area-panel {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 26px;
  padding: 48px 46px;
  border: 2px solid var(--line);
  border-radius: 36px;
  background: var(--green);
  box-shadow: 8px 8px 0 var(--line);
}

.area-title {
  margin: 0;
  font-size: clamp(2.6rem, 4.6vw, 4.2rem);
  line-height: 1.22;
  letter-spacing: -0.02em;
  font-weight: 900;
}

.area-mark {
  display: inline-block;
  margin-top: 0.12em;
  padding: 0.04em 0.2em;
  border: 2px solid var(--line);
  border-radius: 14px;
  background: #fffdf8;
  box-shadow: 3px 3px 0 var(--line);
}

.area-desc {
  margin: 0;
  max-width: 42ch;
  color: rgba(5, 5, 5, 0.78);
  font-size: 1.1rem;
  font-weight: 700;
  line-height: 1.55;
}

.area-cta {
  align-self: flex-start;
  min-height: 56px;
  padding: 0 34px;
  border: 2px solid var(--line);
  border-radius: 999px;
  background: #fffdf8;
  color: var(--ink);
  font-size: 1.05rem;
  font-weight: 900;
  box-shadow: 4px 4px 0 var(--line);
  transition: transform 120ms ease, box-shadow 120ms ease;
}

.area-cta:hover {
  transform: translate(-1px, -1px);
  box-shadow: 6px 6px 0 var(--line);
}

.area-cta:active {
  transform: translate(2px, 2px);
  box-shadow: 1px 1px 0 var(--line);
}

.area-footnote {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 12px;
  margin-top: auto;
}

.area-star {
  display: inline-flex;
  align-items: flex-start;
  gap: 12px;
  width: fit-content;
  max-width: 34ch;
  margin: auto 0;
  color: rgba(20, 36, 26, 0.86);
  font-size: 0.98rem;
  font-weight: 900;
  line-height: 1.45;
  text-decoration: none !important;
}

.area-star span {
  display: grid;
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  margin-top: 2px;
  place-items: center;
  border: 0;
  border-radius: 0;
  background: transparent;
  color: var(--line);
  font-size: 1rem;
  line-height: 1;
  box-shadow: none;
}

.area-star:hover {
  text-decoration: underline !important;
  text-underline-offset: 4px;
}

.area-credit {
  margin: 0;
  font-size: 0.9rem;
  font-weight: 800;
  color: rgba(20, 36, 26, 0.7);
}

.area-stat {
  display: flex;
  align-items: center;
  gap: 22px;
  padding: 22px 28px;
  border: 2px dashed var(--line);
  border-radius: 28px;
  background: var(--cream);
}

.area-stat-copy strong {
  display: block;
  font-size: 2.4rem;
  line-height: 1;
  font-weight: 900;
}

.area-stat-copy span {
  font-weight: 800;
  color: var(--muted);
}

.face-row {
  display: flex;
  align-items: center;
}

.face-row img,
.face-fill {
  width: 46px;
  height: 46px;
  margin-left: -12px;
  border: 2px solid var(--line);
  border-radius: 50%;
  background: var(--green);
  object-fit: cover;
}

.face-row img:first-child {
  margin-left: 0;
}

.face-fill {
  display: grid;
  place-items: center;
  background: #fffdf8;
  font-weight: 900;
}

.area-image {
  position: relative;
  min-height: 480px;
  border: 2px solid var(--line);
  border-radius: 36px;
  overflow: hidden;
  background: var(--forest);
  box-shadow: 8px 8px 0 var(--line);
}

.area-image > img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center;
}

.area-badge {
  position: absolute;
  padding: 10px 18px;
  border: 2px solid var(--line);
  border-radius: 16px;
  background: var(--green);
  font-weight: 900;
  box-shadow: 4px 4px 0 var(--line);
}

.badge-agro {
  top: 26px;
  left: 26px;
}

.badge-acres {
  right: 26px;
  bottom: 96px;
  background: #fffdf8;
  transform: rotate(-4deg);
}

.badge-green {
  left: 26px;
  bottom: 26px;
}

.landing-side {
  position: relative;
  display: grid;
  place-items: center;
  padding: 54px 40px;
  background: var(--lavender);
  overflow: hidden;
}

.orbit-labels {
  position: absolute;
  inset: 0;
  z-index: 3;
  pointer-events: none;
}

.sticker {
  position: absolute;
  display: inline-block;
  width: max-content;
  max-width: 60%;
  padding: 6px 20px;
  color: #050505;
  font-size: clamp(1.5rem, 2.2vw, 2rem);
  font-weight: 900;
  line-height: 1;
  text-transform: uppercase;
  clip-path: polygon(2% 12%, 11% 8%, 10% 0, 20% 8%, 29% 2%, 31% 10%, 43% 7%, 44% 15%, 55% 5%, 58% 14%, 71% 11%, 72% 19%, 89% 12%, 98% 24%, 95% 88%, 86% 92%, 84% 100%, 74% 92%, 62% 98%, 58% 89%, 45% 94%, 42% 86%, 29% 94%, 26% 85%, 13% 90%, 8% 79%);
}

.sticker-cream {
  top: 7%;
  right: 8%;
  background: #eadcc8;
  transform: rotate(-6deg);
}

.sticker-lime {
  bottom: 12%;
  left: 5%;
  background: var(--green);
  transform: rotate(5deg);
}

.sticker-orange {
  bottom: 6%;
  right: 9%;
  background: var(--accent);
  transform: rotate(-4deg);
}

.solar-system {
  position: relative;
  min-height: 430px;
  display: grid;
  place-items: center;
  isolation: isolate;
}

.solar-ring {
  position: absolute;
  border: 2px solid rgba(5, 5, 5, 0.42);
  border-radius: 50%;
}

.ring-one {
  width: 230px;
  height: 140px;
}

.ring-two {
  width: 340px;
  height: 220px;
}

.ring-three {
  width: 450px;
  height: 300px;
}

.ring-four {
  width: 560px;
  height: 372px;
  border-color: rgba(5, 5, 5, 0.22);
}

.solar-core {
  position: relative;
  z-index: 2;
  width: min(210px, 52%);
  filter: drop-shadow(10px 12px 0 rgba(5, 5, 5, 0.8));
  animation: solarFloat 5s ease-in-out infinite;
}

.orbit-item {
  position: absolute;
  z-index: 3;
  object-fit: contain;
  filter: drop-shadow(6px 8px 0 rgba(5, 5, 5, 0.55));
}

.orbit-mayo {
  width: 104px;
  offset-path: ellipse(170px 110px at 50% 50%);
  offset-rotate: 0deg;
  animation: orbitPath 16s linear infinite;
}

.orbit-cola {
  width: 104px;
  offset-path: ellipse(225px 150px at 50% 50%);
  offset-rotate: 0deg;
  animation: orbitPath 20s linear infinite;
  animation-delay: -10s;
}

.orbit-person {
  position: absolute;
  z-index: 4;
  width: 58px;
  height: 58px;
  offset-rotate: 0deg;
  animation: orbitPath 24s linear infinite;
}

.orbit-person img,
.orbit-person-fallback {
  display: grid;
  width: 100%;
  height: 100%;
  place-items: center;
  border: 2px solid var(--line);
  border-radius: 50%;
  background: linear-gradient(135deg, #f7c96b, #ffefe0);
  object-fit: cover;
  color: #050505;
  font-weight: 900;
  box-shadow: 4px 4px 0 #050505;
}

.rank-tag {
  position: absolute;
  top: -10px;
  right: -10px;
  display: grid;
  min-width: 26px;
  height: 26px;
  place-items: center;
  padding: 0 6px;
  border: 2px solid var(--line);
  border-radius: 999px;
  background: var(--green);
  color: #050505;
  font-size: 0.8rem;
  font-weight: 900;
}

.orbit-person-1 {
  offset-path: ellipse(115px 70px at 50% 50%);
  offset-distance: 55%;
  animation-duration: 22s;
}

.orbit-person-2 {
  offset-path: ellipse(170px 110px at 50% 50%);
  offset-distance: 80%;
  animation-duration: 26s;
}

.orbit-person-2 .rank-tag {
  background: #eadcc8;
}

.orbit-person-3 {
  offset-path: ellipse(225px 150px at 50% 50%);
  offset-distance: 35%;
  animation-duration: 30s;
}

.orbit-person-3 .rank-tag {
  background: var(--accent);
  color: #fffaf2;
}

.leaderboard-section {
  display: grid;
  grid-template-columns: 0.85fr 1.15fr;
  gap: 44px;
  align-items: end;
  padding: 76px 70px 86px;
  background: linear-gradient(180deg, #fbf6ec, #f2e7da);
}

.leaderboard-copy h2 {
  margin: 0 0 14px;
  font-size: clamp(3.5rem, 8vw, 7rem);
  line-height: 0.85;
  letter-spacing: -0.04em;
  text-transform: uppercase;
}

.leaderboard-copy p:not(.section-kicker) {
  max-width: 420px;
  margin: 0;
  color: var(--muted);
  font-size: 1.2rem;
  font-weight: 800;
  line-height: 1.45;
}

.podium-stage {
  display: grid;
  grid-template-columns: 1fr 1.15fr 1fr;
  align-items: end;
  gap: 12px;
  min-height: 470px;
  padding: 36px 34px 0;
  border: 2px solid var(--line);
  background:
    radial-gradient(circle at 50% 10%, rgba(209, 246, 74, 0.38), transparent 18rem),
    var(--lavender);
  box-shadow: 10px 10px 0 #050505;
}

.podium-person {
  display: grid;
  justify-items: center;
  align-items: end;
}

.avatar-head {
  display: grid;
  width: 78px;
  height: 78px;
  place-items: center;
  overflow: hidden;
  border: 3px solid var(--line);
  border-radius: 50%;
  background: linear-gradient(135deg, #f7c96b, #ffefe0);
  color: #050505;
  font-size: 2rem;
  font-weight: 900;
  box-shadow: 6px 6px 0 #050505;
}

.avatar-head img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 50%;
}

.avatar-head.champion {
  width: 96px;
  height: 96px;
  background: linear-gradient(135deg, var(--green), #fff0b3);
  font-size: 2.45rem;
}

.stick-body {
  position: relative;
  width: 120px;
  height: 120px;
  margin-top: 12px;
}

.stick-body::before,
.stick-body::after,
.stick-body span,
.stick-body span::before,
.stick-body span::after {
  content: "";
  position: absolute;
  background: #050505;
  border-radius: 999px;
}

.stick-body::before {
  left: 58px;
  top: 0;
  width: 6px;
  height: 78px;
}

.stick-body::after {
  left: 25px;
  top: 34px;
  width: 72px;
  height: 6px;
  transform: rotate(-8deg);
}

.stick-body span::before,
.stick-body span::after {
  top: 72px;
  width: 6px;
  height: 58px;
  transform-origin: top;
}

.stick-body span::before {
  left: 58px;
  transform: rotate(28deg);
}

.stick-body span::after {
  left: 58px;
  transform: rotate(-28deg);
}

.podium-block {
  display: grid;
  justify-items: center;
  align-content: center;
  gap: 8px;
  width: 100%;
  border: 2px solid var(--line);
  border-bottom: 0;
  background: var(--cream);
  text-align: center;
}

.podium-block strong {
  font-size: 4.8rem;
  line-height: 0.85;
}

.podium-block span {
  max-width: 150px;
  font-weight: 900;
}

.podium-block small {
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 800;
}

.podium-empty {
  display: grid;
  gap: 6px;
  align-content: center;
  min-height: 470px;
  padding: 36px;
  border: 2px dashed var(--line);
  background: var(--lavender);
  box-shadow: 10px 10px 0 #050505;
  text-align: center;
}

.podium-empty strong {
  font-size: 1.6rem;
}

.podium-empty span {
  color: var(--muted);
  font-weight: 800;
}

.first .podium-block {
  min-height: 230px;
  background: var(--green);
}

.second .podium-block {
  min-height: 176px;
}

.third .podium-block {
  min-height: 138px;
  background: #ffefe0;
}

.ticker {
  position: relative;
  z-index: 1;
  display: flex;
  min-width: 100%;
  gap: 32px;
  align-items: center;
  justify-content: center;
  min-height: 58px;
  padding: 0 18px;
  border-top: 2px solid var(--line);
  background: #111;
  color: #fff;
  font-size: 1.08rem;
  font-weight: 800;
  white-space: nowrap;
}

.ticker b {
  color: var(--green);
}

.landing-error {
  position: absolute;
  left: 58px;
  bottom: 66px;
  z-index: 5;
  margin: 0;
  color: #9e1f16;
  font-weight: 900;
}

.site-footer {
  position: relative;
  display: grid;
  place-items: center;
  align-content: center;
  min-height: 360px;
  margin-top: 0;
  overflow: hidden;
  background:
    linear-gradient(180deg, #f2e7da 0%, #f6efe1 50%, #ece0cb 100%);
}

.footer-links {
  position: absolute;
  left: 0;
  right: 0;
  top: 72px;
  z-index: 3;
  display: flex;
  flex-wrap: wrap;
  gap: 6px 22px;
  align-items: center;
  justify-content: center;
  padding: 0 22px;
  opacity: 0.62;
}

.footer-links a {
  color: var(--ink);
  font-size: 0.9rem;
  font-weight: 800;
  text-decoration: none;
}

.footer-links a:hover {
  text-decoration: underline;
}

.site-footer > strong {
  position: absolute;
  left: 50%;
  bottom: -46px;
  transform: translateX(-50%);
  color: transparent;
  background: linear-gradient(180deg, rgba(20, 36, 26, 0.92), rgba(20, 36, 26, 0.4));
  -webkit-background-clip: text;
  background-clip: text;
  font-family: "Bungee Shade", Inter, ui-sans-serif, system-ui, sans-serif;
  font-size: clamp(8rem, 27vw, 26rem);
  font-weight: 400;
  line-height: 0.72;
  letter-spacing: 0;
  white-space: nowrap;
}

.hero-panel {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 280px;
  gap: 28px;
  align-items: center;
  min-height: 280px;
  padding: 48px 56px;
  border: 0;
  border-bottom: 2px solid var(--line);
  border-radius: 0;
  background: var(--lavender);
  box-shadow: none;
  overflow: hidden;
}

.hero-panel h1 {
  text-transform: uppercase;
}

.hero-copy {
  max-width: 680px;
}

.eyebrow,
.section-kicker,
.stat-label {
  margin: 0 0 10px;
  color: var(--accent-dark);
  font-size: 0.78rem;
  font-weight: 800;
  letter-spacing: 0;
  text-transform: uppercase;
}

h1,
h2,
h3,
p {
  margin-top: 0;
}

h1 {
  margin-bottom: 14px;
  font-size: clamp(3rem, 7vw, 5.8rem);
  line-height: 0.9;
}

h2 {
  margin-bottom: 10px;
  font-size: clamp(2rem, 5vw, 3.8rem);
  line-height: 1;
}

h3 {
  margin-bottom: 0;
  font-size: 1.1rem;
}

.hero-copy p:not(.eyebrow),
.muted {
  color: var(--muted);
  font-size: 1.05rem;
  line-height: 1.6;
}

.plate-orbit {
  position: relative;
  display: grid;
  place-items: center;
  aspect-ratio: 1;
}

.plate {
  position: relative;
  width: 210px;
  aspect-ratio: 1;
  border-radius: 50%;
  background: radial-gradient(circle, #f6d790 0 46%, #eee3d2 47% 67%, #d5c5b2 68% 100%);
  box-shadow: inset 0 -12px 24px rgba(99, 65, 22, 0.15), 0 24px 40px rgba(99, 65, 22, 0.18);
  animation: plateFloat 4.5s ease-in-out infinite;
}

.rice,
.meat,
.leaf {
  position: absolute;
  display: block;
}

.rice {
  inset: 50px;
  border-radius: 50%;
  background:
    radial-gradient(circle at 34% 38%, #fff8de 0 7px, transparent 8px),
    radial-gradient(circle at 68% 52%, #fff1c1 0 8px, transparent 9px),
    #f1c66e;
}

.meat {
  width: 52px;
  height: 34px;
  border-radius: 45% 55% 52% 48%;
  background: #7b3b22;
  box-shadow: inset 0 5px 0 rgba(255, 255, 255, 0.12);
}

.meat-one {
  top: 76px;
  left: 66px;
  transform: rotate(-18deg);
}

.meat-two {
  right: 62px;
  bottom: 70px;
  transform: rotate(18deg);
}

.leaf {
  right: 62px;
  top: 70px;
  width: 44px;
  height: 22px;
  border-radius: 100% 0;
  background: var(--green);
  transform: rotate(-24deg);
}

.steam {
  position: absolute;
  top: 18px;
  width: 14px;
  height: 86px;
  border-radius: 999px;
  border-left: 3px solid rgba(133, 45, 34, 0.28);
  animation: steamRise 2.8s ease-in-out infinite;
}

.steam-one {
  left: 104px;
}

.steam-two {
  right: 102px;
  animation-delay: 0.8s;
}

.dash-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  min-height: 88px;
  padding: 0 56px;
  border-bottom: 2px solid var(--line);
  background: var(--cream);
}

.workspace {
  margin: 0;
  padding: 48px 56px 64px;
  border: 0;
  border-radius: 0;
  background: var(--cream);
  box-shadow: none;
}

.legal {
  max-width: 720px;
  margin: 0 auto;
  padding: 56px 24px 80px;
}

.legal h1 {
  margin-bottom: 24px;
  text-transform: uppercase;
}

.legal p {
  margin-bottom: 16px;
  color: var(--muted);
  font-size: 1.05rem;
  line-height: 1.6;
}

.legal-note {
  padding: 18px 20px;
  border: 2px solid var(--line);
  background: var(--green-soft);
  box-shadow: 6px 6px 0 var(--line);
  color: var(--ink) !important;
  font-weight: 800;
}

.legal-contact {
  margin-top: 28px;
  color: var(--ink) !important;
  font-weight: 800;
}

.legal a {
  color: var(--accent);
  font-weight: 800;
}

.onboarding {
  display: grid;
  gap: 26px;
  max-width: 620px;
  margin: 56px auto;
  padding: 40px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--green-soft);
  box-shadow: 8px 8px 0 var(--line);
}

.onboarding h2 {
  text-transform: uppercase;
}

.loading-state,
.login-panel {
  display: grid;
  gap: 14px;
  align-content: center;
}

.loading-state {
  justify-items: center;
  min-height: 180px;
}

.spinner {
  width: 44px;
  height: 44px;
  border: 4px solid rgba(179, 63, 47, 0.16);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin 760ms linear infinite;
}

.form-grid,
.log-form {
  display: grid;
  gap: 18px;
}

label {
  display: grid;
  gap: 8px;
  color: var(--muted);
  font-weight: 700;
}

input,
select {
  width: 100%;
  border: 2px solid var(--line);
  border-radius: 0;
  background: #fffdf8;
  color: var(--ink);
  padding: 14px 15px;
  outline: none;
  transition: box-shadow 160ms ease;
}

input:focus {
  box-shadow: 4px 4px 0 var(--accent);
}

select:focus {
  box-shadow: 4px 4px 0 var(--accent);
}

select:disabled {
  opacity: 0.55;
}

label small {
  color: var(--muted);
  font-weight: 600;
}

.input-with-unit {
  display: grid;
  grid-template-columns: 1fr auto;
  align-items: center;
  gap: 10px;
}

.input-with-unit strong {
  color: var(--ink);
}

.primary-button,
.ghost-button {
  min-height: 48px;
  border: 2px solid var(--line);
  border-radius: 0;
  padding: 0 22px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.01em;
  box-shadow: 4px 4px 0 var(--line);
  transition: transform 120ms ease, box-shadow 120ms ease;
}

.primary-button {
  background: var(--ink);
  color: #fff;
}

.primary-button:hover,
.ghost-button:hover {
  transform: translate(-1px, -1px);
  box-shadow: 6px 6px 0 var(--line);
}

.primary-button:active,
.ghost-button:active {
  transform: translate(2px, 2px);
  box-shadow: 1px 1px 0 var(--line);
}

.ghost-button {
  background: var(--cream);
  color: var(--ink);
}

.primary-button:disabled,
.ghost-button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  transform: none;
  box-shadow: 4px 4px 0 var(--line);
}

.input--error {
  border-color: var(--accent);
  box-shadow: 4px 4px 0 var(--accent);
}

.google-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  min-height: 54px;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: #fffdf8;
  color: var(--ink);
  font-weight: 800;
  box-shadow: 0 12px 28px rgba(91, 62, 27, 0.1);
  transition: transform 160ms ease, box-shadow 160ms ease;
}

.google-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 16px 34px rgba(91, 62, 27, 0.14);
}

.google-mark {
  display: grid;
  width: 28px;
  height: 28px;
  place-items: center;
  border-radius: 50%;
  background: #fff;
  color: #4285f4;
  font-weight: 800;
  box-shadow: inset 0 0 0 1px #e2e2e2;
}

.error {
  margin: 0;
  color: #9e1f16;
  font-weight: 700;
}

.error-banner {
  margin-top: 18px;
  padding: 14px 16px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--accent);
  box-shadow: 4px 4px 0 var(--line);
  color: #fffaf2;
  font-weight: 800;
}

.detail-json {
  min-height: 260px;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-word;
  border: 2px solid var(--line);
  background: #fffdf8;
  color: var(--ink);
  box-shadow: 4px 4px 0 var(--line);
  padding: 16px;
}

.location-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(320px, 0.9fr);
  gap: 22px;
  align-items: start;
  padding: 22px;
  border: 2px solid var(--line);
  background:
    radial-gradient(circle at top right, rgba(247, 171, 63, 0.28), transparent 34%),
    #fff8ec;
  box-shadow: 4px 4px 0 var(--line);
}

.location-card[data-empty="true"] {
  grid-template-columns: minmax(0, 1fr);
  background: #fffdf8;
}

.location-card h3 {
  margin: 0 0 8px;
  font-family: var(--font-display);
  font-size: clamp(1.5rem, 3vw, 2.2rem);
  letter-spacing: -0.04em;
}

.location-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin: 0;
}

.location-grid div {
  min-width: 0;
  padding: 14px;
  border: 2px solid rgba(47, 35, 26, 0.2);
  background: rgba(255, 255, 255, 0.62);
}

.location-grid dt {
  color: var(--muted);
  font-size: 0.74rem;
  font-weight: 900;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.location-grid dd {
  margin: 6px 0 0;
  color: var(--ink);
  font-weight: 900;
  overflow-wrap: anywhere;
}

.profile-link small {
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 800;
}

.login-strip {
  align-items: stretch;
}

.inline-login {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
  justify-content: flex-end;
}

.inline-login input {
  min-width: min(280px, 100%);
}

.top-row,
.history-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 18px;
}

.profile-head {
  display: flex;
  align-items: center;
  gap: 16px;
}

.activity {
  display: grid;
  gap: 10px;
  justify-items: end;
}

.activity-title {
  font-size: 0.78rem;
  font-weight: 800;
  letter-spacing: 0;
  text-transform: uppercase;
  color: var(--muted);
}

.activity-grid {
  display: flex;
  gap: 3px;
  padding: 12px;
  border: 2px solid var(--line);
  background: var(--cream);
  box-shadow: 4px 4px 0 var(--line);
  overflow-x: auto;
}

.activity-col {
  display: grid;
  grid-template-rows: repeat(7, 1fr);
  gap: 3px;
}

.activity-cell {
  width: 12px;
  height: 12px;
  border: 1px solid rgba(20, 36, 26, 0.18);
  background: #ece4d6;
}

.activity-cell[data-future='true'] {
  border-color: rgba(20, 36, 26, 0.1);
  background: rgba(236, 228, 214, 0.45);
}

.activity-cell[data-today='true'] {
  border-color: var(--line);
  outline: 2px solid var(--line);
  outline-offset: 2px;
}

.activity-cell[data-level='1'] {
  border-color: rgba(20, 36, 26, 0.28);
  background: #ffb083;
}

.activity-cell[data-level='2'] {
  background: #ff8a47;
}

.activity-cell[data-level='3'] {
  background: #ff6a2b;
}

.activity-cell[data-level='4'] {
  background: #b3300a;
}

.profile-head img {
  width: 64px;
  height: 64px;
  flex: 0 0 auto;
  border: 2px solid var(--line);
  border-radius: 50%;
  box-shadow: 4px 4px 0 var(--line);
}

.profile-head h2 {
  text-transform: uppercase;
}

.stats-grid {
  display: grid;
  grid-template-columns: 1.45fr repeat(4, 1fr);
  gap: 18px;
  margin: 28px 0;
}

.stats-grid article {
  min-height: 146px;
  padding: 20px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--cream);
  box-shadow: 6px 6px 0 var(--line);
}

.stats-grid strong {
  display: block;
  font-size: clamp(1.9rem, 4vw, 3.5rem);
  line-height: 1;
  font-weight: 900;
}

.life-card {
  position: relative;
  overflow: hidden;
  background: var(--green) !important;
}

.life-card em {
  display: inline-block;
  margin-top: 16px;
  color: var(--ink);
  font-style: normal;
  font-weight: 900;
}

.life-card--pulse {
  animation: lifePulse 880ms ease;
}

.log-cta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  padding: 24px 26px;
  border: 2px solid var(--line);
  background: var(--lavender);
  box-shadow: 6px 6px 0 var(--line);
}

.log-cta h3 {
  font-size: 1.5rem;
  text-transform: uppercase;
}

.menu-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 300px;
  gap: 20px;
}

.menu-head {
  display: flex;
  grid-column: 1 / -1;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.compact-button {
  min-height: 40px;
}

.menu-grid {
  display: grid;
  gap: 14px;
}

.menu-category,
.order-summary {
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--cream);
  padding: 16px;
}

.category-head strong {
  text-transform: uppercase;
}

.category-head {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 14px;
}

.category-head div {
  display: grid;
  gap: 2px;
}

.category-head strong,
.menu-item strong {
  color: var(--ink);
}

.category-head small,
.menu-item small {
  color: var(--muted);
  font-weight: 700;
}

.category-icon,
.item-icon {
  position: relative;
  display: grid;
  flex: 0 0 auto;
  place-items: center;
}

.category-icon {
  width: 42px;
  height: 42px;
  border-radius: 0;
  border: 2px solid var(--line);
  background: var(--cream-2);
}

.menu-items {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

.menu-items.single {
  grid-template-columns: minmax(0, 1fr);
}

.menu-item {
  display: grid;
  min-height: 132px;
  gap: 8px;
  justify-items: center;
  align-content: center;
  border: 2px solid var(--line);
  border-radius: 0;
  background: #fff8ec;
  color: var(--ink);
  padding: 14px 10px;
  text-align: center;
  transition: transform 120ms ease, box-shadow 120ms ease;
}

.menu-item strong {
  text-transform: uppercase;
}

.menu-item:hover {
  transform: translate(-2px, -2px);
  box-shadow: 4px 4px 0 var(--line);
}

.menu-item:active {
  transform: translate(2px, 2px);
  box-shadow: none;
}

.item-icon {
  width: 54px;
  height: 54px;
}

.plate-icon,
.plate-quarter,
.plate-half,
.plate-full {
  border-radius: 50%;
  background:
    radial-gradient(circle at center, #f4c96d 0 38%, transparent 39%),
    #efe3d3;
  box-shadow: inset 0 0 0 3px #d5c5b2;
}

.plate-icon {
  width: 42px;
  height: 42px;
}

.plate-icon i,
.plate-quarter i,
.plate-half i,
.plate-full i {
  position: absolute;
  inset: 11px;
  border-radius: 50%;
  background: #7b3b22;
}

.plate-quarter i {
  clip-path: polygon(50% 50%, 100% 0, 100% 100%);
}

.plate-half i {
  clip-path: polygon(50% 0, 100% 0, 100% 100%, 50% 100%);
}

.mayo-icon::before,
.mayo-cup::before {
  content: "";
  width: 25px;
  height: 28px;
  border-radius: 6px 6px 12px 12px;
  background: linear-gradient(#fffef7 0 58%, #f4d786 59%);
  box-shadow: inset 0 0 0 2px #d9c894;
}

.drink-icon::before,
.can-icon::before {
  content: "";
  width: 24px;
  height: 38px;
  border-radius: 7px;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.36);
}

.drink-icon::before,
.can-blue::before {
  background: #2556a7;
}

.can-red::before {
  background: #bc2e28;
}

.can-neutral::before {
  background: #6e665b;
}

.order-summary {
  position: sticky;
  top: 18px;
  align-self: start;
  display: grid;
  gap: 18px;
}

.order-summary > div:first-child strong {
  display: block;
  font-size: 2.2rem;
  line-height: 1;
}

.order-lines {
  display: grid;
  gap: 10px;
}

.order-lines div {
  display: grid;
  grid-template-columns: 1fr auto 34px;
  align-items: center;
  gap: 10px;
  padding: 10px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: #fff8ec;
}

.order-lines span {
  color: var(--muted);
  font-weight: 800;
}

.order-lines button {
  width: 34px;
  height: 34px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: #fffdf8;
  color: var(--ink);
  font-size: 1.2rem;
  font-weight: 900;
}

.damage-ticket {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 14px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--ink);
  color: var(--green);
}

.damage-ticket span {
  font-weight: 800;
}

.damage-ticket strong {
  font-size: 1.6rem;
}

.history {
  margin-top: 36px;
}

.history-head h3 {
  text-transform: uppercase;
  font-size: 1.4rem;
}

.history-head span {
  color: var(--muted);
  font-weight: 800;
}

ul {
  display: grid;
  gap: 12px;
  padding: 0;
  margin: 18px 0 0;
  list-style: none;
}

li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 16px 18px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--cream);
  box-shadow: 4px 4px 0 var(--line);
}

li div {
  display: grid;
  gap: 3px;
}

li span {
  color: var(--muted);
  font-size: 0.92rem;
}

li b {
  color: var(--accent);
  font-size: 1.25rem;
  font-weight: 900;
}

.empty-state {
  display: grid;
  gap: 4px;
  margin-top: 16px;
  padding: 28px;
  border: 2px dashed var(--line);
  border-radius: 0;
  color: var(--muted);
  background: var(--cream);
}

.empty-state strong {
  color: var(--ink);
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: grid;
  place-items: center;
  padding: 24px;
  background: rgba(5, 5, 5, 0.55);
  overflow-y: auto;
}

.modal-card {
  position: relative;
  width: min(900px, 100%);
  max-height: 90vh;
  margin: auto;
  overflow-y: auto;
  padding: 28px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--cream);
  box-shadow: 12px 12px 0 var(--line);
}

.modal-card .menu-head h3 {
  text-transform: uppercase;
  font-size: 1.5rem;
}

.modal-card .order-summary {
  position: static;
}

.icon-button {
  position: absolute;
  top: 22px;
  right: 22px;
  z-index: 2;
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  flex: 0 0 auto;
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--cream);
  color: var(--ink);
  font-size: 1.5rem;
  font-weight: 900;
  line-height: 1;
  box-shadow: 3px 3px 0 var(--line);
}

.icon-button:active {
  transform: translate(2px, 2px);
  box-shadow: none;
}

.modal-actions {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 12px;
}

.modal-actions .primary-button {
  width: 100%;
}

.simple-modal {
  display: grid;
  gap: 18px;
  width: min(460px, 100%);
}

.step-rows {
  display: grid;
  gap: 12px;
}

.step-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 14px 16px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: var(--cream);
}

.step-info {
  display: grid;
  gap: 4px;
}

.step-info strong {
  text-transform: uppercase;
}

.step-info small {
  color: var(--muted);
  font-weight: 700;
}

.step-info select {
  width: max-content;
  margin-top: 6px;
  padding: 6px 10px;
}

.step-control {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 0 0 auto;
}

.step-control button {
  width: 42px;
  height: 42px;
  border: 2px solid var(--line);
  border-radius: 0;
  background: #fffdf8;
  color: var(--ink);
  font-size: 1.4rem;
  font-weight: 900;
}

.step-control button:active {
  transform: translate(1px, 1px);
}

.step-control b {
  min-width: 46px;
  text-align: center;
  font-size: 1.2rem;
  font-weight: 900;
}

.modal-warn {
  margin: 0;
  color: var(--accent);
  font-weight: 800;
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 180ms ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-card,
.modal-leave-active .modal-card {
  transition: transform 180ms ease;
}

.modal-enter-from .modal-card,
.modal-leave-to .modal-card {
  transform: translateY(12px);
}

.swap-enter-active,
.swap-leave-active,
.list-enter-active,
.list-leave-active {
  transition: opacity 220ms ease, transform 220ms ease;
}

.swap-enter-from,
.swap-leave-to,
.list-enter-from,
.list-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

.list-move {
  transition: transform 220ms ease;
}

@keyframes plateFloat {
  0%,
  100% {
    transform: translateY(0) rotate(-1deg);
  }
  50% {
    transform: translateY(-10px) rotate(2deg);
  }
}

@keyframes steamRise {
  0%,
  100% {
    opacity: 0.2;
    transform: translateY(16px) scaleY(0.75);
  }
  45% {
    opacity: 0.9;
    transform: translateY(-8px) scaleY(1);
  }
}

@keyframes lifePulse {
  0% {
    box-shadow: 0 0 0 rgba(179, 63, 47, 0);
  }
  45% {
    box-shadow: 0 0 0 8px rgba(179, 63, 47, 0.12);
    transform: translateY(-2px);
  }
  100% {
    box-shadow: 0 0 0 rgba(179, 63, 47, 0);
  }
}

@keyframes solarFloat {
  0%,
  100% {
    transform: translateY(0) rotate(-2deg);
  }
  50% {
    transform: translateY(-10px) rotate(2deg);
  }
}

@keyframes orbitPath {
  from {
    offset-distance: 0%;
  }
  to {
    offset-distance: 100%;
  }
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 820px) {
  .shell {
    width: 100%;
    padding: 0;
  }

  .landing-nav {
    grid-template-columns: 1fr;
    gap: 16px;
    padding: 22px;
  }

  .dash-nav {
    padding: 16px 22px;
  }

  .brand-name {
    font-size: 1.2rem;
  }

  .brand-mark img {
    height: 40px;
  }

  .profile-name {
    display: none;
  }

  .profile-pill {
    padding: 5px;
  }

  .nav-cta {
    min-height: 40px;
    padding: 0 18px;
    font-size: 0.9rem;
  }

  .nav-links {
    display: none;
  }

  .landing-grid {
    grid-template-columns: 1fr;
    grid-template-rows: auto;
    min-height: 0;
  }

  .landing-main,
  .landing-side {
    border-right: 0;
  }

  .landing-main {
    min-height: auto;
    padding: 42px 22px 64px;
  }

  .title-row {
    flex-direction: column;
  }

  .landing-side {
    grid-template-columns: 1fr;
    gap: 28px;
    padding: 38px 22px;
  }

  .orbit-labels {
    gap: 18px;
  }

  .solar-system {
    min-height: 320px;
  }

  .solar-core {
    width: 210px;
  }

  .ring-one {
    width: 190px;
    height: 116px;
  }

  .ring-two {
    width: 270px;
    height: 180px;
  }

  .ring-three {
    width: 330px;
    height: 230px;
  }

  .ring-four {
    width: 410px;
    height: 280px;
  }

  .orbit-mayo {
    width: 70px;
    offset-path: ellipse(135px 90px at 50% 50%);
  }

  .orbit-cola {
    width: 70px;
    offset-path: ellipse(165px 115px at 50% 50%);
  }

  .orbit-person {
    width: 46px;
    height: 46px;
  }

  .orbit-person-1 {
    offset-path: ellipse(95px 58px at 50% 50%);
  }

  .orbit-person-2 {
    offset-path: ellipse(135px 90px at 50% 50%);
  }

  .orbit-person-3 {
    offset-path: ellipse(165px 115px at 50% 50%);
  }

  .rank-tag {
    min-width: 22px;
    height: 22px;
    font-size: 0.7rem;
  }

  .leaderboard-section {
    grid-template-columns: 1fr;
    padding: 46px 18px 58px;
  }

  .podium-stage {
    gap: 6px;
    min-height: 390px;
    padding: 26px 12px 0;
  }

  .avatar-head {
    width: 58px;
    height: 58px;
  }

  .avatar-head.champion {
    width: 70px;
    height: 70px;
  }

  .stick-body {
    width: 82px;
    height: 96px;
  }

  .stick-body::before {
    left: 38px;
    height: 60px;
  }

  .stick-body::after {
    left: 14px;
    width: 58px;
  }

  .stick-body span::before,
  .stick-body span::after {
    left: 38px;
    top: 58px;
    height: 44px;
  }

  .podium-block strong {
    font-size: 3.4rem;
  }

  .ticker {
    font-size: 1rem;
  }

  .site-footer {
    min-height: 230px;
  }

  .footer-links {
    top: 34px;
    gap: 8px 16px;
  }

  .hero-panel,
  .onboarding,
  .stats-grid,
  .menu-card,
  .menu-items {
    grid-template-columns: 1fr;
  }

  .log-cta {
    flex-direction: column;
    align-items: flex-start;
  }

  .area-hero {
    grid-template-columns: minmax(0, 1fr);
    min-height: 0;
    padding: 18px;
    gap: 18px;
  }

  .area-panel {
    padding: 30px 22px;
  }

  .area-title {
    font-size: clamp(2rem, 9vw, 2.8rem);
    overflow-wrap: anywhere;
  }

  .area-mark {
    overflow-wrap: anywhere;
  }

  .area-image {
    min-height: 360px;
  }

  .area-stat {
    flex-direction: column;
    align-items: flex-start;
    gap: 14px;
  }

  .modal-card {
    padding: 20px;
  }

  .menu-head {
    flex-direction: column;
  }

  .order-summary {
    position: static;
  }

  .hero-panel,
  .workspace {
    padding: 22px;
  }

  .plate-orbit {
    max-width: 240px;
    justify-self: center;
  }

  .top-row {
    align-items: stretch;
    flex-direction: column;
    gap: 22px;
  }

  .profile-head {
    align-items: flex-start;
  }

  .activity {
    justify-items: start;
  }

  .activity-grid {
    max-width: 100%;
  }

  .ghost-button,
  .primary-button {
    width: 100%;
  }
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 1ms !important;
    scroll-behavior: auto !important;
    transition-duration: 1ms !important;
  }
}
</style>
