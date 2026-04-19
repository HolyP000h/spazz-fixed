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
from supabase import create_client, Client

app = FastAPI()

SECRET_KEY = os.environ.get("SPAZZ_SECRET", "spazz-dev-secret-change-in-prod")
ADMIN_IDS = {"user_ben"}

# ── SUPABASE ─────────────────────────────
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://kytmktshrywvxigobsxd.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5dG1rdHNocnl3dnhpZ29ic3hkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjUzOTcyNCwiZXhwIjoyMDkyMTE1NzI0fQ.qif-2FCGwVcwblZWekM-M_221wfGi6PtBHbdlFrbtvo")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

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

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── MODELS ──────────────────────────────
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

def get_auth_by_token(token):
    try:
        result = supabase.table("users").select("*").eq("token", token).limit(1).execute()
        if result.data:
            return result.data[0]
        return None
    except:
        return None

def get_current_user(request: Request):
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    if not token:
        raise HTTPException(401, "No token")
    user = get_auth_by_token(token)
    if not user:
        raise HTTPException(401, "Invalid token")
    return user

# ── GEO ──────────────────────────────────
def haversine(lat1, lon1, lat2, lon2):
    R = 6371e3
    dLat = (lat2 - lat1) * math.pi / 180
    dLon = (lon2 - lon1) * math.pi / 180
    a = math.sin(dLat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dLon/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def meters_to_steps(m): return int(m / 0.762)
def meters_to_calories(m, age=25): return m * 0.06

def smart_coach_tip(user) -> str:
    steps = user.get("steps", 0) if isinstance(user, dict) else 0
    if steps < 100:
        return random.choice(COACH_TIPS_LAZY)
    elif steps > 500:
        return random.choice(COACH_TIPS_ACTIVE)
    return random.choice(COACH_TIPS_GENERAL)

# ── WISPS (in-memory per instance, Vercel ephemeral) ──────────────
_wisps = {}

def get_wisps():
    return list(_wisps.values())

def add_wisp(wisp):
    _wisps[wisp["id"]] = wisp

def remove_wisp(wisp_id):
    _wisps.pop(wisp_id, None)

def move_wisps():
    for w in _wisps.values():
        w["lat"] += random.uniform(-0.0001, 0.0001)
        w["lon"] += random.uniform(-0.0001, 0.0001)

# ── ENDPOINTS ────────────────────────────

@app.post("/api/register")
async def register(req: RegisterRequest):
    # Check username taken
    existing = supabase.table("users").select("id").eq("username", req.username).execute()
    if existing.data:
        raise HTTPException(400, "Username taken")

    user_id = f"user_{uuid.uuid4().hex[:8]}"
    token = make_token(user_id)

    supabase.table("users").insert({
        "id": user_id,
        "username": req.username,
        "password_hash": hash_password(req.password),
        "token": token,
        "age": req.age,
        "gender": req.gender,
        "seeking": req.seeking,
        "steps": 0,
        "wisp_coins": 0,
        "level": 1,
        "xp": 0,
        "is_admin": False,
        "is_premium": False,
    }).execute()

    return {"token": token, "user_id": user_id, "username": req.username, "is_admin": False}

@app.post("/api/login")
async def login(req: LoginRequest):
    result = supabase.table("users").select("*").eq("username", req.username).limit(1).execute()
    if not result.data:
        raise HTTPException(401, "Bad credentials")
    user = result.data[0]
    if user["password_hash"] != hash_password(req.password):
        raise HTTPException(401, "Bad credentials")

    token = make_token(user["id"])
    supabase.table("users").update({"token": token}).eq("id", user["id"]).execute()

    is_admin = user["id"] in ADMIN_IDS or user["username"].lower() == "ben"
    return {"token": token, "user_id": user["id"], "username": user["username"], "is_admin": is_admin}

@app.post("/api/location")
async def update_location(loc: LocationUpdate, auth=Depends(get_current_user)):
    user = auth
    last_lat = user.get("last_lat")
    last_lon = user.get("last_lon")
    distance_m = user.get("distance_m", 0) or 0

    if last_lat and last_lon:
        dist = haversine(float(last_lat), float(last_lon), loc.lat, loc.lon)
        if 3 < dist < 500:
            distance_m += dist

    steps = meters_to_steps(distance_m)
    calories = round(meters_to_calories(distance_m, user.get("age", 25)), 1)

    supabase.table("users").update({
        "lat": loc.lat,
        "lon": loc.lon,
        "last_lat": loc.lat,
        "last_lon": loc.lon,
        "distance_m": distance_m,
        "steps": steps,
        "calories": calories,
        "online": True,
        "last_seen": time.time()
    }).eq("id", user["id"]).execute()

    return {"status": "ok", "steps": steps, "calories": calories}

@app.get("/api/users")
async def get_users(auth=Depends(get_current_user)):
    is_admin = auth["id"] in ADMIN_IDS or auth["username"].lower() == "ben"

    # Get online users from Supabase
    result = supabase.table("users").select("*").eq("online", True).execute()
    online_users = result.data or []

    # Manage wisps in memory
    move_wisps()
    wisps = get_wisps()
    target_wisps = max(10, len(online_users) * 5)

    if len(wisps) < target_wisps and online_users:
        for _ in range(target_wisps - len(wisps)):
            anchor = random.choice(online_users)
            wisp = {
                "id": f"wisp_{uuid.uuid4().hex[:6]}",
                "username": "Wisp",
                "type": "wisp",
                "lat": anchor["lat"] + random.uniform(-0.02, 0.02) if anchor.get("lat") else 39.333 + random.uniform(-0.02, 0.02),
                "lon": anchor["lon"] + random.uniform(-0.02, 0.02) if anchor.get("lon") else -82.982 + random.uniform(-0.02, 0.02),
                "wisp_class": "whisp-cyan",
                "wisp_reward": random.choices([3, 5, 7, 10, 15, 20, 25], weights=[30, 25, 20, 12, 7, 4, 2])[0]
            }
            add_wisp(wisp)

    current_user = auth
    coach_tip = smart_coach_tip(current_user)

    entities = []
    for u in online_users:
        if u["id"] != auth["id"]:
            entities.append({
                "id": u["id"], "username": u["username"], "type": "user",
                "lat": u.get("lat", 0), "lon": u.get("lon", 0),
                "gender": u.get("gender", "other"), "age": u.get("age", 25),
                "is_premium": u.get("is_premium", False)
            })

    entities += get_wisps()

    return {
        "entities": entities,
        "me": {
            "id": current_user["id"],
            "username": current_user["username"],
            "steps": current_user.get("steps", 0),
            "calories": current_user.get("calories", 0),
            "distance_m": current_user.get("distance_m", 0),
            "credits": current_user.get("wisp_coins", 0),
            "wisps_collected": current_user.get("xp", 0),
            "level": current_user.get("level", 1),
            "is_premium": current_user.get("is_premium", False),
        },
        "coach_tip": coach_tip,
        "is_admin": is_admin,
    }

@app.get("/api/me")
async def get_me(auth=Depends(get_current_user)):
    return {
        "id": auth["id"],
        "username": auth["username"],
        "steps": auth.get("steps", 0),
        "calories": auth.get("calories", 0),
        "distance_m": auth.get("distance_m", 0),
        "wisps_collected": auth.get("xp", 0),
        "credits": auth.get("wisp_coins", 0),
        "level": auth.get("level", 1),
        "is_premium": auth.get("is_premium", False),
    }

@app.get("/api/leaderboard")
async def leaderboard(auth=Depends(get_current_user)):
    result = supabase.table("users").select("id,username,xp,steps,wisp_coins").order("xp", desc=True).limit(20).execute()
    users = result.data or []
    return {"leaderboard": [
        {"rank": i+1, "username": u["username"], "wisps": u.get("xp", 0),
         "steps": u.get("steps", 0), "credits": u.get("wisp_coins", 0),
         "is_me": u["id"] == auth["id"]}
        for i, u in enumerate(users)
    ]}

@app.post("/api/collect/{target_id}")
async def collect_target(target_id: str, auth=Depends(get_current_user)):
    wisp = _wisps.get(target_id)
    if not wisp:
        raise HTTPException(404, "Wisp not found or already collected")

    reward = wisp.get("wisp_reward", random.randint(3, 10))
    remove_wisp(target_id)

    # Update user stats in Supabase
    user = auth
    new_coins = (user.get("wisp_coins", 0) or 0) + reward
    new_xp = (user.get("xp", 0) or 0) + 1
    new_level = max(1, new_xp // 10 + 1)

    supabase.table("users").update({
        "wisp_coins": new_coins,
        "xp": new_xp,
        "level": new_level
    }).eq("id", auth["id"]).execute()

    return {"new_balance": new_coins, "reward": reward, "wisps_collected": new_xp, "status": "success"}

@app.post("/api/chat/send")
async def send_message(msg: ChatMessage, auth=Depends(get_current_user)):
    supabase.table("chat_messages").insert({
        "user_id": auth["id"],
        "username": auth["username"],
        "to_user_id": msg.to_user_id,
        "message": msg.message
    }).execute()
    return {"status": "sent"}

@app.get("/api/chat/inbox")
async def get_inbox(auth=Depends(get_current_user)):
    sent = supabase.table("chat_messages").select("*").eq("user_id", auth["id"]).execute().data or []
    received = supabase.table("chat_messages").select("*").eq("to_user_id", auth["id"]).execute().data or []
    all_msgs = sent + received
    convos = {}
    for m in all_msgs:
        partner_id = m["to_user_id"] if m["user_id"] == auth["id"] else m["user_id"]
        if partner_id not in convos:
            convos[partner_id] = {"partner_id": partner_id, "messages": []}
        convos[partner_id]["messages"].append(m)
    return {"conversations": list(convos.values())}

@app.get("/", response_class=HTMLResponse)
async def read_index():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    root_index = os.path.join(BASE_DIR, "..", "index.html")
    try:
        with open(root_index, "r", encoding="utf-8") as f:
            return f.read()
    except:
        return "Error: index.html not found."

# ─────────────────────────────────────────
# 🛍️ SHOP CATALOG
# ─────────────────────────────────────────
SHOP_ITEMS = [
    {"id":"bg_neon_city",   "type":"background","name":"Neon City",      "desc":"Purple/cyan cityscape",          "price":120, "preview":"#1a0033","premium":False},
    {"id":"bg_void",        "type":"background","name":"The Void",        "desc":"Deep black with star particles", "price":180, "preview":"#000005","premium":False},
    {"id":"bg_lava",        "type":"background","name":"Lava Grid",       "desc":"Red hot grid lines",             "price":250, "preview":"#330000","premium":False},
    {"id":"bg_aurora",      "type":"background","name":"Aurora",          "desc":"Northern lights shimmer",        "price":400, "preview":"#001a1a","premium":True},
    {"id":"bg_matrix",      "type":"background","name":"Matrix Rain",     "desc":"Green code rain",                "price":600, "preview":"#001000","premium":True},
    {"id":"ping_chime",     "type":"ping","name":"Crystal Chime",  "desc":"Clean bell tone",           "price":75,  "preview":"🔔","premium":False},
    {"id":"ping_zap",       "type":"ping","name":"Zap",            "desc":"Electric crackle",          "price":100, "preview":"⚡","premium":False},
    {"id":"ping_blip",      "type":"ping","name":"Retro Blip",     "desc":"8-bit classic",             "price":75,  "preview":"🎮","premium":False},
    {"id":"ping_whoosh",    "type":"ping","name":"Whoosh",         "desc":"Sweeping air sound",        "price":200, "preview":"💨","premium":True},
    {"id":"ping_heartbeat", "type":"ping","name":"Heartbeat",      "desc":"Pulse thump",               "price":250, "preview":"💓","premium":True},
    {"id":"flash_lightning","type":"flash","name":"Lightning",    "desc":"Yellow bolt flash",         "price":90,  "preview":"⚡","premium":False},
    {"id":"flash_ripple",   "type":"flash","name":"Ripple",       "desc":"Expanding ring pulse",      "price":120, "preview":"🌊","premium":False},
    {"id":"flash_fire",     "type":"flash","name":"Fire",         "desc":"Orange flame burst",        "price":200, "preview":"🔥","premium":False},
    {"id":"flash_galaxy",   "type":"flash","name":"Galaxy Spin",  "desc":"Spiral star explosion",     "price":450, "preview":"🌀","premium":True},
    {"id":"flash_glitch",   "type":"flash","name":"Glitch",       "desc":"Digital distortion",        "price":350, "preview":"📺","premium":True},
]

PREMIUM_COACH_TIPS = {
    "dating": [
        "Make eye contact for 3 seconds, look away, repeat. It's magnetic.",
        "Ask questions you actually want the answer to. Curiosity is attractive.",
        "Tease lightly. Playfulness signals confidence.",
        "Don't check your phone when talking to someone interesting.",
        "Your posture says more than your words. Shoulders back.",
    ],
    "fitness": [
        "10,000 steps = ~500 calories. You're basically doing cardio by playing Spazz.",
        "Walking pace matters. Push it slightly faster than comfortable.",
        "Consistency beats intensity. Showing up every day wins.",
        "Hydrate before you're thirsty. Thirst is already dehydration.",
        "Zone 2 cardio (moderate walk) burns fat most efficiently.",
    ],
    "motivation": [
        "You showed up today. That already puts you ahead of most.",
        "Discipline is just doing the thing even when you don't feel like it.",
        "The version of you 6 months from now will thank you.",
        "Small actions compounded. Every wisp counts.",
        "Energy creates energy. The more you move, the more you want to.",
    ]
}

@app.get("/api/shop")
async def get_shop(auth=Depends(get_current_user)):
    inv_result = supabase.table("inventory").select("*").eq("user_id", auth["id"]).execute()
    owned_ids = [r["item_name"] for r in (inv_result.data or [])]
    equipped_result = supabase.table("inventory").select("*").eq("user_id", auth["id"]).eq("item_type", "equipped").execute()
    equipped = {}
    for r in (equipped_result.data or []):
        equipped[r.get("item_category", "")] = r["item_name"]

    items = []
    for item in SHOP_ITEMS:
        i = dict(item)
        i["owned"] = item["id"] in owned_ids
        i["equipped"] = equipped.get(item["type"]) == item["id"]
        items.append(i)
    return {"items": items, "equipped": equipped, "is_premium": auth.get("is_premium", False)}

@app.post("/api/shop/buy/{item_id}")
async def buy_item(item_id: str, auth=Depends(get_current_user)):
    item = next((i for i in SHOP_ITEMS if i["id"] == item_id), None)
    if not item:
        raise HTTPException(404, "Item not found")

    inv_result = supabase.table("inventory").select("item_name").eq("user_id", auth["id"]).execute()
    owned_ids = [r["item_name"] for r in (inv_result.data or [])]
    if item_id in owned_ids:
        raise HTTPException(400, "Already owned")

    if item.get("premium") and not auth.get("is_premium"):
        raise HTTPException(403, "Premium required")

    user_result = supabase.table("users").select("wisp_coins").eq("id", auth["id"]).execute()
    coins = user_result.data[0]["wisp_coins"] if user_result.data else 0
    if coins < item["price"]:
        raise HTTPException(400, f"Need {item['price']} coins, you have {coins}")

    supabase.table("users").update({"wisp_coins": coins - item["price"]}).eq("id", auth["id"]).execute()
    supabase.table("inventory").insert({
        "user_id": auth["id"],
        "item_name": item_id,
        "item_type": "owned"
    }).execute()

    return {"status": "purchased", "new_balance": coins - item["price"], "item": item}

@app.post("/api/shop/equip/{item_id}")
async def equip_item(item_id: str, auth=Depends(get_current_user)):
    item = next((i for i in SHOP_ITEMS if i["id"] == item_id), None)
    if not item:
        raise HTTPException(404, "Item not found")

    inv_result = supabase.table("inventory").select("item_name").eq("user_id", auth["id"]).execute()
    owned_ids = [r["item_name"] for r in (inv_result.data or [])]
    if item_id not in owned_ids:
        raise HTTPException(403, "Not owned")

    # Remove old equipped of same type
    supabase.table("inventory").delete().eq("user_id", auth["id"]).eq("item_type", "equipped").eq("item_category", item["type"]).execute()
    supabase.table("inventory").insert({
        "user_id": auth["id"],
        "item_name": item_id,
        "item_type": "equipped",
        "item_category": item["type"]
    }).execute()

    return {"status": "equipped", "item_id": item_id}

@app.post("/api/premium/subscribe")
async def subscribe_premium(auth=Depends(get_current_user)):
    user_result = supabase.table("users").select("wisp_coins,is_premium").eq("id", auth["id"]).execute()
    if not user_result.data:
        raise HTTPException(404, "User not found")
    user = user_result.data[0]
    SUBSCRIPTION_PRICE = 299
    if user["wisp_coins"] < SUBSCRIPTION_PRICE:
        raise HTTPException(400, f"Need {SUBSCRIPTION_PRICE} coins")
    supabase.table("users").update({
        "wisp_coins": user["wisp_coins"] - SUBSCRIPTION_PRICE,
        "is_premium": True
    }).eq("id", auth["id"]).execute()
    return {"status": "subscribed", "new_balance": user["wisp_coins"] - SUBSCRIPTION_PRICE}

@app.get("/api/premium/tips")
async def premium_tips(auth=Depends(get_current_user)):
    if not auth.get("is_premium"):
        raise HTTPException(403, "Premium only")
    return {"tips": PREMIUM_COACH_TIPS}

@app.get("/api/hotspots")
async def get_hotspots(auth=Depends(get_current_user)):
    result = supabase.table("hotspots").select("*").execute()
    return {"hotspots": result.data or []}

@app.post("/api/hotspots/add")
async def add_hotspot(request: Request, auth=Depends(get_current_user)):
    if auth["id"] not in ADMIN_IDS and auth["username"].lower() != "ben":
        raise HTTPException(403, "Admin only")
    body = await request.json()
    supabase.table("hotspots").insert({
        "name": body.get("name", "Hotspot"),
        "lat": body["lat"],
        "lng": body["lng"],
        "radius": body.get("radius", 50),
        "wisp_reward": body.get("wisp_reward", 10)
    }).execute()
    return {"status": "added"}

@app.post("/api/admin/shadow-ban/{target_id}")
async def shadow_ban(target_id: str, auth=Depends(get_current_user)):
    if auth["id"] not in ADMIN_IDS and auth["username"].lower() != "ben":
        raise HTTPException(403, "Admin only")
    supabase.table("users").update({"is_admin": False}).eq("id", target_id).execute()
    return {"status": "banned", "target": target_id}

# ── GOOGLE AUTH ───────────────────────────────────────
class GoogleAuthRequest(BaseModel):
    id_token: str
    email: str
    display_name: str

@app.post("/api/google-auth")
async def google_auth(req: GoogleAuthRequest):
    """
    Accepts a Google ID token from the Flutter app,
    verifies it via Google's tokeninfo endpoint,
    then creates or finds the user in Supabase and returns a Spazz JWT.
    """
    import urllib.request
    import urllib.parse

    # Verify token with Google
    try:
        url = f"https://oauth2.googleapis.com/tokeninfo?id_token={req.id_token}"
        with urllib.request.urlopen(url, timeout=5) as resp:
            token_info = json.loads(resp.read().decode())
    except Exception as e:
        raise HTTPException(401, f"Google token verification failed: {str(e)}")

    if token_info.get("error"):
        raise HTTPException(401, "Invalid Google token")

    google_email = token_info.get("email")
    if not google_email:
        raise HTTPException(401, "No email in Google token")

    # Normalize email to a safe username
    base_username = google_email.split("@")[0].replace(".", "_").replace("+", "_")[:20]

    # Check if user already exists by email
    existing = supabase.table("users").select("*").eq("email", google_email).limit(1).execute()

    if existing.data:
        user = existing.data[0]
        token = make_token(user["id"])
        supabase.table("users").update({"token": token}).eq("id", user["id"]).execute()
        is_admin = user["id"] in ADMIN_IDS or user.get("username", "").lower() == "ben"
        return {
            "token": token,
            "user_id": user["id"],
            "username": user["username"],
            "is_admin": is_admin
        }

    # New user — create them
    user_id = "user_" + str(uuid.uuid4())[:8]

    # Make sure username is unique
    username = base_username
    suffix = 1
    while True:
        check = supabase.table("users").select("id").eq("username", username).limit(1).execute()
        if not check.data:
            break
        username = f"{base_username}{suffix}"
        suffix += 1

    token = make_token(user_id)
    supabase.table("users").insert({
        "id": user_id,
        "username": username,
        "email": google_email,
        "password_hash": "",  # no password for Google users
        "token": token,
        "xp": 0,
        "level": 1,
        "wisp_coins": 50,
        "steps": 0,
        "calories": 0,
        "distance_m": 0,
        "is_premium": False,
    }).execute()

    return {
        "token": token,
        "user_id": user_id,
        "username": username,
        "is_admin": False
    }
