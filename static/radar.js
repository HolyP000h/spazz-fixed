// --- 📍 GLOBAL STATE ---
let myLat = 39.333, myLon = -82.982; 
let markers = {};
let lockedTargetId = null; 
let isAlerting = false; 

// --- 🔊 AUDIO ENGINE ---
const sfx = {
    lock: new Audio('/static/audio/lockon.mp3'),
    wisp_ping: new Audio('/static/audio/wisp_found.mp3'),
    collect: new Audio('/static/audio/collect.mp3'),
    ping: new Audio('/static/audio/ping.mp3')
};

function playSound(name) {
    if (sfx[name]) {
        sfx[name].currentTime = 0;
        sfx[name].play().catch(() => console.log("User interaction required"));
    }
}

// --- 🗺️ MAP INITIALIZATION ---
var map = L.map('map', { zoomControl: false, attributionControl: false }).setView([myLat, myLon], 16);
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png').addTo(map);

function getDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
    return R * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

// --- 📡 THE RADAR LOOP ---
async function updateRadar() {
    try {
        const response = await fetch('/api/users');
        const json = await response.json();
        const users = json.entities || [];
        
        // Update Credit Display
        const coinEl = document.getElementById('coin-count');
        if (coinEl) {
            const ben = users.find(u => u.id === 'user_ben');
            if (ben) coinEl.innerText = ben.credits || 0;
        }

        const currentIds = new Set(users.map(u => u.id));

        // 1. DUAL INTERCEPTOR (MATCH vs WISP)
        if (!lockedTargetId && !isAlerting) {
            const match = users.find(u => u.is_match === true);
            const wispMatch = users.find(u => u.type === 'wisp');

            if (match && getDistance(myLat, myLon, match.lat, match.lon) < 100) {
                triggerSpazzAlert(match, 'spazz');
            } else if (wispMatch && getDistance(myLat, myLon, wispMatch.lat, wispMatch.lon) < 50) {
                triggerSpazzAlert(wispMatch, 'wisp');
            }
        }

        // 2. RENDER & TRACKING 
        users.forEach(user => {
            const color = user.is_match ? '#8a2be2' : (user.type === 'user' ? '#555' : '#00ffff');

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
                    document.getElementById('discovery-card').style.display = 'block';
                });
            }

            // --- 📍 TRACKING LOGIC ---
            if (lockedTargetId === user.id) {
                const dist = getDistance(myLat, myLon, user.lat, user.lon);
                
                // AUTO-BREAK LOCK (Distance > 35m)
                if (dist > 35) {
                    lockedTargetId = null; 
                    document.getElementById('status').innerText = "SIGNAL LOST...";
                    document.getElementById('proximity-fill').style.height = "0%";
                    document.getElementById('discovery-card').style.display = 'none';
                    return; 
                }

                // UPDATE UI
                document.getElementById('status').innerText = `LOCKED: ${Math.round(dist)}m`;
                
                const fill = document.getElementById('proximity-fill');
                if (fill) {
                    let percent = Math.max(0, Math.min(100, (100 - (dist * 3)))); // Scaled for better visual feedback
                    fill.style.height = percent + "%";
                }

                // AUTO-COLLECT (Distance < 15m)
                if (dist < 15) {
                    playSound('collect');
                    harvestTarget(user.id);
                    lockedTargetId = null;
                    document.getElementById('discovery-card').style.display = 'none';
                    document.getElementById('status').innerText = "TARGET ACQUIRED!";
                }
            }
        });

        // 3. CLEANUP
        Object.keys(markers).forEach(id => {
            if (id !== 'me' && !currentIds.has(id)) { 
                map.removeLayer(markers[id]); 
                delete markers[id]; 
            }
        });

    } catch (err) { console.error("Radar Error:", err); }
}

function triggerSpazzAlert(target, type) {
    isAlerting = true;
    if (type === 'spazz') {
        if (navigator.vibrate) navigator.vibrate([500, 110, 500]);
        playSound('lock');
        if (confirm(`TARGET DETECTED: ${target.age}${target.gender[0].toUpperCase()}. Lock on?`)) {
            lockedTargetId = target.id;
            document.getElementById('discovery-card').style.display = 'block';
        }
    } else {
        if (navigator.vibrate) navigator.vibrate([100, 100, 100]);
        playSound('wisp_ping');
        if (confirm("Shhh... Be vewy quiet. Hunting a Wisp. Track?")) {
            lockedTargetId = target.id;
            document.getElementById('discovery-card').style.display = 'block';
        }
    }
    setTimeout(() => { isAlerting = false; }, 15000);
}

async function harvestTarget(targetId) {
    await fetch(`/api/collect/${targetId}`, { method: 'POST' });
}

navigator.geolocation.watchPosition(pos => {
    myLat = pos.coords.latitude; myLon = pos.coords.longitude;
    if (!markers['me']) {
        markers['me'] = L.circleMarker([myLat, myLon], { radius: 12, fillColor: '#ff00ff', color: '#fff', weight: 3, fillOpacity: 1 }).addTo(map);
    } else { markers['me'].setLatLng([myLat, myLon]); }
}, null, { enableHighAccuracy: true });

setInterval(updateRadar, 3000);