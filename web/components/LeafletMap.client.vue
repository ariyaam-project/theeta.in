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

// Grey out everything outside the Kerala border using an inverse polygon
// (world outer ring + Kerala hole). Loaded once from the embedded GeoJSON.
async function addKeralaMask(L: any) {
  try {
    const res = await fetch('/kerala.geojson')
    const geo = await res.json()
    const ring: [number, number][] = geo.geometry.coordinates[0].map(
      ([lng, lat]: [number, number]) => [lat, lng]
    )
    const world: [number, number][] = [
      [-85, -180],
      [-85, 180],
      [85, 180],
      [85, -180]
    ]
    L.polygon([world, ring], {
      pane: 'keralaMask',
      stroke: false,
      fillColor: '#eef0e6',
      fillOpacity: 1,
      interactive: false
    }).addTo(map)
    L.polyline([...ring, ring[0]], {
      pane: 'keralaMask',
      color: '#14241a',
      weight: 2,
      interactive: false
    }).addTo(map)
  } catch {
    // GeoJSON missing → skip mask, map still works
  }
}

function render(L: any) {
  if (!host.value) return
  if (!map) {
    // Lock the map to Kerala — no panning away, no zooming out past it.
    const keralaBounds: [[number, number], [number, number]] = [
      [8.0, 74.7],
      [12.95, 77.6]
    ]
    map = L.map(host.value, {
      maxBounds: keralaBounds,
      maxBoundsViscosity: 1.0,
      minZoom: 6
    }).setView([10.5, 76.2], props.spots.length ? 9 : 7)
    // Stylised, illustrative basemap (CARTO Voyager) — no API key needed.
    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      attribution: '© OpenStreetMap, © CARTO',
      maxZoom: 20
    }).addTo(map)
    // Dedicated pane for the Kerala mask: above tiles (200), below markers (400).
    map.createPane('keralaMask')
    map.getPane('keralaMask').style.zIndex = '350'
    addKeralaMask(L)
    // Labels overlay ABOVE the mask so place names are never greyed out.
    map.createPane('labels')
    const labelPane = map.getPane('labels')
    labelPane.style.zIndex = '360'
    labelPane.style.pointerEvents = 'none'
    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      maxZoom: 20,
      pane: 'labels'
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
