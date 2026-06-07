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
  /* Periwinkle theme — mirrors web/pages/index.vue */
  --bg: #f6f5fb;
  --card: #ffffff;
  --ink: #2c2b3a;
  --muted: #6b6a7c;
  --p: #8b80d6;
  --p2: #a99ff0;
  --p-soft: #ece9fb;
  --peach: #f3a18b;
  --line: rgba(44, 43, 58, 0.08);
  --shadow: 0 20px 44px -26px rgba(44, 43, 58, 0.42);
  --shadow-sm: 0 12px 26px -18px rgba(44, 43, 58, 0.4);
  /* legacy aliases so any stray references resolve to the new palette */
  --cream: #f6f5fb;
  --cream-2: #ffffff;
  --accent: #8b80d6;
  --accent-dark: #8b80d6;
  --green: #ece9fb;
  --green-soft: #ece9fb;
  --lavender: #ece9fb;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-width: 320px;
  background: var(--bg);
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

h1,
h2,
h3,
p {
  margin-top: 0;
}

h1 {
  margin-bottom: 14px;
  font-size: clamp(2.2rem, 5vw, 3rem);
  line-height: 1.05;
}

h2 {
  margin-bottom: 10px;
  font-size: clamp(1.6rem, 3.5vw, 2.2rem);
  line-height: 1.1;
}

h3 {
  margin-bottom: 0;
  font-size: 1.1rem;
}

.muted {
  color: var(--muted);
  font-size: 1.02rem;
  line-height: 1.6;
}

/* Layout shell */
.shell {
  display: flex;
  flex-direction: column;
  width: 100%;
  min-height: 100vh;
}

.shell > .site-footer {
  margin-top: auto;
}

/* Top navigation */
.dash-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  min-height: 84px;
  padding: 16px 40px;
  background: rgba(246, 245, 251, 0.85);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid var(--line);
  position: sticky;
  top: 0;
  z-index: 30;
}

.brand-mark {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
}

.brand-mark img {
  height: 40px;
  width: auto;
  display: block;
}

.brand-name {
  color: var(--ink);
  font-size: 1.4rem;
  font-weight: 800;
  letter-spacing: -0.02em;
}

.nav-cta {
  min-height: 44px;
  padding: 0 24px;
  border: 0;
  border-radius: 999px;
  background: var(--p);
  color: #fff;
  font-weight: 700;
  white-space: nowrap;
  box-shadow: 0 12px 24px -12px var(--p);
  transition: transform 140ms ease;
}

.nav-cta:hover {
  transform: translateY(-2px);
}

/* App nav tabs */
.app-nav {
  gap: 24px;
}

.nav-tabs {
  display: flex;
  flex: 1;
  gap: 6px;
  justify-content: center;
  flex-wrap: wrap;
}

.nav-tab {
  padding: 9px 18px;
  border-radius: 999px;
  color: var(--muted);
  font-weight: 700;
  font-size: 0.92rem;
  text-decoration: none;
  transition: background 140ms ease, color 140ms ease;
}

.nav-tab:hover {
  background: var(--p-soft);
  color: var(--ink);
}

.nav-tab.router-link-active {
  background: var(--p);
  color: #fff;
}

/* Profile menu */
.profile-menu {
  position: relative;
}

.profile-pill {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 5px 16px 5px 5px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: var(--card);
  box-shadow: var(--shadow-sm);
}

.profile-pic {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  overflow: hidden;
  border-radius: 50%;
  background: var(--p-soft);
  color: var(--p);
  font-weight: 800;
}

.profile-pic img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.profile-name {
  font-size: 1rem;
  font-weight: 700;
}

.profile-dropdown {
  position: absolute;
  right: 0;
  top: calc(100% + 10px);
  z-index: 20;
  display: grid;
  min-width: 180px;
  overflow: hidden;
  border-radius: 16px;
  border: 1px solid var(--line);
  background: var(--card);
  box-shadow: var(--shadow);
}

.profile-dropdown .profile-link {
  padding: 13px 18px;
  border: 0;
  border-bottom: 1px solid var(--line);
  background: var(--card);
  color: var(--ink);
  font-weight: 700;
  text-align: left;
  text-decoration: none;
}

.profile-dropdown .profile-link:last-child {
  border-bottom: 0;
}

.profile-dropdown .profile-link:hover {
  background: var(--p-soft);
}

.profile-backdrop {
  position: fixed;
  inset: 0;
  z-index: 10;
  border: 0;
  background: transparent;
}

/* Workspace */
.workspace {
  width: 100%;
  max-width: 1160px;
  margin: 0 auto;
  padding: 36px 40px 60px;
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

.profile-head img {
  width: 60px;
  height: 60px;
  flex: 0 0 auto;
  border-radius: 50%;
  border: 1px solid var(--line);
  box-shadow: var(--shadow-sm);
}

.profile-head h2 {
  margin-bottom: 2px;
}

.section-kicker,
.stat-label {
  margin: 0 0 8px;
  color: var(--p);
  font-size: 0.76rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.error-banner {
  margin-top: 18px;
  padding: 14px 18px;
  border-radius: 16px;
  background: #fdeae2;
  border: 1px solid rgba(243, 161, 139, 0.5);
  color: #9a3b22;
  font-weight: 700;
}

/* Generic card surface */
.stats-grid,
.metric-grid {
  display: grid;
  gap: 16px;
  margin: 24px 0;
}

.stats-grid {
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
}

.metric-grid {
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
}

.stats-grid article,
.metric-grid article {
  min-height: 120px;
  padding: 20px;
  border-radius: 20px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}

.stats-grid strong,
.metric-grid strong {
  display: block;
  margin-top: 8px;
  font-size: clamp(1.7rem, 3.5vw, 2.6rem);
  line-height: 1;
  font-weight: 800;
}

.life-card {
  background: linear-gradient(135deg, var(--p-soft), #fdeae2) !important;
}

.life-card em {
  display: inline-block;
  margin-top: 14px;
  color: var(--ink);
  font-style: normal;
  font-weight: 800;
}

/* Location card */
.location-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(300px, 0.9fr);
  gap: 22px;
  align-items: start;
  padding: 24px;
  border-radius: 22px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}

.location-card[data-empty="true"] {
  grid-template-columns: minmax(0, 1fr);
}

.location-card h3 {
  margin: 0 0 8px;
  font-size: clamp(1.4rem, 3vw, 2rem);
  letter-spacing: -0.02em;
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
  border-radius: 14px;
  background: var(--p-soft);
}

.location-grid dt {
  color: var(--muted);
  font-size: 0.72rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.location-grid dd {
  margin: 6px 0 0;
  color: var(--ink);
  font-weight: 800;
  overflow-wrap: anywhere;
}

/* Section CTA blocks */
.log-cta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  padding: 22px 24px;
  margin-top: 22px;
  border-radius: 20px;
  background: var(--p-soft);
}

.log-cta h3 {
  font-size: 1.3rem;
}

/* Forms */
.form-grid {
  display: grid;
  gap: 16px;
  margin-top: 16px;
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
  border: 1.5px solid var(--line);
  border-radius: 14px;
  background: var(--card);
  color: var(--ink);
  padding: 13px 15px;
  outline: none;
  transition: border-color 160ms ease, box-shadow 160ms ease;
}

input:focus,
select:focus {
  border-color: var(--p2);
  box-shadow: 0 0 0 4px var(--p-soft);
}

label small {
  color: var(--muted);
  font-weight: 600;
}

.primary-button,
.ghost-button {
  min-height: 48px;
  border-radius: 999px;
  padding: 0 26px;
  font-weight: 700;
  letter-spacing: 0.01em;
  transition: transform 130ms ease, box-shadow 130ms ease;
}

.primary-button {
  border: 0;
  background: var(--p);
  color: #fff;
  box-shadow: 0 14px 26px -12px var(--p);
}

.ghost-button {
  border: 1.5px solid var(--line);
  background: var(--card);
  color: var(--ink);
}

.primary-button:hover,
.ghost-button:hover {
  transform: translateY(-2px);
}

.primary-button:disabled,
.ghost-button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.compact-button {
  min-height: 40px;
  padding: 0 18px;
}

.link-button {
  margin-top: 14px;
  border: 0;
  background: none;
  color: var(--p);
  font-weight: 800;
  text-decoration: underline;
}

.modal-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

/* Auth page */
.auth-wrap {
  display: grid;
  place-items: center;
  min-height: 70vh;
}

.auth-card {
  width: 100%;
  max-width: 440px;
  padding: 32px;
  border-radius: 24px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}

.auth-divider {
  display: grid;
  place-items: center;
  margin: 20px 0;
  border-top: 1px solid var(--line);
}

.auth-divider span {
  transform: translateY(-50%);
  padding: 0 12px;
  background: var(--card);
  color: var(--muted);
  font-weight: 700;
  text-transform: uppercase;
  font-size: 0.76rem;
}

.auth-alt {
  display: grid;
  gap: 12px;
}

.auth-alt .ghost-button {
  width: 100%;
}

.dev-login summary {
  cursor: pointer;
  color: var(--muted);
  font-weight: 700;
  font-size: 0.85rem;
}

.dev-login-body {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 10px;
  margin-top: 10px;
}

/* History list */
.history {
  margin-top: 32px;
}

.history-head h3 {
  font-size: 1.3rem;
}

.history-head span {
  color: var(--muted);
  font-weight: 700;
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
  border-radius: 16px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow-sm);
}

li > .profile-link {
  display: grid;
  gap: 4px;
  border: 0;
  background: none;
  text-align: left;
  cursor: pointer;
}

li .profile-link strong {
  font-weight: 800;
}

li span {
  color: var(--muted);
  font-size: 0.92rem;
}

li .profile-link small {
  color: var(--p);
  font-weight: 700;
  font-size: 0.82rem;
}

li b {
  color: var(--muted);
  font-size: 0.95rem;
  font-weight: 700;
  white-space: nowrap;
}

.empty-state {
  display: grid;
  gap: 4px;
  margin-top: 16px;
  padding: 28px;
  border-radius: 18px;
  border: 1.5px dashed var(--line);
  color: var(--muted);
  background: var(--card);
}

.empty-state strong {
  color: var(--ink);
}

/* Filter chips */
.filter-chips {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.chip {
  padding: 8px 16px;
  border: 1.5px solid var(--line);
  border-radius: 999px;
  background: var(--card);
  font-weight: 700;
  font-size: 0.8rem;
}

.chip[data-active='true'] {
  background: var(--p);
  border-color: var(--p);
  color: #fff;
}

/* Analytics panels */
.panel-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 18px;
}

.panel {
  padding: 24px;
  border-radius: 20px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}

.bar-row {
  margin-bottom: 12px;
}

.bar-head,
.row-line {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: 700;
}

.row-line {
  padding: 8px 0;
  border-bottom: 1px solid var(--line);
}

.bar-track {
  margin-top: 5px;
  height: 10px;
  border-radius: 999px;
  background: var(--p-soft);
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  border-radius: 999px;
  background: linear-gradient(90deg, var(--p), var(--p2));
}

/* Profile page */
.profile-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 24px;
  border-radius: 22px;
  background: linear-gradient(135deg, #2c2b3a 0%, #4a4373 100%);
  color: #fff;
  box-shadow: var(--shadow);
}

.profile-card h3 {
  color: #fff;
  font-size: 1.4rem;
}

.profile-card .muted {
  color: rgba(255, 255, 255, 0.78);
}

.profile-avatar {
  display: grid;
  place-items: center;
  width: 62px;
  height: 62px;
  flex: 0 0 auto;
  overflow: hidden;
  border-radius: 50%;
  background: var(--p2);
  color: #fff;
  font-size: 1.6rem;
  font-weight: 800;
}

.profile-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.danger-button {
  margin-top: 22px;
  color: var(--peach);
  border-color: rgba(243, 161, 139, 0.6);
}

/* Map */
.map-shell {
  margin-top: 22px;
  border-radius: 22px;
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
  overflow: hidden;
}

.leaflet-host,
.map-fallback {
  width: 100%;
  height: 60vh;
  min-height: 360px;
}

.map-fallback {
  display: grid;
  place-items: center;
  background: var(--card);
}

/* Loading */
.loading-state {
  display: grid;
  gap: 14px;
  align-content: center;
  justify-items: center;
  min-height: 200px;
}

.spinner {
  width: 44px;
  height: 44px;
  border: 4px solid var(--p-soft);
  border-top-color: var(--p);
  border-radius: 50%;
  animation: spin 760ms linear infinite;
}

/* Legal pages */
.legal {
  max-width: 720px;
  margin: 0 auto;
  padding: 56px 24px 80px;
}

.legal h1 {
  margin-bottom: 24px;
}

.legal p {
  margin-bottom: 16px;
  color: var(--muted);
  font-size: 1.05rem;
  line-height: 1.6;
}

.legal-note {
  padding: 18px 20px;
  border-radius: 16px;
  background: var(--p-soft);
  color: var(--ink) !important;
  font-weight: 700;
}

.legal-contact {
  margin-top: 28px;
  color: var(--ink) !important;
  font-weight: 800;
}

.legal a {
  color: var(--p);
  font-weight: 700;
}

/* Footer */
.site-footer {
  position: relative;
  display: grid;
  place-items: center;
  align-content: center;
  min-height: 360px;
  overflow: hidden;
  background: linear-gradient(180deg, #ffffff 0%, #f6f5fb 45%, #ece9fb 100%);
}

.footer-links {
  position: absolute;
  left: 0;
  right: 0;
  top: 48px;
  z-index: 3;
  display: flex;
  flex-wrap: wrap;
  gap: 6px 22px;
  align-items: center;
  justify-content: center;
  padding: 0 22px;
  opacity: 0.7;
}

.footer-links a {
  color: #2c2b3a;
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
  background: linear-gradient(180deg, rgba(139, 128, 214, 0.95), rgba(169, 159, 240, 0.32));
  -webkit-background-clip: text;
  background-clip: text;
  font-family: "Bungee Shade", Inter, ui-sans-serif, system-ui, sans-serif;
  font-size: clamp(5.5rem, 19vw, 17rem);
  font-weight: 400;
  line-height: 0.74;
  white-space: nowrap;
}

/* Transitions */
.pop-enter-active,
.pop-leave-active {
  transition: opacity 140ms ease, transform 140ms ease;
}

.pop-enter-from,
.pop-leave-to {
  opacity: 0;
  transform: translateY(-6px);
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

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 820px) {
  .dash-nav {
    flex-wrap: wrap;
    padding: 14px 20px;
  }

  .nav-tabs {
    order: 3;
    width: 100%;
    margin-top: 4px;
  }

  .brand-name {
    font-size: 1.2rem;
  }

  .profile-name {
    display: none;
  }

  .workspace {
    padding: 22px;
  }

  .location-card,
  .top-row {
    grid-template-columns: 1fr;
    flex-direction: column;
    align-items: stretch;
  }

  .log-cta {
    flex-direction: column;
    align-items: flex-start;
  }

  .ghost-button,
  .primary-button {
    width: 100%;
  }

  .site-footer {
    min-height: 220px;
  }

  .footer-links {
    top: 30px;
    gap: 8px 16px;
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
