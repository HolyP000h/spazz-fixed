import json
import asyncio
import random
import os
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

# Enable CORS
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
    except:
        return []

# --- 4. THE HEARTBEAT (Movement) ---
async def ghost_heartbeat():
    print("💓 Ghost Heartbeat pumping...")
    while True:
        all_entities = load_from_db()
        if all_entities:
            for entity in all_entities:
                # Subtle drifting movement
                entity.lat += random.uniform(-0.0002, 0.0002)
                entity.lon += random.uniform(-0.0002, 0.0002)
            save_to_db(all_entities)
        await asyncio.sleep(3)

# --- 5. STARTUP & ENDPOINTS ---
@app.on_event("startup")
async def startup_event():
    # Start movement
    asyncio.create_task(ghost_heartbeat())
    
    # Mass Populate if empty
    all_entities = load_from_db()
    if len(all_entities) < 5:
        print("🌌 Mass Manifesting 50 entities into the Void...")
        for i in range(50):
            new_id = f"gen_{random.randint(1000, 9999)}"
            roll = random.random()
            
            if roll < 0.1: # Purple Users
                u_type, u_name, u_class = "user", f"Shadow_{i}", None
            elif roll < 0.3: # Red Phantoms
                u_type, u_name, u_class = "wisp", "Red Phantom", "whisp-red"
            else: # Cyan Wisps
                u_type, u_name, u_class = "wisp", "Common Wisp", "whisp-cyan"

            all_entities.append(User(
                id=new_id, username=u_name, type=u_type,
                lat=39.333 + random.uniform(-0.02, 0.02),
                lon=-82.982 + random.uniform(-0.02, 0.02),
                wisp_class=u_class
            ))
        save_to_db(all_entities)
    print("🚀 Spazz Engine: Online @ http://127.0.0.1:8888")

@app.get("/api/users")
def get_users():
    return [u for u in load_from_db() if not u.is_shadow_banned]

@app.get("/", response_class=HTMLResponse)
async def read_index():
    with open("index.html", "r", encoding="utf-8") as f:
        return f.read()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8888)