import math
import time
import json
import asyncio
import random
import winsound
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# Enable CORS so the HTML file can talk to the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 1. DATA MODEL (Pydantic) ---
class User(BaseModel):
    id: str
    username: str
    type: str
    lat: float
    lon: float
    credits: int = 0
    wisp_class: Optional[str] = None
    active_skin: str = "basic_white"
    blocked_users: List[str] = []
    min_age: int = 18
    max_age: int = 99
    age: int = 25
    nudges_balance: int = 10
    is_premium: bool = False
    last_reward_time: float = 0.0

    def to_dict(self):
        return self.dict()

# --- 2. DATABASE TOOLS ---
DB_FILE = 'users_db.json'

def save_to_db(users_list: List[User]):
    data = {"users": [u.to_dict() for u in users_list]}
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=4)
    # print("💾 [DATABASE]: Sync complete.")

def load_from_db() -> List[User]:
    try:
        with open(DB_FILE, 'r') as f:
            data = json.load(f)
            return [User(**u) for u in data["users"]]
    except (FileNotFoundError, json.JSONDecodeError):
        return []

# --- 3. HELPER FUNCTIONS ---
def create_entity(entity_id, username, e_type="user", lat=0.0, lon=0.0, wisp_class=None):
    return User(
        id=str(entity_id),
        username=username,
        type=e_type,
        lat=lat,
        lon=lon,
        wisp_class=wisp_class
    )

def calculate_distance(lat1, lon1, lat2, lon2):
    R = 3958.8 # Miles
    dlat, dlon = math.radians(lat2-lat1), math.radians(lon2-lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * (2 * math.atan2(math.sqrt(a), math.sqrt(1-a)))

def calculate_bearing(lat1, lon1, lat2, lon2):
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_lambda = math.radians(lon2 - lon1)
    y = math.sin(delta_lambda) * math.cos(phi2)
    x = math.cos(phi1) * math.sin(phi2) - \
        math.sin(phi1) * math.cos(phi2) * math.cos(delta_lambda)
    return (math.degrees(math.atan2(y, x)) + 360) % 360

# --- 4. THE HEARTBEAT (Background Engine) ---
async def ghost_heartbeat():
    print("💓 Ghost Heartbeat is officially pumping...")
    while True:
        all_entities = load_from_db()
        
        # SPAWN LOGIC: Keep the map populated
        if len(all_entities) < 5:
            new_wisp = create_entity(f"wisp_{random.randint(1,999)}", "Golden Wisp", "wisp", 40.7128 + random.uniform(-0.01, 0.01), -74.0060 + random.uniform(-0.01, 0.01))
            all_entities.append(new_wisp)
            print("✨ [SPAWNER]: A Golden Wisp has appeared!")

        for entity in all_entities:
            # MOVEMENT for non-player entities
            if entity.type != "player":
                entity.lat += random.uniform(-0.0005, 0.0005)
                entity.lon += random.uniform(-0.0005, 0.0005)

        save_to_db(all_entities)
        await asyncio.sleep(10)

# --- 5. STARTUP EVENT ---
@app.on_event("startup")
async def startup_event():
    print("🧪 [DIAGNOSTIC]: Checking for users...")
    active_users = load_from_db()
    
    if not active_users:
        u1 = create_entity("1", "You", "player", 40.7128, -74.0060)
        u2 = create_entity("2", "spazzmaster", "wisp", 40.7130, -74.0062, "whisp-red-underlined")
        u3 = create_entity("3", "the queen", "wisp", 40.7125, -74.0055, "whisp-red-underlined")
        save_to_db([u1, u2, u3])
        print("✨ [DIAGNOSTIC]: Generated fresh entities.")

    asyncio.create_task(ghost_heartbeat())
    print("🚀 Engine fully initialized.")

# --- SPAZZ SHOP CATALOG ---
SPAZZ_CATALOG = {
    "basic_white": {"name": "Standard Strobe", "price": 0},
    "boss_gold": {"name": "The Final Boss", "price": 500},
    "neon_heart": {"name": "Lover Pulse", "price": 200}
}

# --- WEB ENDPOINTS ---
@app.get("/", response_class=HTMLResponse)
async def read_index():
    with open("index.html", "r") as f:
        return f.read()

@app.get("/users")
def get_users():
    return [u.to_dict() for u in load_from_db()]

@app.post("/teleport/{user_id}")
def teleport_user(user_id: str, lat: float, lon: float):
    users = load_from_db()
    user = next((u for u in users if u.id == user_id), None)
    
    if user:
        user.lat = lat
        user.lon = lon
        save_to_db(users)
        return {"message": f"{user.username} warped to new coordinates!"}
    raise HTTPException(status_code=404, detail="User not found")

@app.get("/pulse/{user_id}/{target_id}")
def get_pulse(user_id: str, target_id: str):
    users = load_from_db()
    me = next((u for u in users if u.id == user_id), None)
    them = next((u for u in users if u.id == target_id), None)
    
    if not me or not them:
        raise HTTPException(status_code=404, detail="User not found")

    dist = calculate_distance(me.lat, me.lon, them.lat, them.lon)
    bearing = calculate_bearing(me.lat, me.lon, them.lat, them.lon)
    
    # --- PULSE LOGIC ---
    if dist < 0.002: # ~10 feet
        pulse_status = {"mode": "STROBE", "vibe": "SOLID", "speed": 0}
    elif dist < 0.05: # Close
        pulse_status = {"mode": "PULSE", "vibe": "FAST", "speed": 0.5}
    else: # Cold
        pulse_status = {"mode": "PULSE", "vibe": "SLOW", "speed": 5.0}
        
    return {
        "target": them.username,
        "distance_miles": round(dist, 4),
        "bearing_degrees": round(bearing, 0),
        "pulse": pulse_status,
        "status": "locked"
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Engine starting in standalone mode...")
    uvicorn.run(app, host="0.0.0.0", port=8001)