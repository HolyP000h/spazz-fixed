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

# ── CONFIGURATION CONSTANTS ───────────────────
METER_TO_DEGREE_FACTOR = 0.000009
HOME_BLACKOUT_RADIUS_METERS = 300

# ── SUPABASE ─────────────────────────────
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://kytmktshrywvxigobsxd.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "sb_publishable_U09QKkouk1bYdQum8h6Ytg_zyCKRZml")

# Execute and initialize the client engine
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

# ── OMNI-CHANNEL CORS INJECTION MATRIX ─────────────────
origins = [
    "https://www.spazzapp.com",
    "https://spazzapp.com",
    "http://localhost:3000",
    "http://localhost:5173",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"https://.*\.figma\.site",  # Wildcard validation for Figma Make preview frames
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── MODELS ──────────────────────────────
class RegisterRequest(BaseModel):
    username: str
    password: str
    gender: str = "other"
    seeking: str = "everyone"
    age: int = 25
    home_lat: Optional[float] = None
    home_lon: Optional[float] = None

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

# ── GEO & PRIVACY SHIELD ─────────────────
def haversine(lat1, lon1, lat2, lon2):
    R = 6371e3
    dLat = (lat2 - lat1) * math.pi / 180
    dLon = (lon2 - lon1) * math.pi / 180
    a = math.sin(dLat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dLon/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def is_inside_home_geofence(current_lat: float, current_lon: float, user: dict) -> bool:
    home_lat = user.get("home_lat")
    home_lon = user.get("home_lon")
    if home_lat is None or home_lon is None:
        return False
    distance_from_home = haversine(current_lat, current_lon, float(home_lat), float(home_lon))
    return distance_from_home < HOME_BLACKOUT_RADIUS_METERS

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
        "home_lat": req.home_lat,
        "home_lon": req.home_lon,
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
    if not isinstance(user, dict):
        raise HTTPException(401, "Bad credentials")

    if user.get("password_hash") != hash_password(req.password):
        raise HTTPException(401, "Bad credentials")

    token = make_token(user["id"])
    supabase.table("users").update({"token": token}).eq("id", user["id"]).execute()

    username = user.get("username")
    is_admin = user["id"] in ADMIN_IDS or (isinstance(username, str) and username.lower() == "ben")
    return {"token": token, "user_id": user["id"], "username": user["username"], "is_admin": is_admin}

@app.post("/api/location")
async def update_location(loc: LocationUpdate, auth=Depends(get_current_user)):
    user = auth
    if is_inside_home_geofence(loc.lat, loc.lon, user):
        supabase.table("users").update({"online": False}).eq("id", user["id"]).execute()
        raise HTTPException(403, "🚨 SECURITY LOCK: Cannot broadcast Spazz Signal inside your 300m protected Home Sector.")

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
async def get_users(auth: dict = Depends(get_current_user)):
    if not auth or not isinstance(auth, dict):
        raise HTTPException(401, "Invalid auth payload")

    auth_id = auth.get("id")
    auth_username = auth.get("username", "")
    
    # 🚀 Strict string guard prevents the line 288 cascading analyzer crash
    is_admin = auth_id in ADMIN_IDS or (isinstance(auth_username, str) and auth_username.lower() == "ben")

    result = supabase.table("users").select("*").eq("online", True).execute()
    online_users = result.data if isinstance(result.data, list) else []

    entities = []
    for u in online_users:
        if not isinstance(u, dict):
            continue
        if u.get("id") != auth_id:
            entities.append({
                "id": u.get("id"), "username": u.get("username"), "type": "user",
                "lat": u.get("lat", 0), "lon": u.get("lon", 0),
                "gender": u.get("gender", "other"), "age": u.get("age", 25),
                "is_premium": u.get("is_premium", False)
            })

    entities += get_wisps()

    return {
        "entities": entities,
        "me": {
            "id": auth_id,
            "username": auth_username,
            "steps": auth.get("steps", 0),
            "calories": auth.get("calories", 0),
            "distance_m": auth.get("distance_m", 0),
            "credits": auth.get("wisp_coins", 0),
            "wisps_collected": auth.get("xp", 0),
            "level": auth.get("level", 1),
            "is_premium": auth.get("is_premium", False),
        },
        "coach_tip": smart_coach_tip(auth),
        "is_admin": is_admin,
    }

@app.get("/api/me")
async def get_me(auth=Depends(get_current_user)):
    if not isinstance(auth, dict):
        raise HTTPException(401, "Invalid user")
    return {
        "id": auth.get("id"),
        "username": auth.get("username", ""),
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
    if not isinstance(auth, dict):
        raise HTTPException(401, "Invalid user")
    result = supabase.table("users").select("id,username,xp,steps,wisp_coins").order("xp", desc=True).limit(20).execute()
    users = result.data if isinstance(result.data, list) else []
    leaderboard_items = []
    for u in users:
        if not isinstance(u, dict):
            continue
        leaderboard_items.append({
            "rank": len(leaderboard_items) + 1,
            "username": u.get("username", ""),
            "wisps": u.get("xp", 0),
            "steps": u.get("steps", 0),
            "credits": u.get("wisp_coins", 0),
            "is_me": u.get("id") == auth.get("id"),
        })
    return {"leaderboard": leaderboard_items}

@app.post("/api/collect/{target_id}")
async def collect_target(target_id: str, auth=Depends(get_current_user)):
    wisp = _wisps.get(target_id)
    if not wisp:
        raise HTTPException(404, "Wisp not found or already collected")

    reward = wisp.get("wisp_reward", random.randint(3, 10))
    remove_wisp(target_id)

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
        if not isinstance(m, dict):
            continue
        user_id = m.get("user_id")
        to_user_id = m.get("to_user_id")
        partner_id = to_user_id if user_id == auth.get("id") else user_id
        if partner_id is None:
            continue
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

# ── SHOP CATALOG ─────────────────────────
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
    {"id":"flash_fire",     "type":"flash","name":"Fire",          "desc":"Orange flame burst",        "price":200, "preview":"🔥","premium":False},
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
    if not auth or not isinstance(auth, dict):
        raise HTTPException(401, "Invalid session token")

    inv_result = supabase.table("inventory").select("*").eq("user_id", auth["id"]).execute()
    
    # 🚀 Type Guard added here satisfies Pylance perfectly
    owned_ids = [r.get("item_name") for r in (inv_result.data or []) if isinstance(r, dict)]
    
    equipped_result = supabase.table("inventory").select("*").eq("user_id", auth["id"]).eq("item_type", "equipped").execute()
    equipped = {}
    for r in (equipped_result.data or []):
        if not isinstance(r, dict):  # 🚀 Explicit loop guard
            continue
        item_category = r.get("item_category")
        item_name = r.get("item_name")
        if item_category and item_name:
            equipped[item_category] = item_name

    items = []
    for item in SHOP_ITEMS:
        i = dict(item)
        i["owned"] = item["id"] in owned_ids
        i["equipped"] = equipped.get(item["type"]) == item["id"]
        items.append(i)
    return {"items": items, "equipped": equipped, "is_premium": auth.get("is_premium", False)}

@app.post("/api/shop/buy/{item_id}")
async def buy_item(item_id: str, auth=Depends(get_current_user)):
    if not auth or not isinstance(auth, dict):
        raise HTTPException(401, "Invalid session token")

    item = next((i for i in SHOP_ITEMS if i["id"] == item_id), None)
    if not item:
        raise HTTPException(404, "Item not found")

    inv_result = supabase.table("inventory").select("item_name").eq("user_id", auth["id"]).execute()
    
    # 🚀 Double type guard format for Pylance type tracking stability
    owned_ids = [r.get("item_name") for r in (inv_result.data or []) if isinstance(r, dict)]
    if item_id in owned_ids:
        raise HTTPException(400, "Already owned")

    if item.get("premium") and not auth.get("is_premium"):
        raise HTTPException(403, "Premium required")

    user_result = supabase.table("users").select("wisp_coins").eq("id", auth["id"]).execute()
    coins = 0
    if isinstance(user_result.data, list) and user_result.data:
        first_row = user_result.data[0]
        if isinstance(first_row, dict):
            coins = first_row.get("wisp_coins", 0) or 0
            
    if coins < item["price"]:
        raise HTTPException(400, f"Need {item['price']} coins, you have {coins}")

    supabase.table("users").update({"wisp_coins": coins - item["price"]}).eq("id", auth["id"]).execute()
    supabase.table("inventory").insert({
        "user_id": auth["id"],
        "item_name": item_id,
        "item_type": "owned"
    }).execute()

    return {"status": "purchased", "new_balance": coins - item["price"], "item": item}

@app.post("/api/premium/subscribe")
async def subscribe_premium(auth=Depends(get_current_user)):
    # 🚀 GUARD: Force Pylance to recognize 'auth' as a valid user dictionary object payload
    if not auth or not isinstance(auth, dict):
        raise HTTPException(401, "🚨 AUTH FAILURE: Session invalid or expired.")

    user_result = supabase.table("users").select("wisp_coins,is_premium").eq("id", auth.get("id")).execute()
    if not user_result.data or not isinstance(user_result.data, list):
        raise HTTPException(404, "User not found")
        
    user = user_result.data[0]
    if not isinstance(user, dict):
        raise HTTPException(404, "User not found")
        
    SUBSCRIPTION_PRICE = 299
    # Force a strict fallback cast to make the type system happy
    coins_raw = user.get("wisp_coins")
    try:
        coins = int(coins_raw) if isinstance(coins_raw, (int, float, str)) else 0
    except (TypeError, ValueError):
        raise HTTPException(400, "Invalid coin balance")
        
    if coins < SUBSCRIPTION_PRICE:
        raise HTTPException(400, f"Need {SUBSCRIPTION_PRICE} coins")
        
    supabase.table("users").update({
        "wisp_coins": coins - SUBSCRIPTION_PRICE,
        "is_premium": True
    }).eq("id", auth.get("id")).execute() # Cleaned up to use a safe .get() lookup
    
    return {"status": "subscribed", "new_balance": coins - SUBSCRIPTION_PRICE}

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
    
    # 🚀 GUARD: Teach Pylance that the request body payload is explicitly a dictionary matrix
    if not isinstance(body, dict):
        raise HTTPException(400, "Malformed request entity matrix.")
        
    supabase.table("hotspots").insert({
        "name": body.get("name", "Hotspot"),
        "lat": body.get("lat"),
        "lng": body.get("lng"), # 100% safe lookups now!
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
    import urllib.request
    import urllib.parse

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

    base_username = google_email.split("@")[0].replace(".", "_").replace("+", "_")[:20]

    existing = supabase.table("users").select("*").eq("email", google_email).limit(1).execute()

    if existing.data:
        user = existing.data[0]
        
        # 🚀 GUARD: Force Pylance to recognize 'user' as a dictionary matrix payload
        if not isinstance(user, dict):
            raise HTTPException(401, "Google user profile record is corrupted.")

        token = make_token(user.get("id"))
        supabase.table("users").update({"token": token}).eq("id", user.get("id")).execute()
        
        username_val = user.get("username", "")
        # 🚀 Complete type protection for Line 600
        is_admin = user.get("id") in ADMIN_IDS or (isinstance(username_val, str) and username_val.lower() == "ben")
        return {
            "token": token,
            "user_id": user.get("id"),
            "username": user.get("username"),
            "is_admin": is_admin
        }
        supabase.table("users").update({"token": token}).eq("id", user["id"]).execute()
        is_admin = user["id"] in ADMIN_IDS or user.get("username", "").lower() == "ben"
        return {
            "token": token,
            "user_id": user["id"],
            "username": user["username"],
            "is_admin": is_admin
        }

    user_id = "user_" + str(uuid.uuid4())[:8]

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
        "password_hash": "", 
        "token": token,
        "xp": 0,
        "level": 1,
        "wisp_coins": 50,
        "steps": 0,
        "calories": 0,
        "distance_m": 0,
        "is_premium": False,
        "home_lat": None,
        "home_lon": None
    }).execute()

    return {
        "token": token,
        "user_id": user_id,
        "username": username,
        "is_admin": False
    }

# ── FLUTTER MAP ENDPOINTS ─────────────────────────────────────────

@app.post("/api/location/update")
async def location_update_flutter(request: Request, auth=Depends(get_current_user)):
    body = await request.json()
    lat = body.get("lat")
    lng = body.get("lng")
    if lat is None or lng is None:
        raise HTTPException(400, "lat and lng required")

    user = auth
    if is_inside_home_geofence(lat, lng, user):
        supabase.table("users").update({"online": False}).eq("id", user["id"]).execute()
        raise HTTPException(403, "🚨 SECURITY LOCK: Cannot update location matrices while inside your 300m protected Home Sector.")

    last_lat = user.get("last_lat")
    last_lon = user.get("last_lon")
    distance_m = user.get("distance_m", 0) or 0

    if last_lat and last_lon:
        dist = haversine(float(last_lat), float(last_lon), lat, lng)
        if 3 < dist < 500:
            distance_m += dist

    steps = meters_to_steps(distance_m)
    calories = round(meters_to_calories(distance_m, user.get("age", 25)), 1)

    try:
        hotspots_res = supabase.table("hotspots").select("*").execute()
        for hs in (hotspots_res.data or []):
            if not isinstance(hs, dict):
                continue
                
            # 🚀 Fallback lookups ensure everything arriving at float() is a plain primitive string or number
            hs_lat = hs.get("lat")
            hs_lng = hs.get("lng")
            
            lat_val = float(hs_lat) if isinstance(hs_lat, (int, float, str)) else 0.0
            lng_val = float(hs_lng) if isinstance(hs_lng, (int, float, str)) else 0.0

            d = haversine(lat, lng, lat_val, lng_val)
            
            hs_radius = hs.get("radius", 50)
            radius_val = float(hs_radius) if isinstance(hs_radius, (int, float, str)) else 50.0

            if d < radius_val:
                # 🚀 Safely parse out the current visit count integer first
                current_visits = hs.get("visit_count", 0)
                visits_int = int(current_visits) if isinstance(current_visits, (int, float, str)) else 0
                
                supabase.table("hotspots").update({
                    "visit_count": visits_int + 1
                }).eq("id", hs.get("id")).execute()
    except Exception:
        pass

    supabase.table("users").update({
        "lat": lat,
        "lon": lng,
        "last_lat": lat,
        "last_lon": lng,
        "distance_m": distance_m,
        "steps": steps,
        "calories": calories,
        "online": True,
        "last_seen": time.time()
    }).eq("id", user.get("id")).execute()

    return {"status": "ok", "steps": steps, "calories": calories}


@app.get("/api/nearby")
async def get_nearby(lat: float, lng: float, user_id: str, auth=Depends(get_current_user)):
    if not auth or not isinstance(auth, dict):
        raise HTTPException(401, "Invalid session payload")

    RADIUS_M = 2000  # 2km radius
    cutoff = time.time() - 300

    if is_inside_home_geofence(lat, lng, auth):
        raise HTTPException(403, "🚨 SECURITY LOCK: Proximity query failed inside Home Sector.")

    all_users_res = supabase.table("users").select(
        "id,username,lat,lon,is_premium,last_seen,home_lat,home_lon"
    ).eq("online", True).execute()

    nearby_users = []
    # 🚀 Enforce strict indentation level matching the function body!
    for u in (all_users_res.data or []):
        if not isinstance(u, dict):
            continue
        if u.get("id") == auth.get("id"):
            continue
            
        u_last_seen = u.get("last_seen")
        last_seen_val = float(u_last_seen) if isinstance(u_last_seen, (int, float, str)) else 0.0
        if last_seen_val < cutoff:
            continue

        u_lat = u.get("lat")
        u_lon = u.get("lon")
        if u_lat is None or u_lon is None:
            continue
            
        # 🚀 2. Cast lat/lon values securely so haversine runs perfectly
        user_lat = float(u_lat) if isinstance(u_lat, (int, float, str)) else 0.0
        user_lon = float(u_lon) if isinstance(u_lon, (int, float, str)) else 0.0
            
        if u.get("home_lat") is not None and u.get("home_lon") is not None:
            # 🚀 Type-safe defensive casting guarantees primitives for float()
            raw_h_lat = u.get("home_lat")
            raw_h_lon = u.get("home_lon")
            
            h_lat = float(raw_h_lat) if isinstance(raw_h_lat, (int, float, str)) else 0.0
            h_lon = float(raw_h_lon) if isinstance(raw_h_lon, (int, float, str)) else 0.0
            
            if haversine(user_lat, user_lon, h_lat, h_lon) < HOME_BLACKOUT_RADIUS_METERS:
                continue

        dist = haversine(lat, lng, user_lat, user_lon)
        if dist <= RADIUS_M:
            nearby_users.append({
                "id": u.get("id"),
                "username": u.get("username"),
                "lat": user_lat,
                "lng": user_lon,
                "is_premium": u.get("is_premium", False),
            })

    move_wisps()
    wisps_raw = get_wisps()
    nearby_wisps = []
    for wisp in wisps_raw:
        # 🚀 GUARD: Force Pylance to recognize that 'wisp' is a dictionary matrix
        if not isinstance(wisp, dict):
            continue
            
        dist = haversine(lat, lng, float(wisp.get("lat", 0)), float(wisp.get("lon", 0)))
        if dist <= RADIUS_M:
            nearby_wisps.append({
                "id": wisp.get("id"),
                "lat": wisp.get("lat"),
                "lon": lng + random.uniform(-0.01, 0.01),
                "xp": wisp.get("wisp_reward", 10),
            })

    if len(nearby_wisps) < 5:
        for _ in range(5 - len(nearby_wisps)):
            wisp = {
                "id": f"wisp_{uuid.uuid4().hex[:6]}",
                "username": "Wisp",
                "type": "wisp",
                "lat": lat + random.uniform(-0.01, 0.01),
                "lon": lng + random.uniform(-0.01, 0.01),
                "wisp_reward": random.choices([5, 10, 15, 20], weights=[40, 30, 20, 10])[0],
            }
            add_wisp(wisp)
            nearby_wisps.append({
                "id": wisp["id"],
                "lat": wisp["lat"],
                "lng": wisp["lon"],
                "xp": wisp["wisp_reward"],
            })

    hotspots_res = supabase.table("hotspots").select("*").execute()
    nearby_hotspots = []
    for hs in (hotspots_res.data or []):
        # 🚀 GUARD 1: Teach Pylance that 'hs' is strictly a dictionary payload matrix
        if not isinstance(hs, dict):
            continue
            
        # 🚀 GUARD 2: Explicitly extract and cast coordinates cleanly using safe primitives
        hs_lat = hs.get("lat")
        hs_lng = hs.get("lng")
        if hs_lat is None or hs_lng is None:
            continue
            
        lat_val = float(hs_lat) if isinstance(hs_lat, (int, float, str)) else 0.0
        lng_val = float(hs_lng) if isinstance(hs_lng, (int, float, str)) else 0.0

        dist = haversine(lat, lng, lat_val, lng_val)
        if dist <= RADIUS_M * 2:
            nearby_hotspots.append({
                "id": hs.get("id"),
                "lat": lat_val,
                "lng": lng_val,
                "visit_count": hs.get("visit_count", 1),
                "name": hs.get("name", "Hotspot"),
            })

    return {
        "users": nearby_users,
        "wisps": nearby_wisps,
        "hotspots": nearby_hotspots,
    }


@app.post("/api/wisp/collect")
async def collect_wisp(request: Request, auth=Depends(get_current_user)):
    body = await request.json()
    wisp_id = body.get("wisp_id")

    wisp = _wisps.get(wisp_id)
    xp_reward = wisp.get("wisp_reward", 10) if wisp else 10

    remove_wisp(wisp_id)

    user = auth
    user_xp = user.get("xp", 0)
    current_xp = int(user_xp) if isinstance(user_xp, (int, float, str)) else 0
    new_xp = current_xp + int(xp_reward)  # 🚀 Type-hardened addition!
    new_level = max(1, new_xp // 100 + 1)
    new_coins = (user.get("wisp_coins") or 0) + random.randint(1, 3)

    supabase.table("users").update({
        "xp": new_xp,
        "level": new_level,
        "wisp_coins": new_coins,
    }).eq("id", auth["id"]).execute()

    return {"status": "collected", "xp_earned": xp_reward, "new_xp": new_xp, "new_level": new_level}


@app.get("/api/user/{user_id}")
async def get_user(user_id: str, auth=Depends(get_current_user)):
    # Quick type check guard on your request auth token session row
    if not auth or not isinstance(auth, dict):
        raise HTTPException(401, "Invalid auth payload")

    result = supabase.table("users").select("*").eq("id", user_id).limit(1).execute()
    if not result.data or not isinstance(result.data, list):
        raise HTTPException(404, "User not found")
        
    u = result.data[0]
    
    # 🚀 Add this type guard line to instantly satisfy strict Pylance checks!
    if not isinstance(u, dict):
        raise HTTPException(404, "User entry matrix data is corrupted.")

    # Use clean, safe .get() queries instead of raw bracket lookup variables
    return {
        "id": u.get("id"),
        "username": u.get("username"),
        "xp": u.get("xp", 0),
        "level": u.get("level", 1),
        "steps": u.get("steps", 0),
        "calories": u.get("calories", 0),
        "wisp_coins": u.get("wisp_coins", 0),
        "wisps_collected": u.get("xp", 0),
        "is_premium": u.get("is_premium", False),
        "inventory": u.get("inventory", []),
    }


@app.post("/api/subscribe")
async def subscribe(request: Request, auth=Depends(get_current_user)):
    body = await request.json()
    plan = body.get("plan", "monthly")
    supabase.table("users").update({
        "is_premium": True,
        "subscription_plan": plan,
    }).eq("id", auth["id"]).execute()
    return {"status": "subscribed", "plan": plan}

# ── PING SYSTEM ───────────────────────────────────────────────────

_active_pings = {}
@app.post("/api/ping/send")
async def send_ping(request: Request, auth=Depends(get_current_user)):
    # 1. Enforce strict dictionary structure for the analyzer
    if not auth or not isinstance(auth, dict):
        raise HTTPException(401, "🚨 AUTH FAILURE: Session invalid.")

    body = await request.json()
    if not isinstance(body, dict):
        raise HTTPException(400, "Malformed JSON request body.")

    # 2. Extract values cleanly using standard defaults
    priority = body.get("priority", 1)
    is_premium = body.get("is_premium", False)
    lat = body.get("lat", 0)
    lng = body.get("lng", 0)

    # --- GEOPRIVACY SHIELD GATEKEEPER ---
    if is_inside_home_geofence(lat, lng, auth):
        raise HTTPException(403, "🚨 SECURITY LOCK: Operation blocked inside protected Home Sector.")

    # 3. Use .get() lookup parameters instead of raw brackets to make type errors impossible
    user_id = auth.get("id")
    if not user_id:
        raise HTTPException(400, "Malformed user payload matrix.")

    ping_id = f"ping_{uuid.uuid4().hex[:8]}"
    ping_data = {
        "id": ping_id,
        "user_id": user_id,
        "username": auth.get("username", "Hunter"),
        "ping_id": body.get("ping_id", "ping_default"),
        "emoji": body.get("emoji", "📡"),
        "name": body.get("name", "Ping"),
        "sound": body.get("sound", "beep"),
        "haptic": body.get("haptic", "light"),
        "priority": priority,
        "lat": lat,
        "lng": lng,
        "is_premium": is_premium,
        "sent_at": time.time(),
        "expires_at": time.time() + 30, 
    }

    _active_pings[ping_id] = ping_data
    return {**ping_data, "status": "sent"}