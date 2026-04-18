import json
import random
import os
import uuid
import hashlib
import hmac
import base64
import time
import math
from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

SECRET_KEY = os.environ.get("SPAZZ_SECRET", "spazz-dev-secret-change-in-prod")
ADMIN_IDS = {"user_ben"}

COACH_TIPS_LAZY = [
    "You've been still for a while. Wisps don't come to you.",
    "Every step is a chance. Get moving.",
    "Sitting burns almost nothing. Walk.",
    "Your next Wisp is closer than you think — but you have to move.",
]
COACH_TIPS_ACTIVE = [
    "You're crushing it. Keep the pace.",
    "Wisps love momentum. Don't stop now.",
    "Look alive — signal's heating up.",
    "You're in the zone. Chase it.",
    "That burn means you're earning it.",
]
COACH_TIPS_GENERAL = [
    "Confidence is magnetic. Stand tall.",
    "Eye contact shows dominance and interest.",
    "Fitness is the ultimate multiplier.",
    "COACH: Be vewy vewy quiet... we hunting wisps.",
    "New area = new wisps. Explore.",
    "10,000 steps a day changes everything.",
    "Every wisp you find is proof you showed up.",
]

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Vercel serverless: filesystem is read-only except /tmp
_DATA_DIR = '/tmp' if os.path.exists('/tmp') and not os.access(BASE_DIR, os.W_OK) else BASE_DIR
DB_FILE   = os.path.join(_DATA_DIR, 'users_db.json')
AUTH_FILE = os.path.join(_DATA_DIR, 'auth_db.json')
CHAT_FILE = os.path.join(_DATA_DIR, 'chat_db.json')

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── MODELS ──────────────────────────────
class User(BaseModel):
    id: str
    username: str
    type: str
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
    wisp_reward: int = 0  # credits this wisp drops when collected
    # Stats
    wisps_collected: int = 0
    steps: int = 0
    calories: float = 0.0
    distance_m: float = 0.0   # total meters walked
    last_lat: Optional[float] = None
    last_lon: Optional[float] = None
    last_seen: float = 0.0

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

# ── AUTH ─────────────────────────────────
def hash_password(p):
    return hashlib.sha256((p + SECRET_KEY).encode()).hexdigest()

def make_token(user_id):
    payload = f"{user_id}:{time.time()}:{random.random()}"
    return base64.b64encode(hmac.new(SECRET_KEY.encode(), payload.encode(), hashlib.sha256).digest()).decode()

def load_auth():
    if not os.path.exists(AUTH_FILE): return []
    try:
        with open(AUTH_FILE) as f:
            return [AuthRecord(**r) for r in json.load(f).get("auth", [])]
    except: return []

def save_auth(records):
    with open(AUTH_FILE, 'w') as f:
        json.dump({"auth": [r.model_dump() for r in records]}, f, indent=2)

def get_auth_by_token(token):
    for r in load_auth():
        if r.token == token: return r
    return None

def get_current_user(request: Request) -> AuthRecord:
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    if not token: raise HTTPException(401, "No token")
    record = get_auth_by_token(token)
    if not record: raise HTTPException(401, "Invalid token")
    return record

# ── DB ───────────────────────────────────
def load_from_db():
    if not os.path.exists(DB_FILE): return []
    try:
        with open(DB_FILE) as f:
            return [User(**u) for u in json.load(f).get("users", [])]
    except Exception as e:
        print(f"DB error: {e}"); return []

def save_to_db(users):
    with open(DB_FILE, 'w') as f:
        json.dump({"users": [u.model_dump() for u in users]}, f, indent=2)

def load_messages():
    if not os.path.exists(CHAT_FILE): return []
    with open(CHAT_FILE) as f: return json.load(f).get("messages", [])

def save_messages(msgs):
    with open(CHAT_FILE, 'w') as f: json.dump({"messages": msgs}, f, indent=2)

# ── GEO ──────────────────────────────────
def haversine(lat1, lon1, lat2, lon2):
    R = 6371e3
    dLat = (lat2-lat1)*math.pi/180
    dLon = (lon2-lon1)*math.pi/180
    a = math.sin(dLat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dLon/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def meters_to_steps(m): return int(m / 0.762)  # avg stride ~76.2cm
def meters_to_calories(m, age=25): return m * 0.06  # ~60 cal/km rough estimate

def move_wisps(entities):
    for e in entities:
        if e.type == "wisp":
            e.lat += random.uniform(-0.0001, 0.0001)
            e.lon += random.uniform(-0.0001, 0.0001)
    return entities

def near_any_user(wisp, users, threshold=0.05):
    return any(abs(wisp.lat - u.lat) < threshold and abs(wisp.lon - u.lon) < threshold for u in users)

def smart_coach_tip(user: User) -> str:
    # If user hasn't moved much recently, motivate
    if user.steps < 100:
        return random.choice(COACH_TIPS_LAZY)
    elif user.steps > 500:
        return random.choice(COACH_TIPS_ACTIVE)
    return random.choice(COACH_TIPS_GENERAL)

# ── ENDPOINTS ────────────────────────────

@app.post("/api/register")
async def register(req: RegisterRequest):
    auth_records = load_auth()
    if any(r.username.lower() == req.username.lower() for r in auth_records):
        raise HTTPException(400, "Username taken")
    user_id = f"user_{uuid.uuid4().hex[:8]}"
    token = make_token(user_id)
    auth_records.append(AuthRecord(user_id=user_id, username=req.username,
        password_hash=hash_password(req.password), token=token, created_at=time.time()))
    save_auth(auth_records)
    all_users = load_from_db()
    all_users.append(User(id=user_id, username=req.username, type="user",
        lat=39.333 + random.uniform(-0.01, 0.01),
        lon=-82.982 + random.uniform(-0.01, 0.01),
        gender=req.gender, seeking=req.seeking, age=req.age,
        credits=0, online=True, last_seen=time.time()))
    save_to_db(all_users)
    return {"token": token, "user_id": user_id, "username": req.username,
            "is_admin": user_id in ADMIN_IDS}

@app.post("/api/login")
async def login(req: LoginRequest):
    auth_records = load_auth()
    record = next((r for r in auth_records if r.username.lower() == req.username.lower()), None)
    if not record or record.password_hash != hash_password(req.password):
        raise HTTPException(401, "Bad credentials")
    record.token = make_token(record.user_id)
    save_auth(auth_records)
    is_admin = record.user_id in ADMIN_IDS or record.username.lower() == "ben"
    return {"token": record.token, "user_id": record.user_id,
            "username": record.username, "is_admin": is_admin}

@app.post("/api/location")
async def update_location(loc: LocationUpdate, auth: AuthRecord = Depends(get_current_user)):
    all_users = load_from_db()
    for u in all_users:
        if u.id == auth.user_id:
            # Calculate distance moved since last update
            if u.last_lat is not None and u.last_lon is not None:
                dist = haversine(u.last_lat, u.last_lon, loc.lat, loc.lon)
                # Filter out GPS jitter (< 3m) and teleports (> 500m)
                if 3 < dist < 500:
                    u.distance_m += dist
                    u.steps = meters_to_steps(u.distance_m)
                    u.calories = round(meters_to_calories(u.distance_m, u.age), 1)
            u.lat = loc.lat
            u.lon = loc.lon
            u.last_lat = loc.lat
            u.last_lon = loc.lon
            u.online = True
            u.last_seen = time.time()
    save_to_db(all_users)
    return {"status": "ok"}

@app.get("/api/users")
async def get_users(auth: AuthRecord = Depends(get_current_user)):
    all_entities = load_from_db()
    is_admin = auth.user_id in ADMIN_IDS or auth.username.lower() == "ben"

    if not any(u.id == "user_ben" for u in all_entities) and is_admin:
        all_entities.append(User(id="user_ben", username="Ben", type="admin",
            lat=39.333, lon=-82.982, credits=0, gender="male",
            seeking="female", online=True, last_seen=time.time()))

    online_users = [u for u in all_entities if u.type in ("user", "admin") and u.online]

    # Clean stale wisps
    if online_users:
        all_entities = [e for e in all_entities if e.type != "wisp" or near_any_user(e, online_users)]

    wisps = [u for u in all_entities if u.type == "wisp"]
    target_wisps = max(10, len(online_users) * 5)
    if len(wisps) < target_wisps and online_users:
        for _ in range(target_wisps - len(wisps)):
            anchor = random.choice(online_users)
            all_entities.append(User(
                id=f"wisp_{uuid.uuid4().hex[:6]}", username="Wisp", type="wisp",
                lat=anchor.lat + random.uniform(-0.02, 0.02),
                lon=anchor.lon + random.uniform(-0.02, 0.02),
                wisp_class="whisp-cyan",
                wisp_reward=random.choices(
                    [3, 5, 7, 10, 15, 20, 25],
                    weights=[30, 25, 20, 12, 7, 4, 2]  # common=small, rare=big
                )[0]))

    all_entities = move_wisps(all_entities)
    save_to_db(all_entities)

    current_user = next((u for u in all_entities if u.id == auth.user_id), None)
    coach_tip = smart_coach_tip(current_user) if current_user else random.choice(COACH_TIPS_GENERAL)

    output = []
    for u in all_entities:
        if u.is_shadow_banned: continue
        u_dict = u.model_dump()
        u_dict["is_match"] = False
        if current_user and u.type == "user" and u.id != auth.user_id:
            if current_user.seeking == "everyone" or current_user.seeking == u.gender:
                u_dict["is_match"] = True
        if not is_admin and u.type == "user" and u.id != auth.user_id:
            u_dict.pop("lat", None); u_dict.pop("lon", None)
        output.append(u_dict)

    return {"entities": output, "coach": coach_tip, "is_admin": is_admin}

@app.get("/api/stats")
async def get_stats(auth: AuthRecord = Depends(get_current_user)):
    all_users = load_from_db()
    me = next((u for u in all_users if u.id == auth.user_id), None)
    if not me: raise HTTPException(404, "User not found")
    return {
        "steps": me.steps,
        "calories": me.calories,
        "distance_m": round(me.distance_m),
        "wisps_collected": me.wisps_collected,
        "credits": me.credits
    }

@app.get("/api/leaderboard")
async def leaderboard(auth: AuthRecord = Depends(get_current_user)):
    all_users = load_from_db()
    real_users = [u for u in all_users if u.type in ("user", "admin") and not u.is_shadow_banned]
    # Sort by wisps collected desc, steps as tiebreaker
    ranked = sorted(real_users, key=lambda u: (u.wisps_collected, u.steps), reverse=True)
    return {"leaderboard": [
        {"rank": i+1, "username": u.username, "wisps": u.wisps_collected,
         "steps": u.steps, "credits": u.credits, "is_me": u.id == auth.user_id}
        for i, u in enumerate(ranked[:20])
    ]}

@app.post("/api/collect/{target_id}")
async def collect_target(target_id: str, auth: AuthRecord = Depends(get_current_user)):
    all_entities = load_from_db()
    target = next((x for x in all_entities if x.id == target_id), None)
    current_user = next((x for x in all_entities if x.id == auth.user_id), None)
    if not target or not current_user: raise HTTPException(404, "Not found")
    reward = target.wisp_reward if target.type == "wisp" and target.wisp_reward > 0 else (random.randint(3,10) if target.type == "wisp" else 5)
    current_user.credits += reward
    if target.type == "wisp":
        current_user.wisps_collected += 1
        all_entities = [u for u in all_entities if u.id != target_id]
    save_to_db(all_entities)
    return {"new_balance": current_user.credits, "reward": reward,
            "wisps_collected": current_user.wisps_collected, "status": "success"}

@app.post("/api/chat/send")
async def send_message(msg: ChatMessage, auth: AuthRecord = Depends(get_current_user)):
    messages = load_messages()
    messages.append({"id": uuid.uuid4().hex, "from_id": auth.user_id,
        "from_username": auth.username, "to_id": msg.to_user_id,
        "message": msg.message, "timestamp": time.time()})
    save_messages(messages)
    return {"status": "sent"}

@app.get("/api/chat/inbox")
async def get_inbox(auth: AuthRecord = Depends(get_current_user)):
    messages = load_messages()
    mine = [m for m in messages if m["from_id"] == auth.user_id or m["to_id"] == auth.user_id]
    convos = {}
    for m in mine:
        partner_id = m["to_id"] if m["from_id"] == auth.user_id else m["from_id"]
        if partner_id not in convos: convos[partner_id] = {"partner_id": partner_id, "messages": []}
        convos[partner_id]["messages"].append(m)
    return {"conversations": list(convos.values())}

@app.post("/api/friends/add/{target_id}")
async def add_friend(target_id: str, auth: AuthRecord = Depends(get_current_user)):
    return {"status": "friend_request_sent", "to": target_id}

@app.get("/", response_class=HTMLResponse)
async def read_index():
    root_index = os.path.join(BASE_DIR, "..", "index.html")
    try:
        with open(root_index, "r", encoding="utf-8") as f: return f.read()
    except: return "Error: index.html not found."

# ─────────────────────────────────────────
# 🛍️ SHOP CATALOG
# ─────────────────────────────────────────
SHOP_ITEMS = [
    # Backgrounds
    {"id":"bg_neon_city",   "type":"background","name":"Neon City",      "desc":"Purple/cyan cityscape",          "price":120, "preview":"#1a0033","premium":False},
    {"id":"bg_void",        "type":"background","name":"The Void",        "desc":"Deep black with star particles", "price":180, "preview":"#000005","premium":False},
    {"id":"bg_lava",        "type":"background","name":"Lava Grid",       "desc":"Red hot grid lines",             "price":250, "preview":"#330000","premium":False},
    {"id":"bg_aurora",      "type":"background","name":"Aurora",          "desc":"Northern lights shimmer",        "price":400, "preview":"#001a1a","premium":True},
    {"id":"bg_matrix",      "type":"background","name":"Matrix Rain",     "desc":"Green code rain",                "price":600, "preview":"#001000","premium":True},
    # Ping sounds
    {"id":"ping_chime",     "type":"ping","name":"Crystal Chime",  "desc":"Clean bell tone",           "price":75,  "preview":"🔔","premium":False},
    {"id":"ping_zap",       "type":"ping","name":"Zap",            "desc":"Electric crackle",          "price":100, "preview":"⚡","premium":False},
    {"id":"ping_blip",      "type":"ping","name":"Retro Blip",     "desc":"8-bit classic",             "price":75,  "preview":"🎮","premium":False},
    {"id":"ping_whoosh",    "type":"ping","name":"Whoosh",         "desc":"Sweeping air sound",        "price":200, "preview":"💨","premium":True},
    {"id":"ping_heartbeat", "type":"ping","name":"Heartbeat",      "desc":"Pulse thump",               "price":250, "preview":"💓","premium":True},
    # Flash designs
    {"id":"flash_lightning","type":"flash","name":"Lightning",    "desc":"Yellow bolt flash",         "price":90,  "preview":"⚡","premium":False},
    {"id":"flash_ripple",   "type":"flash","name":"Ripple",       "desc":"Expanding ring pulse",      "price":120, "preview":"🌊","premium":False},
    {"id":"flash_fire",     "type":"flash","name":"Fire",         "desc":"Orange flame burst",        "price":200, "preview":"🔥","premium":False},
    {"id":"flash_galaxy",   "type":"flash","name":"Galaxy Spin",  "desc":"Spiral star explosion",     "price":450, "preview":"🌀","premium":True},
    {"id":"flash_glitch",   "type":"flash","name":"Glitch",       "desc":"Digital distortion",        "price":350, "preview":"📺","premium":True},
]

SUBSCRIPTION_PRICE = 299  # credits/month

PREMIUM_COACH_TIPS = {
    "dating": [
        "Make eye contact for 3 seconds, look away, repeat. It's magnetic.",
        "Ask questions you actually want the answer to. Curiosity is attractive.",
        "Tease lightly. Playfulness signals confidence.",
        "Don't check your phone when talking to someone interesting.",
        "Your posture says more than your words. Shoulders back.",
        "The best opener is just: be genuinely interested in them.",
        "Smile with your eyes. People feel that before they hear you.",
    ],
    "fitness": [
        "10,000 steps = ~500 calories. You're basically doing cardio by playing Spazz.",
        "Walking pace matters. Push it slightly faster than comfortable.",
        "Consistency beats intensity. Showing up every day wins.",
        "Your body adapts fast. Add hills or stairs when flat gets easy.",
        "Hydrate before you're thirsty. Thirst is already dehydration.",
        "Sleep is the most underrated fitness tool. Protect it.",
        "Zone 2 cardio (moderate walk) burns fat most efficiently.",
    ],
    "motivation": [
        "You showed up today. That already puts you ahead of most.",
        "Discipline is just doing the thing even when you don't feel like it.",
        "The version of you 6 months from now will thank you.",
        "Small actions compounded. Every wisp counts.",
        "Nobody remembers the days you stayed home.",
        "Your comfort zone is a cage with no lock. Walk out.",
        "Energy creates energy. The more you move, the more you want to.",
    ]
}

HOTSPOTS_FILE = os.path.join(_DATA_DIR, 'hotspots_db.json')
INVENTORY_FILE = os.path.join(_DATA_DIR, 'inventory_db.json')

def load_hotspots():
    if not os.path.exists(HOTSPOTS_FILE): return []
    with open(HOTSPOTS_FILE) as f: return json.load(f).get("hotspots", [])

def save_hotspots(spots):
    with open(HOTSPOTS_FILE, 'w') as f: json.dump({"hotspots": spots}, f, indent=2)

def load_inventory():
    if not os.path.exists(INVENTORY_FILE): return {}
    with open(INVENTORY_FILE) as f: return json.load(f)

def save_inventory(inv):
    with open(INVENTORY_FILE, 'w') as f: json.dump(inv, f, indent=2)

def get_user_inventory(user_id):
    inv = load_inventory()
    return inv.get(user_id, {"owned": [], "equipped": {}, "is_premium": False, "premium_until": 0})

def save_user_inventory(user_id, data):
    inv = load_inventory()
    inv[user_id] = data
    save_inventory(inv)

# ─────────────────────────────────────────
# 🛍️ SHOP ENDPOINTS
# ─────────────────────────────────────────

@app.get("/api/shop")
async def get_shop(auth: AuthRecord = Depends(get_current_user)):
    inv = get_user_inventory(auth.user_id)
    items = []
    for item in SHOP_ITEMS:
        i = dict(item)
        i["owned"] = item["id"] in inv.get("owned", [])
        i["equipped"] = inv.get("equipped", {}).get(item["type"]) == item["id"]
        items.append(i)
    return {"items": items, "equipped": inv.get("equipped", {}), "is_premium": inv.get("is_premium", False)}

@app.post("/api/shop/buy/{item_id}")
async def buy_item(item_id: str, auth: AuthRecord = Depends(get_current_user)):
    item = next((i for i in SHOP_ITEMS if i["id"] == item_id), None)
    if not item: raise HTTPException(404, "Item not found")

    inv = get_user_inventory(auth.user_id)
    if item["id"] in inv.get("owned", []):
        raise HTTPException(400, "Already owned")

    if item.get("premium") and not inv.get("is_premium"):
        raise HTTPException(403, "Premium required")

    all_users = load_from_db()
    user = next((u for u in all_users if u.id == auth.user_id), None)
    if not user: raise HTTPException(404, "User not found")
    if user.credits < item["price"]:
        raise HTTPException(400, f"Need {item['price']} credits, you have {user.credits}")

    user.credits -= item["price"]
    save_to_db(all_users)
    inv.setdefault("owned", []).append(item_id)
    save_user_inventory(auth.user_id, inv)
    return {"status": "purchased", "new_balance": user.credits, "item": item}

@app.post("/api/shop/equip/{item_id}")
async def equip_item(item_id: str, auth: AuthRecord = Depends(get_current_user)):
    item = next((i for i in SHOP_ITEMS if i["id"] == item_id), None)
    if not item: raise HTTPException(404, "Item not found")
    inv = get_user_inventory(auth.user_id)
    if item_id not in inv.get("owned", []):
        raise HTTPException(403, "Not owned")
    inv.setdefault("equipped", {})[item["type"]] = item_id
    save_user_inventory(auth.user_id, inv)
    return {"status": "equipped", "equipped": inv["equipped"]}

@app.post("/api/subscribe")
async def subscribe(auth: AuthRecord = Depends(get_current_user)):
    all_users = load_from_db()
    user = next((u for u in all_users if u.id == auth.user_id), None)
    if not user: raise HTTPException(404, "Not found")
    if user.credits < SUBSCRIPTION_PRICE:
        raise HTTPException(400, f"Need {SUBSCRIPTION_PRICE} credits")
    user.credits -= SUBSCRIPTION_PRICE
    save_to_db(all_users)
    inv = get_user_inventory(auth.user_id)
    inv["is_premium"] = True
    inv["premium_until"] = time.time() + (30 * 24 * 3600)
    save_user_inventory(auth.user_id, inv)
    return {"status": "subscribed", "new_balance": user.credits, "premium_until": inv["premium_until"]}

@app.get("/api/coach/premium")
async def premium_coach(category: str = "motivation", auth: AuthRecord = Depends(get_current_user)):
    inv = get_user_inventory(auth.user_id)
    if not inv.get("is_premium"):
        raise HTTPException(403, "Premium required")
    tips = PREMIUM_COACH_TIPS.get(category, PREMIUM_COACH_TIPS["motivation"])
    return {"tip": random.choice(tips), "category": category}

# ─────────────────────────────────────────
# 📍 HOTSPOTS
# ─────────────────────────────────────────

@app.get("/api/hotspots")
async def get_hotspots(auth: AuthRecord = Depends(get_current_user)):
    inv = get_user_inventory(auth.user_id)
    if not inv.get("is_premium"):
        raise HTTPException(403, "Premium required to see hotspots")
    spots = load_hotspots()
    # Auto-seed example hotspots if none exist
    if not spots:
        spots = [
            {"id":"hs_1","name":"The Grid Bar","type":"bar","lat":39.335,"lon":-82.980,"vibe":"High energy Friday nights","active_users":12},
            {"id":"hs_2","name":"Yoctangee Park","type":"park","lat":39.338,"lon":-82.979,"vibe":"Morning walkers, wisp hotzone","active_users":8},
            {"id":"hs_3","name":"Coffee House","type":"cafe","lat":39.331,"lon":-82.984,"vibe":"Chill, good for meetups","active_users":5},
        ]
        save_hotspots(spots)
    return {"hotspots": spots}

@app.post("/api/hotspots/checkin/{spot_id}")
async def checkin_hotspot(spot_id: str, auth: AuthRecord = Depends(get_current_user)):
    inv = get_user_inventory(auth.user_id)
    if not inv.get("is_premium"): raise HTTPException(403, "Premium required")
    spots = load_hotspots()
    spot = next((s for s in spots if s["id"] == spot_id), None)
    if not spot: raise HTTPException(404, "Spot not found")
    spot["active_users"] = spot.get("active_users", 0) + 1
    save_hotspots(spots)
    return {"status": "checked_in", "spot": spot}
