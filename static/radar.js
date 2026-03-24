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

        // 1. Process each signal
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

        // 2. Cleanup old markers
        Object.keys(markers).forEach(id => {
            if (!currentIds.has(id)) {
                map.removeLayer(markers[id]);
                delete markers[id];
            }
        });

        // 3. Update UI Status
        const statusEl = document.getElementById('status');
        if (statusEl) statusEl.innerText = `SIGNALS: ${data.length} LOCKED`;

        // 4. THE LOCK & THE FADE
        if (firstLoad && allCoords.length > 0) {
            map.fitBounds(L.latLngBounds(allCoords), { padding: [100, 100] });
            firstLoad = false; // Lock the camera
            
            const boot = document.getElementById('boot-screen');
            if (boot) {
                boot.style.opacity = '0';
                setTimeout(() => boot.remove(), 1000);
            }
            console.log("🎯 Initial Lock-On: Manual Control Engaged.");
        }

    } catch (err) {
        console.error("⚠️ Radar Sync Error:", err);
    }
}

// 5. Kickstart the engine
updateRadar();
setInterval(updateRadar, 3000);