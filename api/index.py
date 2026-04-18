import json
import random
import os
import uuid
import hashlib
import hmac
import base64
import time
from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# ─────────────────────────────────────────
# 🔐 CONFIG
# ─────────────────────────────────────────
SECRET_KEY = os.environ.get("SPAZZ_SECRET", "spazz-dev-secret-change-in-prod")
ADMIN_IDS = {"user_ben"}  # these users see the radar map

# ─────────────────────────────────────────
# 🛰️ AI COACH TIPS
# ─────────────────────────────────────────
COACH_TIPS = [
    "Confidence is magnetic. Stand tall.",
    "First impressions are 90% visual. Fresh trim?",
    "Eye contact shows dominance and interest.",
    "Fitness is the ultimate multiplier. Hit the gym.",
    "COACH: Be vewy vewy quiet... we hunting wisps.",
    "COACH: Target detected. Stay frosty.",
    "Walk more. Wisps are out there.",
    "New area = new wisps. Explore.",
]

# ─────────────────────────────────────────
# 📁 DB PATHS
# ─────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(BASE_DIR, 'users_db.json')
AUTH_FILE = os.path.join(BASE_DIR, 'auth_db.json')

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────
# 📦 MODELS
# ─────────────────────────────────────────
class User(BaseModel):
    id: str
    username: str
    type: str       # "user" | "wisp" | "admin"
    lat: float
    lon: float
    credits: int = 0
    gender: str = "other"
    seeking: str = "everyone"
    is_premium: bool = False
    is_shadow_banned: bool = False
    age: int = 25
    wisp_class: Optional[str] = None
    online: bool = False

class AuthRecord(BaseModel):
    user_id: str
    username: str
    password_hash: str
    token: str
    created_at: float

class RegisterRequest(BaseModel):
    username: str
    password: str
    gender: str = "other"
    seeking: str = "everyone"
    age: int = 25

class LoginRequest(BaseModel):
    username: str
    password: str

class LocationUpdate(BaseModel):
    lat: float
    lon: float

class ChatMessage(BaseModel):
    to_user_id: str
    message: str

# ─────────────────────────────────────────
# 🔑 AUTH HELPERS
# ─────────────────────────────────────────
def hash_password(password: str) -> str:
    return hashlib.sha256((password + SECRET_KEY).encode()).hexdigest()

def make_token(user_id: str) -> str:
    payload = f"{user_id}:{time.time()}:{random.random()}"
    return base64.b64encode(hmac.new(SECRET_KEY.encode(), payload.encode(), hashlib.sha256).digest()).decode()

def load_auth() -> List[AuthRecord]:
    if not os.path.exists(AUTH_FILE):
        return []
    try:
        with open(AUTH_FILE, 'r') as f:
            data = json.load(f)
            return [AuthRecord(**r) for r in data.get("auth", [])]
    except:
        return []

def save_auth(records: List[AuthRecord]):
    with open(AUTH_FILE, 'w') as f:
        json.dump({"auth": [r.model_dump() for r in records]}, f, indent=2)

def get_auth_by_token(token: str) -> Optional[AuthRecord]:
    for r in load_auth():
        if r.token == token:
            return r
    return None

def get_current_user(request: Request) -> AuthRecord:
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    if not token:
        raise HTTPException(status_code=401, detail="No token")
    record = get_auth_by_token(token)
    if not record:
        raise HTTPException(status_code=401, detail="Invalid token")
    return record

# ─────────────────────────────────────────
# 🗄️ USER DB
# ─────────────────────────────────────────
def load_from_db() -> List[User]:
    if not os.path.exists(DB_FILE):
        return []
    try:
        with open(DB_FILE, 'r') as f:
            data = json.load(f)
            return [User(**u) for u in data.get("users", [])]
    except Exception as e:
        print(f"DB load error: {e}")
        return []

def save_to_db(users_list: List[User]):
    with open(DB_FILE, 'w') as f:
        json.dump({"users": [u.model_dump() for u in users_list]}, f, indent=2)

def move_wisps(entities: List[User]) -> List[User]:
    for e in entities:
        if e.type == "wisp":
            e.lat += random.uniform(-0.0001, 0.0001)
            e.lon += random.uniform(-0.0001, 0.0001)
    return entities

# ─────────────────────────────────────────
# 📨 CHAT DB (simple flat file)
# ─────────────────────────────────────────
CHAT_FILE = os.path.join(BASE_DIR, 'chat_db.json')

def load_messages():
    if not os.path.exists(CHAT_FILE):
        return []
    with open(CHAT_FILE, 'r') as f:
        return json.load(f).get("messages", [])

def save_messages(msgs):
    with open(CHAT_FILE, 'w') as f:
        json.dump({"messages": msgs}, f, indent=2)

# ─────────────────────────────────────────
# 🌐 ENDPOINTS
# ─────────────────────────────────────────

@app.post("/api/register")
async def register(req: RegisterRequest):
    auth_records = load_auth()
    if any(r.username.lower() == req.username.lower() for r in auth_records):
        raise HTTPException(status_code=400, detail="Username taken")

    user_id = f"user_{uuid.uuid4().hex[:8]}"
    token = make_token(user_id)

    # Create auth record
    auth_records.append(AuthRecord(
        user_id=user_id,
        username=req.username,
        password_hash=hash_password(req.password),
        token=token,
        created_at=time.time()
    ))
    save_auth(auth_records)

    # Create user record
    all_users = load_from_db()
    all_users.append(User(
        id=user_id,
        username=req.username,
        type="user",
        lat=39.333 + random.uniform(-0.01, 0.01),
        lon=-82.982 + random.uniform(-0.01, 0.01),
        gender=req.gender,
        seeking=req.seeking,
        age=req.age,
        credits=0,
        online=True
    ))
    save_to_db(all_users)

    return {"token": token, "user_id": user_id, "username": req.username, "is_admin": user_id in ADMIN_IDS}


@app.post("/api/login")
async def login(req: LoginRequest):
    auth_records = load_auth()
    record = next((r for r in auth_records if r.username.lower() == req.username.lower()), None)

    if not record or record.password_hash != hash_password(req.password):
        raise HTTPException(status_code=401, detail="Bad credentials")

    # Refresh token on login
    record.token = make_token(record.user_id)
    save_auth(auth_records)

    is_admin = record.user_id in ADMIN_IDS or record.username.lower() == "ben"
    return {"token": record.token, "user_id": record.user_id, "username": record.username, "is_admin": is_admin}


@app.post("/api/location")
async def update_location(loc: LocationUpdate, auth: AuthRecord = Depends(get_current_user)):
    all_users = load_from_db()
    for u in all_users:
        if u.id == auth.user_id:
            u.lat = loc.lat
            u.lon = loc.lon
            u.online = True
    save_to_db(all_users)
    return {"status": "ok"}


@app.get("/api/users")
async def get_users(auth: AuthRecord = Depends(get_current_user)):
    all_entities = load_from_db()
    is_admin = auth.user_id in ADMIN_IDS or auth.username.lower() == "ben"

    # Ensure ben exists
    if not any(u.id == "user_ben" for u in all_entities) and is_admin:
        all_entities.append(User(
            id="user_ben", username="Ben", type="admin",
            lat=39.333, lon=-82.982, credits=0,
            gender="male", seeking="female", online=True
        ))

    # Spawn wisps if needed
    wisps = [u for u in all_entities if u.type == "wisp"]
    if len(wisps) < 10:
        for _ in range(15):
            all_entities.append(User(
                id=f"wisp_{uuid.uuid4().hex[:6]}",
                username="Wisp", type="wisp",
                lat=39.333 + random.uniform(-0.02, 0.02),
                lon=-82.982 + random.uniform(-0.02, 0.02),
                wisp_class="whisp-cyan"
            ))

    all_entities = move_wisps(all_entities)
    save_to_db(all_entities)

    current_user = next((u for u in all_entities if u.id == auth.user_id), None)

    output = []
    for u in all_entities:
        if u.is_shadow_banned:
            continue
        u_dict = u.model_dump()
        u_dict["is_match"] = False

        if current_user and u.type == "user" and u.id != auth.user_id:
            if current_user.seeking == "everyone" or current_user.seeking == u.gender:
                u_dict["is_match"] = True

        # Non-admins: strip lat/lon from other real users (privacy)
        if not is_admin and u.type == "user" and u.id != auth.user_id:
            u_dict.pop("lat", None)
            u_dict.pop("lon", None)

        output.append(u_dict)

    return {
        "entities": output,
        "coach": random.choice(COACH_TIPS),
        "is_admin": is_admin
    }


@app.post("/api/collect/{target_id}")
async def collect_target(target_id: str, auth: AuthRecord = Depends(get_current_user)):
    all_entities = load_from_db()
    target = next((x for x in all_entities if x.id == target_id), None)
    current_user = next((x for x in all_entities if x.id == auth.user_id), None)

    if not target or not current_user:
        raise HTTPException(status_code=404, detail="Not found")

    reward = 15 if target.type == "wisp" else 5
    current_user.credits += reward

    if target.type == "wisp":
        all_entities = [u for u in all_entities if u.id != target_id]
    save_to_db(all_entities)
    return {"new_balance": current_user.credits, "reward": reward, "status": "success"}


@app.post("/api/chat/send")
async def send_message(msg: ChatMessage, auth: AuthRecord = Depends(get_current_user)):
    messages = load_messages()
    messages.append({
        "id": uuid.uuid4().hex,
        "from_id": auth.user_id,
        "from_username": auth.username,
        "to_id": msg.to_user_id,
        "message": msg.message,
        "timestamp": time.time()
    })
    save_messages(messages)
    return {"status": "sent"}


@app.get("/api/chat/inbox")
async def get_inbox(auth: AuthRecord = Depends(get_current_user)):
    messages = load_messages()
    # Get all messages involving this user
    mine = [m for m in messages if m["from_id"] == auth.user_id or m["to_id"] == auth.user_id]
    # Group by conversation partner
    convos = {}
    for m in mine:
        partner_id = m["to_id"] if m["from_id"] == auth.user_id else m["from_id"]
        partner_name = m["from_username"] if m["to_id"] == auth.user_id else "You"
        if partner_id not in convos:
            convos[partner_id] = {"partner_id": partner_id, "messages": []}
        convos[partner_id]["messages"].append(m)
    return {"conversations": list(convos.values())}


@app.post("/api/friends/add/{target_id}")
async def add_friend(target_id: str, auth: AuthRecord = Depends(get_current_user)):
    # Simple: just return success for now, extend with a friends_db later
    return {"status": "friend_request_sent", "to": target_id}


@app.get("/", response_class=HTMLResponse)
async def read_index():
    root_index = os.path.join(BASE_DIR, "..", "index.html")
    try:
        with open(root_index, "r", encoding="utf-8") as f:
            return f.read()
    except:
        return "Error: index.html not found."
