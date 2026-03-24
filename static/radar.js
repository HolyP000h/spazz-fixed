// 1. Initialize Global Variables
let firstLoad = true;
let lastDistance = 999999;
let lockedTargetId = null;
let markers = {};

var map = L.map('map', { zoomControl: false }).setView([39.3331, -82.9824], 14);

// 2. Add Dark Matter tiles
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: 'SPAZZ Stealth Radar | &copy; CARTO',
    subdomains: 'abcd',
    maxZoom: 20
}).addTo(map);

// 3. The Main Engine
async function updateRadar() {
    try {
        console.log("📡 Fetching signals...");
        const response = await fetch('/api/users');
        const data = await response.json();
        
        const currentIds = new Set(data.map(u => u.id));
        const allCoords = [];
        const mapEl = document.getElementById('map');

        data.forEach(user => {
            const color = user.wisp_class === 'whisp-red' ? '#ff0000' : 
                          (user.type === 'user' ? '#8a2be2' : '#00ffff');

            // --- MARKER MANAGEMENT ---
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

                // Set target when clicked
                markers[user.id].on('click', () => { 
                    lockedTargetId = user.id; 
                    console.log("🔒 LOCKED ONTO:", user.username);
                });
            }
            allCoords.push([user.lat, user.lon]);

            // --- 🎯 THE SPAZZ SENSOR (Haversine Logic) ---
            if (lockedTargetId === user.id) {
                const center = map.getCenter();
                const distance = getHaversineDistance(center.lat, center.lng, user.lat, user.lon);

                let jitter = 0;
                let blur = 0;

                if (distance < 30) { // FACE TO FACE
                    jitter = 15; blur = 5;
                    document.getElementById('status').innerText = "⚠️ CRITICAL PROXIMITY: SPAZZING OUT";
                } else if (distance < 150) { // NEARBY
                    jitter = 4; blur = 1;
                    document.getElementById('status').innerText = "📡 SIGNAL GAIN: CLOSING IN";
                } else { // LONG RANGE
                    document.getElementById('status').innerText = `🎯 TRACKING: ${Math.round(distance)}m`;
                }

                // 👣 Wrong Way Detection
                if (distance > lastDistance) {
                    mapEl.style.opacity = "0.4"; // Fade if getting colder
                    mapEl.style.transition = "opacity 2s ease";
                } else {
                    mapEl.style.opacity = "1.0";
                    mapEl.style.transition = "opacity 0.3s ease";
                }
                lastDistance = distance;

                // ⚡ Apply Visual Glitch
                mapEl.style.filter = `blur(${blur}px) contrast(${100 + jitter * 10}%)`;
                mapEl.style.transform = `translate(${Math.random() * jitter}px, ${Math.random() * jitter}px)`;
            }
        });

        // --- CLEANUP & UI ---
        Object.keys(markers).forEach(id => {
            if (!currentIds.has(id)) {
                map.removeLayer(markers[id]);
                delete markers[id];
            }
        });

        if (firstLoad && allCoords.length > 0) {
            map.fitBounds(L.latLngBounds(allCoords), { padding: [100, 100] });
            firstLoad = false;
            const boot = document.getElementById('boot-screen');
            if (boot) { boot.style.opacity = '0'; setTimeout(() => boot.remove(), 1000); }
        }

    } catch (err) {
        console.error("⚠️ Radar Sync Error:", err);
    }
}

// 4. Distance Formula
function getHaversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3; 
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

// 5. Initialize
updateRadar();
setInterval(updateRadar, 3000);

// 📍 This connects YOUR real steps to the Radar
let currentLat, currentLon; // Global variables for the Haversine formula

function startTracking() {
    navigator.geolocation.watchPosition(
        (position) => {
            currentLat = position.coords.latitude;
            currentLon = position.coords.longitude;

            // 🏎️ PAN instead of SET for smooth movement
            map.panTo([currentLat, currentLon], {
                animate: true,
                duration: 1.5 // Creates a 1.5 second "glide"
            });
            
            // 🔍 Zoom in deep to make street-walking feel accurate
            if (map.getZoom() < 18) map.setZoom(18); 
        },
        (err) => console.error(err),
        { enableHighAccuracy: true, maximumAge: 0, timeout: 5000 }
    );
}

startTracking(); // Kick off the GPS