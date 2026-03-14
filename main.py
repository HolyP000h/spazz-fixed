import math
import time
import json
import asyncio
import random
<<<<<<< HEAD
import winsound
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# Enable CORS so the HTML file can talk to the backend
# Enable CORS
 8c8a0a857a81c8b47569e12edc67db6caec78bbd
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
    # --- NEW: SHADOW BAN STATUS ---
    is_shadow_banned: bool = False 
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
<<<<<<< HEAD
def create_entity(entity_id, username, e_type="user", lat=0.0, lon=0.0, wisp_class=None):
=======
def create_entity(entity_id, username, e_type="user", lat=0.0, lon=0.0, age=25, wisp_class=None):
    # --- AGE SHIELD CHECK ---
    if age < 18:
        raise ValueError("Age Shield: User must be 18+")
    
    # --- AUTO-SHADOW BAN TRIGGER ---
    shadow_flag = False
    if "bot" in username.lower() or "spam" in username.lower():
        shadow_flag = True

    return User(
        id=str(entity_id),
        username=username,
        type=e_type,
        lat=lat,
        lon=lon,
        wisp_class=wisp_class
        age=age,
        wisp_class=wisp_class,
        is_shadow_banned=shadow_flag
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
<<<<<<< HEAD
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
    print("💓 Ghost Heartbeat pumping on the Legion i9...")
    while True:
        all_entities = load_from_db()
        
        # SPAWN LOGIC
        if len(all_entities) < 5:
            new_wisp = create_entity(f"wisp_{random.randint(1,999)}", "Golden Wisp", "wisp", 40.7128 + random.uniform(-0.01, 0.01), -74.0060 + random.uniform(-0.01, 0.01))
            all_entities.append(new_wisp)

        for entity in all_entities:
            if entity.type != "player":
                entity.lat += random.uniform(-0.0005, 0.0005)
                entity.lon += random.uniform(-0.0005, 0.0005)

        save_to_db(all_entities)
        await asyncio.sleep(10)

# --- 5. STARTUP EVENT ---
@app.on_event("startup")
async def startup_event():
<<<<<<< HEAD
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
=======
    active_users = load_from_db()
    if not active_users:
        u1 = create_entity("1", "You", "player", 40.7128, -74.0060, 25)
        # Testing the Shadow Ban on a "bot"
        u2 = create_entity("2", "spazz-bot-9000", "wisp", 40.7130, -74.0062, 21) 
        u3 = create_entity("3", "the queen", "wisp", 40.7125, -74.0055, 30)
        save_to_db([u1, u2, u3])
    
    asyncio.create_task(ghost_heartbeat())
    print("🚀 Spazz Engine: Shadow Ban & Age Shield Online.")

# --- WEB ENDPOINTS ---
@app.get("/users")
def get_users():
    # --- SHADOW BAN FILTER ---
    # Only return users who are NOT shadow banned to the radar
    all_users = load_from_db()
    return [u.to_dict() for u in all_users if not u.is_shadow_banned]

@app.post("/join")
def join_game(username: str, age: int, lat: float, lon: float):
    users = load_from_db()
    try:
        new_user = create_entity(len(users)+1, username, "player", lat, lon, age)
        users.append(new_user)
        save_to_db(users)
        return {"status": "Success", "user": new_user.to_dict()}
    except ValueError as e:
        raise HTTPException(status_code=403, detail=str(e))

@app.get("/pulse/{user_id}/{target_id}")
def get_pulse(user_id: str, target_id: str):
    users = load_from_db()
    me = next((u for u in users if u.id == user_id), None)
    them = next((u for u in users if u.id == target_id), None)
    
    if not me or not them:
        raise HTTPException(status_code=404, detail="User not found")
=======
    if not me or not them or them.is_shadow_banned:
        raise HTTPException(status_code=404, detail="Target not visible")

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
=======
    if dist < 0.002: pulse_status = {"mode": "STROBE", "vibe": "SOLID"}
    elif dist < 0.05: pulse_status = {"mode": "PULSE", "vibe": "FAST"}
    else: pulse_status = {"mode": "PULSE", "vibe": "SLOW"}
        
    return {"target": them.username, "distance": round(dist, 4), "pulse": pulse_status}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)