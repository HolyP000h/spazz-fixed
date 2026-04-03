import json
import asyncio
import random
import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(BASE_DIR, 'users_db.json')
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# 1. MOUNT STATIC FILES
if not os.path.exists("static"):
    os.makedirs("static")
app.mount("/static", StaticFiles(directory="static"), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 2. DATA MODEL ---
class User(BaseModel):
    id: str
    username: str
    type: str
    lat: float
    lon: float
    credits: int = 0
    gender: str = "other"
    is_premium: bool = False
    is_shadow_banned: bool = False
    age: int = 25
    wisp_class: Optional[str] = None

# --- 3. DATABASE TOOLS ---
DB_FILE = 'users_db.json'

def save_to_db(users_list: List[User]):
    data = {"users": [u.model_dump() for u in users_list]}
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=4)

def load_from_db() -> List[User]:
    try:
        if not os.path.exists(DB_FILE):
            return []
        with open(DB_FILE, 'r') as f:
            data = json.load(f)
            user_data = data.get("users", [])
            return [User(**u) for u in user_data]
    except Exception as e:
        print(f"Error loading DB: {e}")
        return []

# --- 4. THE HEARTBEAT (Movement) ---
async def ghost_heartbeat():
    print("💓 Ghost Heartbeat pumping...")
    while True:
        all_entities = load_from_db()
        if all_entities:
            for entity in all_entities:
                if entity.type == "wisp": # Only move ghosts, not the player!
                    entity.lat += random.uniform(-0.0001, 0.0001)
                    entity.lon += random.uniform(-0.0001, 0.0001)
            save_to_db(all_entities)
        await asyncio.sleep(3)

# --- 5. STARTUP & ENDPOINTS ---
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(ghost_heartbeat())
    
    all_entities = load_from_db()
    
    # 🚨 FIX: Ensure Ben exists at startup
    if not any(u.id == "user_ben" for u in all_entities):
        print("👤 Initializing Player: Ben")
        all_entities.append(User(
            id="user_ben", username="Ben", type="user",
            lat=39.333, lon=-82.982, credits=0
        ))

    # Mass Populate if empty
    if len(all_entities) < 10:
        print("🌌 Mass Manifesting entities...")
        for i in range(50):
            new_id = f"gen_{random.randint(1000, 9999)}"
            roll = random.random()
            if roll < 0.1: u_type, u_name, u_class = "user", f"Shadow_{i}", None
            elif roll < 0.3: u_type, u_name, u_class = "wisp", "Red Phantom", "whisp-red"
            else: u_type, u_name, u_class = "wisp", "Common Wisp", "whisp-cyan"

            all_entities.append(User(
                id=new_id, username=u_name, type=u_type,
                lat=39.333 + random.uniform(-0.005, 0.005),
                lon=-82.982 + random.uniform(-0.005, 0.005),
                wisp_class=u_class
            ))
    
    save_to_db(all_entities)
    print("🚀 Spazz Engine: Online @ http://127.0.0.1:8888")

@app.get("/api/users")
def get_users():
    all_entities = load_from_db()
    # Find Ben to calculate distance for the Coach
    user_ben = next((u for u in all_entities if u.id == "user_ben"), None)
    
    coach_msg = "COACH: Scanning for Phantoms..."
    
    if user_ben:
        # If there's a Red Phantom nearby, the coach gets excited
        has_red = any(u.wisp_class == "whisp-red" for u in all_entities)
        if has_red:
            coach_msg = "COACH: RED PHANTOM DETECTED. MOVE!"

    return {
        "entities": [u for u in all_entities if not u.is_shadow_banned],
        "coach": coach_msg
    }

@app.post("/api/collect/{wisp_id}")
async def collect_wisp(wisp_id: str):
    all_entities = load_from_db()
    target_wisp = next((x for x in all_entities if x.id == wisp_id), None)
    user_ben = next((x for x in all_entities if x.id == "user_ben"), None)

    if target_wisp and user_ben:
        val = 50 if target_wisp.wisp_class == "whisp-red" else 15
        user_ben.credits += val
        
        # Remove wisp and keep everything else (including Ben)
        all_entities = [u for u in all_entities if u.id != wisp_id]
        save_to_db(all_entities)
        
        return {"new_balance": user_ben.credits, "status": "success"}
    
    return {"status": "failed", "message": "Target lost"}, 400

@app.get("/", response_class=HTMLResponse)
async def read_index():
    with open("index.html", "r", encoding="utf-8") as f:
        return f.read()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8888)