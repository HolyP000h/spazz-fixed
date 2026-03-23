import math
import json
import asyncio
import random
import os
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles  # <--- NEW: Missing Import
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# 1. MOUNT STATIC FILES (The fix for your 404s!)
# This MUST happen after app = FastAPI()
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
    looking_for: str = "any"
    is_premium: bool = False
    is_shadow_banned: bool = False
    age: int = 25
    wisp_class: Optional[str] = None

# --- 3. DATABASE TOOLS ---
DB_FILE = 'users_db.json'

def save_to_db(users_list: List[User]):
    # Use model_dump() to keep JSON clean and prevent doubling lines
    data = {"users": [u.model_dump() for u in users_list]}
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=4)

def load_from_db() -> List[User]:
    try:
        if not os.path.exists(DB_FILE):
            return []
        with open(DB_FILE, 'r') as f:
            data = json.load(f)
            return [User(**u) for u in data.get("users", [])]
    except (FileNotFoundError, json.JSONDecodeError, KeyError):
        return []

# --- 4. THE HEARTBEAT (Fixed to stop doubling lines) ---
async def ghost_heartbeat():
    print("💓 Ghost Heartbeat pumping on the Legion i9...")
    while True:
        all_entities = load_from_db()
        
        # Keep a healthy amount of wisps (Max 15)
        if len(all_entities) < 15:
            new_id = f"wisp_{random.randint(100, 999)}"
            # Random Ohio-ish coordinates for new wisps
            new_wisp = User(
                id=new_id,
                username="Common Wisp",
                type="wisp",
                lat=39.333 + random.uniform(-0.01, 0.01),
                lon=-82.982 + random.uniform(-0.01, 0.01),
                wisp_class="whisp-cyan"
            )
            all_entities.append(new_wisp)

        # Move everyone slightly (Pulse effect)
        for entity in all_entities:
            # We update the existing .lat and .lon instead of adding new ones
            entity.lat += random.uniform(-0.0001, 0.0001)
            entity.lon += random.uniform(-0.0001, 0.0001)

        save_to_db(all_entities)
        await asyncio.sleep(5)

# --- 5. STARTUP & ENDPOINTS ---
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(ghost_heartbeat())
    print("🚀 Spazz Engine: Online. Access at http://localhost:8001")

@app.get("/api/users")
def get_users():
    all_users = load_from_db()
    # Filter out shadow banned bots
    return [u for u in all_users if not u.is_shadow_banned]

@app.get("/", response_class=HTMLResponse)
async def read_index():
    try:
        with open("index.html", "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        return HTMLResponse(content=f"<h1>Engine Error: {str(e)}</h1>", status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
