// 1. Initialize the map
var map = L.map('map', { zoomControl: false }).setView([39.3331, -82.9824], 14);

// 2. Add Dark Matter tiles
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: 'SPAZZ Stealth Radar | &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
    subdomains: 'abcd',
    maxZoom: 20
}).addTo(map);

let markers = {}; // Object to track markers by ID for smooth movement

async function updateRadar() {
    try {
        console.log("Fetching signals...");
        const response = await fetch('/api/users');
        const data = await response.json();
        
        const currentIds = new Set(data.map(u => u.id));
        const allCoords = [];

        data.forEach(user => {
            const color = user.wisp_class === 'whisp-red' ? '#ff0000' : 
                          (user.type === 'wisp' ? '#00ffff' : '#8a2be2');
const allCoords = data.map(u => [u.lat, u.lon]);
if (allCoords.length > 0) {
    const bounds = L.latLngBounds(allCoords);
    map.fitBounds(bounds, { padding: [50, 50], animate: true });
}                 

            // If marker exists, update position
            if (markers[user.id]) {
                markers[user.id].setLatLng([user.lat, user.lon]);
            } else {
                // If marker is new, create it as a CircleMarker
                markers[user.id] = L.circleMarker([user.lat, user.lon], {
                    radius: user.type === 'user' ? 10 : 7,
                    fillColor: color,
                    color: '#fff',
                    weight: 2,
                    opacity: 1,
                    fillOpacity: 0.8,
                    className: user.wisp_class || '' // Injects 'whisp-red' for the flicker
                }).addTo(map).bindPopup(`<b>${user.username}</b><br>${user.type}`);
            }
            allCoords.push([user.lat, user.lon]);
        });

        // Remove markers for users who disappeared from the JSON
        Object.keys(markers).forEach(id => {
            if (!currentIds.has(id)) {
                map.removeLayer(markers[id]);
                delete markers[id];
            }
        });

        // Update Status
        document.getElementById('status').innerText = `SIGNALS: ${data.length} LOCKED`;

        // Auto-zoom to fit everyone (Ohio to LA)
        if (allCoords.length > 1) {
            map.fitBounds(L.latLngBounds(allCoords), { padding: [100, 100], animate: true });
        }

    } catch (err) {
        console.error("Radar Error:", err);
    }
}

// Initial fire and interval
updateRadar();
setInterval(updateRadar, 3000);