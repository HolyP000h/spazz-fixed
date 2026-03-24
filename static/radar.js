// 1. Initialize the map
let firstLoad = true;
var map = L.map('map', { zoomControl: false }).setView([39.3331, -82.9824], 14);

// 2. Add Dark Matter tiles
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: 'SPAZZ Stealth Radar | &copy; CARTO',
    subdomains: 'abcd',
    maxZoom: 20
}).addTo(map);

let markers = {}; 

async function updateRadar() {
    try {
        console.log("📡 Fetching signals...");
        const response = await fetch('/api/users');
        const data = await response.json();
        
        const currentIds = new Set(data.map(u => u.id));
        const allCoords = [];

        // 1. Update or Create Markers
        data.forEach(user => {
            const color = user.wisp_class === 'whisp-red' ? '#ff0000' : 
                          (user.type === 'user' ? '#8a2be2' : '#00ffff');

            if (markers[user.id]) {
                markers[user.id].setLatLng([user.lat, user.lon]);
            } else {
                markers[user.id] = L.circleMarker([user.lat, user.lon], {
                    radius: user.type === 'user' ? 10 : 7,
                    fillColor: color,
                    color: '#fff',
                    weight: 2,
                    fillOpacity: 0.8,
                    className: user.wisp_class || '' 
                }).addTo(map).bindPopup(`<b>${user.username}</b>`);
            }
            allCoords.push([user.lat, user.lon]);
        });

        // 2. Cleanup Disconnected Signals
        Object.keys(markers).forEach(id => {
            if (!currentIds.has(id)) {
                map.removeLayer(markers[id]);
                delete markers[id];
            }
        });

        // 3. UI and Auto-Zoom
        const statusEl = document.getElementById('status');
        if (statusEl) statusEl.innerText = `SIGNALS: ${data.length} LOCKED`;

        if (typeof window.firstLoad === 'undefined') window.firstLoad = true; 
        if (window.firstLoad && allCoords.length > 0) {
            map.fitBounds(L.latLngBounds(allCoords), { padding: [100, 100] });
            window.firstLoad = false; 
        }

    } catch (err) {
        console.error("⚠️ Radar Sync Error:", err);
    }
}