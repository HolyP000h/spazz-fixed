// --- 🔊 AUDIO ENGINE ---
const sfx = {
    ping: new Audio('/static/audio/ping.mp3'),
    lock: new Audio('/static/audio/lockon.mp3'),
    collect: new Audio('/static/audio/collect.mp3')
};

function playSound(name) {
    sfx[name].currentTime = 0;
    sfx[name].play().catch(() => console.log("Interaction required for audio"));
}

// --- 📍 GLOBAL STATE ---
let lockedTargetId = null;
let myLat, myLon;
let markers = {};

// --- 🗺️ INITIALIZE DARK RADAR ---
var map = L.map('map', { 
    zoomControl: false,
    attributionControl: false 
}).setView([39.333, -82.982], 16);

L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png').addTo(map);

// --- 📡 THE RADAR LOOP ---
async function updateRadar() {
    try {
        const response = await fetch('/api/users');
        const json = await response.json();
        
        const users = json.entities || [];
        const coachMsg = json.coach || "SCANNING...";

        const coachEl = document.getElementById('coach-bubble');
        if (coachEl) coachEl.innerText = coachMsg;

        const currentIds = new Set(users.map(u => u.id));

        users.forEach(user => {
            const color = user.wisp_class === 'whisp-red' ? '#ff0000' : 
                         (user.type === 'user' ? '#8a2be2' : '#00ffff');

            // 1. CREATE OR UPDATE MARKER
            if (markers[user.id]) {
                markers[user.id].setLatLng([user.lat, user.lon]);
            } else {
                markers[user.id] = L.circleMarker([user.lat, user.lon], {
                    radius: user.type === 'user' ? 10 : 8,
                    fillColor: color, color: '#fff', weight: 2, fillOpacity: 0.8
                }).addTo(map);

                markers[user.id].on('click', () => {
                    lockedTargetId = user.id;
                    playSound('lock');
                    const card = document.getElementById('discovery-card');
                    if (card) card.style.display = 'block';
                    console.log("🔒 LOCKED ONTO: " + user.username);
                });
            }

            // 2. HUNT & HARVEST LOGIC (ONLY for the locked target)
            if (lockedTargetId === user.id && myLat) {
                const dist = getDistance(myLat, myLon, user.lat, user.lon);
                
                // Update Distance Text
                const statusEl = document.getElementById('status');
                if (statusEl) statusEl.innerText = `TARGET: ${Math.round(dist)}m`;
                
                // Update Pink Proximity Bar
                const fill = document.getElementById('proximity-fill');
                if (fill) {
                    let proximityPercent = Math.max(0, Math.min(100, (100 - dist))); 
                    fill.style.height = proximityPercent + "%";
                }
                
                // Trigger Harvest
                if (dist < 15) {
                    playSound('collect');
                    harvestTarget(user.id);
                    lockedTargetId = null; // Unlock after harvest
                    if (fill) fill.style.height = "0%";
                }
            }
        });

        // 3. CLEANUP OLD MARKERS
        Object.keys(markers).forEach(id => {
            if (id !== 'me' && !currentIds.has(id)) { 
                map.removeLayer(markers[id]); 
                delete markers[id]; 
            }
        });

    } catch (err) { 
        console.error("Radar Sync Error:", err); 
    }
}

// --- 📏 MATH & GPS ---
function getDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3; // Earth radius in meters
    const dLat = (lat2-lat1) * Math.PI/180;
    const dLon = (lon2-lon1) * Math.PI/180;
    const a = Math.sin(dLat/2)**2 + Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLon/2)**2;
    return R * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)));
}

// Watch physical location
navigator.geolocation.watchPosition(pos => {
    myLat = pos.coords.latitude;
    myLon = pos.coords.longitude;
    
    if (!markers['me']) {
        markers['me'] = L.circleMarker([myLat, myLon], {
            radius: 12, fillColor: '#00ffff', color: '#fff', weight: 3, fillOpacity: 1
        }).addTo(map).bindPopup("YOU (STAY STEALTH)");
    } else {
        markers['me'].setLatLng([myLat, myLon]);
    }
    map.panTo([myLat, myLon], { animate: true });
}, err => {
    console.warn("GPS ERROR: ", err.message);
}, { enableHighAccuracy: true });

// Sync with backend every 3 seconds
setInterval(updateRadar, 3000);

// Boot Screen Fade
setTimeout(() => {
    const boot = document.getElementById('boot-screen');
    if (boot) {
        boot.style.opacity = '0';
        setTimeout(() => boot.remove(), 1000);
    }
}, 3000);