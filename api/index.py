import json
import random
import os
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# --- 1. CONFIG & PATHS ---
# This ensures Vercel finds the DB inside the /api folder
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(BASE_DIR, 'users_db.json')

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
def save_to_db(users_list: List[User]):
    data = {"users": [u.model_dump() for u in users_list]}
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=4)

def load_from_db() -> List[User]:
    if not os.path.exists(DB_FILE):
        return []
    try:
        with open(DB_FILE, 'r') as f:
            data = json.load(f)
            user_data = data.get("users", [])
            return [User(**u) for u in user_data]
    except Exception as e:
        print(f"Error loading DB: {e}")
        return []

# --- 4. THE ENGINE (Movement logic moved inside the request) ---
def move_wisps(all_entities: List[User]):
    for entity in all_entities:
        if entity.type == "wisp":
            entity.lat += random.uniform(-0.0001, 0.0001)
            entity.lon += random.uniform(-0.0001, 0.0001)
    return all_entities

# --- 5. ENDPOINTS ---

@app.get("/api/users")
def get_users():
    all_entities = load_from_db()
    
    # Initialize Ben if the DB is empty or he's missing
    if not any(u.id == "user_ben" for u in all_entities):
        all_entities.append(User(
            id="user_ben", username="Ben", type="user",
            lat=39.333, lon=-82.982, credits=0
        ))
    
    # Populate ghosts if needed
    if len(all_entities) < 10:
        for i in range(30):
            new_id = f"gen_{random.randint(1000, 9999)}"
            # Randomly decide if this is a Wisp or a Potential Match
            is_match = random.random() > 0.7  # 30% chance it's a real person
            
            all_entities.append(User(
                id=new_id, 
                username="Potential Spazz" if is_match else "Wisp", 
                type="user" if is_match else "wisp", # 'user' type triggers the radar lock
                lat=39.333 + random.uniform(-0.015, 0.015), # Wider 30-mile scatter
                lon=-82.982 + random.uniform(-0.015, 0.015),
                gender="female" if is_match else "other",
                age=random.randint(19, 45) if is_match else 25,
                wisp_class="whisp-purple" if is_match else "whisp-cyan"
            ))
            
    # Move ghosts every time the radar is checked
    all_entities = move_wisps(all_entities)
    save_to_db(all_entities)
    
    return {
        "entities": [u for u in all_entities if not u.is_shadow_banned],
        "coach": "COACH: Be vewy vewy quiet... we hunting wisps." if random.random() > 0.5 else "COACH: Target detected. Stay frosty."
    }    

@app.post("/api/collect/{wisp_id}")
async def collect_wisp(wisp_id: str):
    all_entities = load_from_db()
    target_wisp = next((x for x in all_entities if x.id == wisp_id), None)
    user_ben = next((x for x in all_entities if x.id == "user_ben"), None)

    if target_wisp and user_ben:
        user_ben.credits += 15
        all_entities = [u for u in all_entities if u.id != wisp_id]
        save_to_db(all_entities)
        return {"new_balance": user_ben.credits, "status": "success"}
    
    return {"status": "failed", "message": "Target lost"}, 400

@app.get("/", response_class=HTMLResponse)
async def read_index():
    # Looking for index.html in the ROOT folder
    root_index = os.path.join(BASE_DIR, "..", "index.html")
    with open(root_index, "r", encoding="utf-8") as f:
        return f.read()