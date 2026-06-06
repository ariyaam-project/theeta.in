<script setup lang="ts">
// Client-only Leaflet map. Leaflet needs `window`, so this lives in a
// `.client.vue` component and loads the library from the CDN on mount —
// no npm dependency, no SSR pitfalls on Cloudflare.
export type MapSpot = {
  name: string
  city: string | null
  lat: number
  lng: number
  url: string
}

const props = defineProps<{ spots: MapSpot[] }>()

const host = ref<HTMLElement | null>(null)
let map: any = null
let layer: any = null

async function ensureLeaflet(): Promise<any> {
  const w = window as any
  if (w.L) return w.L
  if (!document.getElementById('leaflet-css')) {
    const link = document.createElement('link')
    link.id = 'leaflet-css'
    link.rel = 'stylesheet'
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
    document.head.appendChild(link)
  }
  await new Promise<void>((resolve, reject) => {
    const script = document.createElement('script')
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
    script.onload = () => resolve()
    script.onerror = () => reject(new Error('Failed to load Leaflet'))
    document.head.appendChild(script)
  })
  return (window as any).L
}

function render(L: any) {
  if (!host.value) return
  if (!map) {
    map = L.map(host.value).setView([20.5937, 78.9629], props.spots.length ? 11 : 4)
    // Stylised, illustrative basemap (CARTO Voyager) — no API key needed.
    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      attribution: '© OpenStreetMap, © CARTO',
      maxZoom: 20
    }).addTo(map)
  }
  if (layer) layer.remove()
  layer = L.layerGroup().addTo(map)

  const points: [number, number][] = []
  for (const spot of props.spots) {
    const marker = L.circleMarker([spot.lat, spot.lng], {
      radius: 9,
      color: '#14241a',
      weight: 2,
      fillColor: '#ff6a2b',
      fillOpacity: 1
    }).addTo(layer)
    const safeName = spot.name.replace(/</g, '&lt;')
    const cityLine = spot.city ? `<br>${spot.city.replace(/</g, '&lt;')}` : ''
    const gmaps = `https://www.google.com/maps/search/?api=1&query=${spot.lat},${spot.lng}`
    marker.bindPopup(
      `<strong>${safeName}</strong>${cityLine}<br>` +
        `<a href="${spot.url}" target="_blank" rel="noopener">Open reel</a> · ` +
        `<a href="${gmaps}" target="_blank" rel="noopener">Google Maps</a>`
    )
    points.push([spot.lat, spot.lng])
  }
  if (points.length) {
    map.fitBounds(points, { padding: [40, 40], maxZoom: 13 })
  }
}

onMounted(async () => {
  try {
    const L = await ensureLeaflet()
    render(L)
  } catch {
    // leave the empty host; the page shows its own hint
  }
})

watch(
  () => props.spots,
  () => {
    const L = (window as any).L
    if (L) render(L)
  },
  { deep: true }
)

onBeforeUnmount(() => {
  if (map) {
    map.remove()
    map = null
    layer = null
  }
})
</script>

<template>
  <div ref="host" class="leaflet-host" />
</template>

<style>
/* Push the basemap away from realistic toward a punchy, illustrative look. */
.leaflet-host .leaflet-tile-pane {
  filter: saturate(1.25) contrast(1.05) brightness(1.02);
}
</style>
