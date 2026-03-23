// Initialize the map
var map = L.map('map').setView([39.3331, -82.9824], 14);

// Add Dark Matter tiles
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: 'SPAZZ Stealth Radar'
}).addTo(map);

async function updateRadar() {
    try {
        console.log("Fetching signals...");
        const response = await fetch('/api/users');
        const data = await response.json();
        
        // Clear old markers
        map.eachLayer((layer) => {
            if (layer instanceof L.CircleMarker) {
                map.removeLayer(layer);
            }
        });

        const markers = [];

        data.forEach(user => {
            let markerOptions = {
                radius: user.type === 'user' ? 10 : 6,
                color: '#fff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            };

            // Apply Red Whisp flicker class and color
            if (user.wisp_class === 'whisp-red') {
                markerOptions.fillColor = '#ff0000';
                markerOptions.className = 'whisp-red'; // Triggers your flicker CSS
            } else if (user.type === 'wisp') {
                markerOptions.fillColor = '#00ffff'; 
            } else {
                markerOptions.fillColor = '#8a2be2'; 
            }

            // Create and add the marker
            L.circleMarker([user.lat, user.lon], markerOptions)
                .addTo(map)
                .bindPopup(`<b>${user.username}</b><br>${user.type}`);
            
            // Keep track of coordinates for the auto-zoom
            markers.push([user.lat, user.lon]);
        }); // <-- Fixed the bracket position here

        // Automatically zoom to fit everyone (Ohio and LA)
        if (markers.length > 0) {
            const bounds = L.latLngBounds(markers);
            map.fitBounds(bounds, { padding: [100, 100], animate: true });
        }

    } catch (err) {
        console.error("Radar Error:", err);
    }
}

updateRadar();
setInterval(updateRadar, 5000);
