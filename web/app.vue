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
  --cream: #f4f1e9;
  --cream-2: #fbf6ec;
  --ink: #14241a;
  --muted: #5c6b5a;
  --line: #14241a;
  --accent: #ff6a2b;
  --accent-dark: #14241a;
  --green: #c8ef4d;
  --green-soft: #e3efc7;
  --lavender: #e3efc7;
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

.muted {
  color: var(--muted);
  font-size: 1.05rem;
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
  min-height: 88px;
  padding: 0 56px;
  border-bottom: 2px solid var(--line);
  background: var(--cream);
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

/* Profile menu */
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

.profile-link small {
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 800;
}

.profile-backdrop {
  position: fixed;
  inset: 0;
  z-index: 10;
  border: 0;
  background: transparent;
}

/* Workspace / dashboard */
.workspace {
  padding: 48px 56px 64px;
  background: var(--cream);
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

.section-kicker,
.stat-label {
  margin: 0 0 10px;
  color: var(--accent-dark);
  font-size: 0.78rem;
  font-weight: 800;
  text-transform: uppercase;
}

.error-banner {
  margin-top: 18px;
  padding: 14px 16px;
  border: 2px solid var(--line);
  background: var(--accent);
  box-shadow: 4px 4px 0 var(--line);
  color: #fffaf2;
  font-weight: 800;
}

/* Stats */
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

/* Location card */
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

/* Section CTA blocks */
.log-cta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  padding: 24px 26px;
  margin-top: 24px;
  border: 2px solid var(--line);
  background: var(--lavender);
  box-shadow: 6px 6px 0 var(--line);
}

.log-cta h3 {
  font-size: 1.5rem;
  text-transform: uppercase;
}

/* Forms */
.form-grid {
  display: grid;
  gap: 18px;
  margin-top: 18px;
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
  background: #fffdf8;
  color: var(--ink);
  padding: 14px 15px;
  outline: none;
  transition: box-shadow 160ms ease;
}

input:focus,
select:focus {
  box-shadow: 4px 4px 0 var(--accent);
}

label small {
  color: var(--muted);
  font-weight: 600;
}

.primary-button,
.ghost-button {
  min-height: 48px;
  border: 2px solid var(--line);
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

.ghost-button {
  background: var(--cream);
  color: var(--ink);
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

.primary-button:disabled,
.ghost-button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  transform: none;
  box-shadow: 4px 4px 0 var(--line);
}

.compact-button {
  min-height: 40px;
}

.modal-actions {
  display: grid;
  grid-template-columns: auto auto auto;
  gap: 12px;
}

/* History list */
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
  color: var(--muted);
  background: var(--cream);
}

.empty-state strong {
  color: var(--ink);
}

/* Loading */
.loading-state {
  display: grid;
  gap: 14px;
  align-content: center;
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

/* Legal pages */
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

/* Footer */
.site-footer {
  position: relative;
  display: grid;
  place-items: center;
  align-content: center;
  min-height: 360px;
  overflow: hidden;
  background: linear-gradient(180deg, #f2e7da 0%, #f6efe1 50%, #ece0cb 100%);
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

  .workspace {
    padding: 22px;
  }

  .stats-grid,
  .location-card,
  .modal-actions {
    grid-template-columns: 1fr;
  }

  .log-cta {
    flex-direction: column;
    align-items: flex-start;
  }

  .top-row {
    flex-direction: column;
    align-items: stretch;
    gap: 22px;
  }

  .profile-head {
    align-items: flex-start;
  }

  .ghost-button,
  .primary-button {
    width: 100%;
  }

  .site-footer {
    min-height: 230px;
  }

  .footer-links {
    top: 34px;
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
