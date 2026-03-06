import math
import time
import json
import asyncio
import random
import os
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from dotenv import load_dotenv

# --- 0. INITIALIZATION ---
load_dotenv()
ADMIN_KEY = os.getenv("ADMIN_KEY", "SpazzPass123")

# Graceful winsound import for non-windows/mobile testing
try:
    import winsound
except ImportError:
    winsound = None

from fastapi.staticfiles import StaticFiles

app = FastAPI()

app.mount("/static", StaticFiles(directory="static"), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 1. DATA MODEL ---
class User(BaseModel):
    id: str
    username: str
    type: str # "player" or "wisp"
    lat: float
    lon: float
    credits: int = 0
    xp: int = 0
    level: int = 1
    wisp_class: Optional[str] = None
    active_skin: str = "basic_white"
    age: int = 25
    is_premium: bool = False

    def to_dict(self):
        return self.dict()

# --- 2. DATABASE TOOLS ---
DB_FILE = 'users_db.json'

def save_to_db(users_list: List[User]):
    data = {"users": [u.to_dict() for u in users_list]}
    with open(DB_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)

def load_from_db() -> List[User]:
    if not os.path.exists(DB_FILE):
        return []
    try:
        with open(DB_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return [User(**u) for u in data["users"]]
    except (json.JSONDecodeError, KeyError):
        return []

# --- 3. LOGIC HELPERS ---
def is_safe_interaction(user_age: int, target_age: int) -> bool:
    """The 'Romeo & Juliet' Safety Filter"""
    age_diff = abs(user_age - target_age)
    if user_age < 18 or target_age < 18:
        return age_diff <= 3
    return True

def calculate_distance(lat1, lon1, lat2, lon2):
    # Standard Pythagorean for small distances (Radar scale)
    return math.sqrt((lat1 - lat2)**2 + (lon1 - lon2)**2)

# --- 4. THE HEARTBEAT (i9 Optimized) ---
async def ghost_heartbeat():
    print("💓 Ghost Heartbeat is pumping on the i9...")
    while True:
        all_entities = load_from_db()
        wisps = [u for u in all_entities if u.type == "wisp"]
        
        # Keep 12 wisps on the map
        if len(wisps) < 12:
            new_id = f"wisp_{random.randint(1000, 9999)}"
            # Random spawn near the center
            new_wisp = User(
                id=new_id,
                username="Common Wisp",
                type="wisp",
                lat=40.7128 + random.uniform(-0.004, 0.004),
                lon=-74.0060 + random.uniform(-0.004, 0.004),
                wisp_class="whisp-cyan"
            )
            all_entities.append(new_wisp)

        # Subtle Wisp Movement
        for e in all_entities:
            if e.type == "wisp":
                e.lat += random.uniform(-0.00005, 0.00005)
                e.lon += random.uniform(-0.00005, 0.00005)

        save_to_db(all_entities)
        await asyncio.sleep(1) # Faster update for the new PC

# --- 5. ENDPOINTS ---
@app.on_event("startup")
async def startup_event():
    active_users = load_from_db()
    if not active_users:
        u1 = User(id="1", username="Spazzmaster", type="player", lat=40.7128, lon=-74.0060, age=25)
        u2 = User(id="2", username="RizzQueen", type="player", lat=40.7135, lon=-74.0065, age=24)
        save_to_db([u1, u2])
    asyncio.create_task(ghost_heartbeat())

@app.get("/", response_class=HTMLResponse)
async def read_index():
    try:
        with open("index.html", "r", encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return HTMLResponse("index.html not found. Check your folder!", status_code=404)

@app.get("/users")
def get_users():
    return [u.to_dict() for u in load_from_db()]

@app.post("/move/{user_id}/{direction}/{key}")
def move_user(user_id: str, direction: str, key: str):
    if key != ADMIN_KEY:
        raise HTTPException(status_code=403, detail="Invalid Key")
    
    all_users = load_from_db()
    user = next((u for u in all_users if u.id == user_id), None)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Movement
    step = 0.0001
    if "north" in direction: user.lat += step
    if "south" in direction: user.lat -= step
    if "east" in direction:  user.lon += step
    if "west" in direction:  user.lon -= step

    # Wisp Collection & Safety Interaction
    for other in all_users[:]:
        if other.id == user.id: continue
        
        dist = calculate_distance(user.lat, user.lon, other.lat, other.lon)
        
        # Wisp Magnet (0.0006 threshold)
        if other.type == "wisp" and dist < 0.0006:
            user.credits += 25
            user.xp += 50
            all_users.remove(other)
            if winsound:
                try: winsound.Beep(1200, 100)
                except: pass

        # Human Interaction Safety
        if other.type == "player" and dist < 0.001:
            if not is_safe_interaction(user.age, other.age):
                # Optionally hide users here, for now we just block "pings"
                pass

    # Level Up Check
    if user.xp >= (user.level * 200):
        user.level += 1
        user.xp = 0
        if winsound:
            try: winsound.Beep(2000, 300)
            except: pass

    save_to_db(all_users)
    return user.to_dict()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
