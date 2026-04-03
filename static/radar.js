// --- 🔊 AUDIO ENGINE ---
const sfx = {
    ping: new Audio('/static/audio/ping.mp3'),
    lock: new Audio('/static/audio/lockon.mp3'),
    collect: new Audio('/static/audio/collect.mp3')
};

function playSound(name) {
    sfx[name].currentTime = 0;
    sfx[name].play().catch(() => console.log("Click map to enable audio"));
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
        
        // Handle FastAPI structure
        const users = json.entities || [];
        const coachMsg = json.coach || "SCANNING...";

        // 🤖 Update Coach UI
        const coachEl = document.getElementById('coach-bubble');
        if (coachEl) coachEl.innerText = coachMsg;

        const currentIds = new Set(users.map(u => u.id));

        users.forEach(user => {
            // Pick color based on class/type
            const color = user.wisp_class === 'whisp-red' ? '#ff0000' : 
                         (user.type === 'user' ? '#8a2be2' : '#00ffff');

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
                    console.log("🔒 LOCKED ONTO: " + user.username);
                });
            }
// Fill the pink bar as you get closer (100m is full empty, 0m is full pink)
const fill = document.getElementById('proximity-fill');
if (fill) {
    let proximityPercent = Math.max(0, Math.min(100, (100 - dist))); 
    fill.style.height = proximityPercent + "%";
}
const card = document.getElementById('discovery-card');
if (card) card.style.display = 'block';



            // 🎯 HUNT & HARVEST LOGIC
            if (lockedTargetId === user.id && myLat) {
                const dist = getDistance(myLat, myLon, user.lat, user.lon);
                const statusEl = document.getElementById('status');
                if (statusEl) statusEl.innerText = `TARGET: ${Math.round(dist)}m`;
                
                // Trigger Harvest at 15 meters
                if (dist < 15) {
                    harvestTarget(user.id);
                }
            }

            if (card) card.style.display = 'none';
if (fill) fill.style.height = "0%";
const statusEl = document.getElementById('status');
if (statusEl) statusEl.innerText = "SIGNAL HARVESTED";
        });

        // Cleanup old markers
        Object.keys(markers).forEach(id => {
            if (!currentIds.has(id)) { map.removeLayer(markers[id]); delete markers[id]; }
        });

    } catch (err) { console.error("Radar Sync Error:", err); }
}

// 🎯 HUNT & HARVEST LOGIC
            if (lockedTargetId === user.id && myLat) {
                // 1. CALCULATE THE DISTANCE FIRST
                const dist = getDistance(myLat, myLon, user.lat, user.lon);
                
                // 2. UPDATE THE STATUS TEXT
                const statusEl = document.getElementById('status');
                if (statusEl) statusEl.innerText = `TARGET: ${Math.round(dist)}m`;
                
                // 3. UPDATE THE PINK PROXIMITY BAR
                const fill = document.getElementById('proximity-fill');
                if (fill) {
                    // Fill bar based on 100m range
                    let proximityPercent = Math.max(0, Math.min(100, (100 - dist))); 
                    fill.style.height = proximityPercent + "%";
                }
                
                // 4. TRIGGER HARVEST AT 15 METERS
                if (dist < 15) {
                    harvestTarget(user.id);
                }
            }

// --- 📏 MATH & GPS ---
function getDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3;
    const dLat = (lat2-lat1) * Math.PI/180;
    const dLon = (lon2-lon1) * Math.PI/180;
    const a = Math.sin(dLat/2)**2 + Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLon/2)**2;
    return R * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)));
}

navigator.geolocation.watchPosition(pos => {
    myLat = pos.coords.latitude;
    myLon = pos.coords.longitude;
    map.panTo([myLat, myLon], { animate: true });
}, err => console.warn("GPS Weak"), { enableHighAccuracy: true });

navigator.geolocation.watchPosition(pos => {
    myLat = pos.coords.latitude;
    myLon = pos.coords.longitude;
    
    // 🎯 FORCE REVEAL: This creates your player marker if it doesn't exist
    if (!markers['me']) {
        markers['me'] = L.circleMarker([myLat, myLon], {
            radius: 12,
            fillColor: '#00ffff', // Neon Cyan for YOU
            color: '#fff',
            weight: 3,
            fillOpacity: 1
        }).addTo(map).bindPopup("YOU (STAY STEALTH)");
    } else {
        markers['me'].setLatLng([myLat, myLon]);
    }

    // Keep the camera on you
    map.panTo([myLat, myLon], { animate: true });
    
}, err => {
    console.warn("GPS ERROR: ", err.message);
    document.getElementById('status').innerText = "GPS SIGNAL LOST";
}, { enableHighAccuracy: true });

// Start the pulse
setInterval(updateRadar, 3000);

// Fade out boot screen after 3 seconds
setTimeout(() => {
    const boot = document.getElementById('boot-screen');
    if (boot) {
        boot.style.opacity = '0';
        setTimeout(() => boot.remove(), 1000);
    }
}, 3000);