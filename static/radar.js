// ==========================================
// SPAZZ RADAR & PROXIMITY ENGINE
// File Path: static/js/radar.js
// ==========================================

// --- 📍 GLOBAL STATE ---
let myLat = 39.333, myLon = -82.982; 
let markers = {};
let activeTargetId = null;
let isAlerting = false; 

// --- 🌀 VISUAL RADAR ANIMATION STATE ---
let pulseScale = 1;
let pulseGrowing = true;

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
        sfx[name].play().catch(() => {
            // Silently swallow autoplay restriction errors until user interacts
        });
    }
}

// --- 🗺️ MAP INITIALIZATION ---
let map = null;
const mapElement = document.getElementById('map');

if (mapElement && typeof L !== 'undefined') {
    map = L.map('map', { zoomControl: false, attributionControl: false }).setView([myLat, myLon], 16);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png').addTo(map);
}

// --- 📐 HAVERSINE DISTANCE FORMULA ---
function getDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3; // meters
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
    return R * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

// --- 🌀 HARDWARE-ACCELERATED RADAR ANIMATION LOOP ---
function animateRadarPulse() {
    const pulseEl = document.getElementById('radar-pulse');

    if (pulseEl) {
        let proximityFactor = 0.15; // Base scanning speed

        // Speed up animation dynamically if locked onto an active target
        if (activeTargetId && markers[activeTargetId]) {
            const targetPos = markers[activeTargetId].getLatLng();
            const dist = getDistance(myLat, myLon, targetPos.lat, targetPos.lng);
            // Proximity factor ranges from 0.1 (far away) to 1.0 (extremely close)
            proximityFactor = Math.min(Math.max(1 - (dist / 100), 0.1), 1.0);
        }

        // Adjust pulsing rate based on proximity factor
        const step = 0.004 + (proximityFactor * 0.025);

        if (pulseGrowing) {
            pulseScale += step;
            if (pulseScale >= 1 + (proximityFactor * 0.6)) pulseGrowing = false;
        } else {
            pulseScale -= step;
            if (pulseScale <= 1) pulseGrowing = true;
        }

        pulseEl.style.transform = `scale(${pulseScale})`;
        pulseEl.style.opacity = (0.2 + (proximityFactor * 0.6)).toString();
    }

    // Keep the loop running seamlessly on every browser repaint
    requestAnimationFrame(animateRadarPulse);
}

// --- 📡 THE RADAR DATA LOOP ---
async function updateRadar() {
    try {
        const response = await fetch('/api/users');
        if (!response.ok) return;

        const json = await response.json();
        const users = json.entities || [];
        
        // Update Credit Display safely
        const coinEl = document.getElementById('coin-count');
        if (coinEl) {
            const ben = users.find(u => u.id === 'user_ben');
            if (ben) coinEl.innerText = ben.credits || 0;
        }

        const currentIds = new Set(users.map(u => u.id));

        // 1. AUTOMATIC PROXIMITY INTERCEPTOR
        if (!activeTargetId && !isAlerting) {
            const match = users.find(u => u.is_match === true);
            const wispMatch = users.find(u => u.type === 'wisp');

            if (match && getDistance(myLat, myLon, match.lat, match.lon) < 100) {
                triggerSpazzAlert(match, 'spazz');
            } else if (wispMatch && getDistance(myLat, myLon, wispMatch.lat, wispMatch.lon) < 50) {
                triggerSpazzAlert(wispMatch, 'wisp');
            }
        }

        // 2. RENDER & AUTO-TRACKING PROCESSING
        users.forEach(user => {
            const color = user.is_match ? '#8a2be2' : (user.type === 'user' ? '#555' : '#00ffff');

            // Update Map Marker Positions
            if (map) {
                if (markers[user.id]) {
                    markers[user.id].setLatLng([user.lat, user.lon]);
                } else {
                    markers[user.id] = L.circleMarker([user.lat, user.lon], {
                        radius: user.type === 'user' ? 10 : 8,
                        fillColor: color, color: '#fff', weight: 2, fillOpacity: 0.8
                    }).addTo(map);
                }
            }

            // --- 📍 PROXIMITY ENGINE & AUTO-COLLECT ---
            if (activeTargetId === user.id) {
                const dist = getDistance(myLat, myLon, user.lat, user.lon);
                const statusEl = document.getElementById('status');
                const fillEl = document.getElementById('proximity-fill');
                const discoveryCardEl = document.getElementById('discovery-card');

                // AUTO-BREAK ENCOUNTER (User walked away > 50m)
                if (dist > 50) {
                    activeTargetId = null; 
                    if (statusEl) statusEl.innerText = "SIGNAL LOST...";
                    if (fillEl) fillEl.style.height = "0%";
                    if (discoveryCardEl) discoveryCardEl.style.display = 'none';
                    return; 
                }

                // UPDATE UI SYSTEM
                if (statusEl) {
                    statusEl.innerText = `${user.type === 'wisp' ? 'WISP NEARBY' : 'MATCH CLOSING IN'}: ${Math.round(dist)}m`;
                }
                
                if (fillEl) {
                    let percent = Math.max(0, Math.min(100, (100 - (dist * 2)))); 
                    fillEl.style.height = percent + "%";
                }

                // AUTO-HARVEST/COLLECT (Distance < 15m)
                if (dist < 15) {
                    playSound('collect');
                    harvestTarget(user.id);
                    activeTargetId = null;
                    if (discoveryCardEl) discoveryCardEl.style.display = 'none';
                    if (statusEl) statusEl.innerText = "DISCOVERED!";
                }
            }
        });

        // 3. CLEANUP DISCONNECTED ENTITIES
        Object.keys(markers).forEach(id => {
            if (id !== 'me' && !currentIds.has(id)) { 
                if (map) map.removeLayer(markers[id]); 
                delete markers[id]; 
            }
        });

    } catch (err) { 
        console.error("Radar Loop Error:", err); 
    }
}

// --- 🚨 CLEAN AUTO-TRIGGER SYSTEM ---
function triggerSpazzAlert(target, type) {
    isAlerting = true;
    activeTargetId = target.id;
    
    const cardEl = document.getElementById('discovery-card');
    const statusEl = document.getElementById('status');

    if (cardEl) cardEl.style.display = 'block';

    if (type === 'spazz') {
        if (navigator.vibrate) navigator.vibrate([500, 110, 500]);
        playSound('lock');
        if (statusEl) statusEl.innerText = "NEW SIGNAL DETECTED...";
    } else {
        if (navigator.vibrate) navigator.vibrate([100, 100, 100]);
        playSound('wisp_ping');
        if (statusEl) statusEl.innerText = "WISP DETECTED...";
    }
    
    setTimeout(() => { isAlerting = false; }, 15000);
}

async function harvestTarget(targetId) {
    try {
        await fetch(`/api/collect/${targetId}`, { method: 'POST' });
    } catch (e) {
        console.error("Harvesting failed:", e);
    }
}

// --- 🌍 POSITION TRACKING ---
if ("geolocation" in navigator) {
    navigator.geolocation.watchPosition(
        pos => {
            myLat = pos.coords.latitude; 
            myLon = pos.coords.longitude;
            
            if (map) {
                if (!markers['me']) {
                    markers['me'] = L.circleMarker([myLat, myLon], { 
                        radius: 12, 
                        fillColor: '#ff00ff', 
                        color: '#fff', 
                        weight: 3, 
                        fillOpacity: 1 
                    }).addTo(map);
                } else { 
                    markers['me'].setLatLng([myLat, myLon]); 
                }
            }
        }, 
        err => console.warn("Geolocation warning:", err.message), 
        { enableHighAccuracy: true }
    );
}

// --- 🚀 ENGINE INITIALIZATION ---
document.addEventListener('DOMContentLoaded', () => {
    // Start visual animation loop
    animateRadarPulse();
    // Start data polling every 3 seconds
    setInterval(updateRadar, 3000);
});