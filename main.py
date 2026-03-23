import math
import json
import asyncio
import random
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()
from fastapi.staticfiles import StaticFiles

# This tells FastAPI to serve everything in the 'static' folder
app.mount("/static", StaticFiles(directory="static"), name="static")

# Enable CORS so the HTML file can talk to the backend
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

    def to_dict(self):
        return self.dict()

# --- 2. DATABASE TOOLS ---
DB_FILE = 'users_db.json'

def save_to_db(users_list: List[User]):
    data = {"users": [u.to_dict() for u in users_list]}
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=4)

def load_from_db() -> List[User]:
    try:
        with open(DB_FILE, 'r') as f:
            data = json.load(f)
            return [User(**u) for u in data["users"]]
    except (FileNotFoundError, json.JSONDecodeError):
        return []

# --- 3. HELPER FUNCTIONS ---
def create_entity(entity_id, username, e_type="user", lat=0.0, lon=0.0, age=25, gender="male", looking_for="any", is_premium=False):
    if age < 18:
        raise ValueError("Age Shield: User must be 18+")
    
    shadow_flag = False
    if "bot" in username.lower() or "spam" in username.lower():
        shadow_flag = True

    return User(
        id=str(entity_id),
        username=username,
        type=e_type,
        lat=lat,
        lon=lon,
        age=age,
        gender=gender,
        looking_for=looking_for,
        is_premium=is_premium,
        is_shadow_banned=shadow_flag
    )

def calculate_distance(lat1, lon1, lat2, lon2):
    R = 3958.8 # Miles
    dlat, dlon = math.radians(lat2-lat1), math.radians(lon2-lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * (2 * math.atan2(math.sqrt(a), math.sqrt(1-a)))

# --- 4. THE HEARTBEAT ---
async def ghost_heartbeat():
    print("💓 Ghost Heartbeat pumping on the Legion i9...")
    while True:
        all_entities = load_from_db()
        if len(all_entities) < 10:
            new_wisp = create_entity(f"wisp_{random.randint(1,999)}", "Wisp", "wisp", 34.052 + random.uniform(-0.01, 0.01), -118.243 + random.uniform(-0.01, 0.01))
            all_entities.append(new_wisp)

        for entity in all_entities:
            if entity.type != "player":
                entity.lat += random.uniform(-0.0002, 0.0002)
                entity.lon += random.uniform(-0.0002, 0.0002)

        save_to_db(all_entities)
        await asyncio.sleep(5)

# --- 5. STARTUP & ENDPOINTS ---
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(ghost_heartbeat())
    print("🚀 Spazz Engine: Online.")

# --- UPDATE THE API USERS ROUTE ---
@app.get("/api/users")
def get_users():
    # Load users from the JSON DB
    all_users = load_from_db()
    # Pydantic models in V2 use .model_dump() instead of .to_dict()
    # Or simply return the list and let FastAPI handle the JSON conversion automatically
    return [u for u in all_users if not getattr(u, 'is_shadow_banned', False)]

# --- UPDATE THE INDEX ROUTE ---
@app.get("/", response_class=HTMLResponse)
async def read_index():
    try:
        with open("index.html", "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        # If it still fails, this will tell us exactly WHY in the browser
        return HTMLResponse(content=f"<h1>Engine Error: {str(e)}</h1>", status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
