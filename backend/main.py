import shutil                                                       # File operations (copy/delete files for uploads)
import bcrypt                                                       # Hash passwords securely
from typing import Optional                                         # Type hints for optional parameters
from datetime import datetime, timedelta                            # Date/time handling for tokens and timestamps

from fastapi import FastAPI, HTTPException, UploadFile, File, Form  # Web framework and HTTP utilities
from fastapi.middleware.cors import CORSMiddleware                  # Allows Flutter app to call this backend
from fastapi.staticfiles import StaticFiles                         # Serve uploaded images from /uploads and /profilePic folders
from jose import jwt                                                # Create and verify login tokens
from pydantic import BaseModel                                      # Validate incoming request data (ensures correct types)
from sqlalchemy import text                                         # Execute raw SQL queries safely

from db import engine                                               # Database connection object

# Data validation models (Pydantic)
# These check that incoming data from Flutter has the correct type and structure
import cloudinary
import cloudinary.uploader
from dotenv import load_dotenv
import os

load_dotenv()
print("Cloudinary URL loaded:", os.getenv("CLOUDINARY_URL") is not None)
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

class ProfilePicUpdateRequest(BaseModel):  # Validates profile picture URL updates
    profile_picture: str

class SwipeRequest(BaseModel):  # Validates swipe actions (like/dislike on items)
    swiper_user_id: int
    swiped_cloth_id: int
    action: str # "like" or "dislike"
    
class ProfileUpdateRequest(BaseModel):  # Validates profile edits (username, bio)
    username: str
    about_me: str
    city: str
    

class TradeRequest(BaseModel):  # Validates trade/deal proposals from chat
    match_id: int
    proposer_user_id: int
    meeting_method: Optional[str] = None  # Optional shipping method

class TradeShippingRequest(BaseModel):  # Validates shipping method updates
    meeting_method: str

# Initialize FastAPI app
app = FastAPI()
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# CORS configuration - allows Flutter app on Android emulator to reach this backend
app.add_middleware(
    CORSMiddleware, 
    allow_origins=["*"],  # Allow all origins (safe for development, restrict in production)
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods (GET, POST, PUT, etc.)
    allow_headers=["*"],  # Allow all headers
)


#change profilepic
@app.put("/profile/{user_id}/profile-pic")
def update_profile_pic(user_id: int, payload: ProfilePicUpdateRequest):
    with engine.connect() as connection:
        result = connection.execute(text("""
            UPDATE users
            SET profile_pic_url = :profile_pic_url
            WHERE user_id = :user_id
        """), {
            "profile_pic_url": payload.profile_picture,
            "user_id": user_id
        })

        connection.commit()

        check_user = connection.execute(text("""
            SELECT username, bio, profile_pic_url
            FROM users
            WHERE user_id = :user_id
        """), {
            "user_id": user_id
        }).fetchone()

        if not check_user:
            return {"detail": "User not found"}

        return {
            "username": check_user.username,
            "about_me": check_user.bio if check_user.bio else "",
            "profile_picture": check_user.profile_pic_url if check_user.profile_pic_url else ""
        }

@app.get("/")
def home():
    return {"message": "API is working"}

app.mount("/profilePic", StaticFiles(directory="profilePic"), name="profilePic")

@app.post("/upload-profile-pic")
async def upload_profile_pic(file: UploadFile):
    
    upload_result = cloudinary.uploader.upload(
        file.file,
        folder="swipeswap/profile_pics"
    )

    image_url = upload_result["secure_url"]

    return {"url": image_url}

@app.get("/profile/{user_id}")
def get_profile(user_id: int):
    with engine.connect() as connection:
        result = connection.execute(text("""
            SELECT username, bio, profile_pic_url, city
            FROM users
            WHERE user_id = :user_id
        """), {"user_id": user_id}).fetchone()

        if not result:
            return {"detail": "User not found"}

        return {
            "username": result.username,
            "about_me": result.bio if result.bio else "",
            "profile_picture": result.profile_pic_url if result.profile_pic_url else "",
            "city": result.city if result.city else "",
            
        }

@app.put("/profile/{user_id}/update")
def update_profile(user_id: int, profile: ProfileUpdateRequest):
    with engine.connect() as connection:
        result = connection.execute(text("""
            UPDATE users
            SET username = :username,
                bio = :bio,
                city = :city
            WHERE user_id = :user_id
        """), {
            "username": profile.username,
            "bio": profile.about_me,
            "user_id": user_id,
            "city": profile.city
        })

        connection.commit()

        check_user = connection.execute(text("""
            SELECT username, bio, profile_pic_url, city
            FROM users
            WHERE user_id = :user_id
        """), {
            "user_id": user_id
        }).fetchone()

        if not check_user:
            return {"detail": "User not found"}

        return {
            "username": check_user.username,
            "about_me": check_user.bio if check_user.bio else "",
            "profile_picture": check_user.profile_pic_url if check_user.profile_pic_url else "",
            "city": check_user.city if check_user.city else "",
        }



@app.get("/items/{user_id}")
def get_items(user_id: int):
    with engine.connect() as connection:
        result = connection.execute(text("""
            SELECT 
                cloth_id,
                name,
                description,
                image_url,
                category,
                brand,
                size,
                condition_rating,
                estimated_value
            FROM clothes
            WHERE is_available = 1
              AND user_id != :user_id
              ORDER BY cloth_id DESC
        """), {"user_id": user_id})

        items = []
        for row in result:
            items.append({
                "cloth_id": row.cloth_id,
                "name": row.name,
                "description": row.description,
                "image_url": row.image_url,
                "category": row.category,
                "brand": row.brand,
                "size": row.size,
                "condition_rating": row.condition_rating,
                "estimated_value": float(row.estimated_value) if row.estimated_value is not None else None
            })

        return items
    
@app.get("/items/user/{user_id}")
def get_user_items(user_id: int):
    with engine.connect() as connection:
        result = connection.execute(text("""
            SELECT
                cloth_id,
                name,
                description,
                image_url,
                category,
                brand,
                size,
                condition_rating,
                estimated_value,
                is_available
            FROM clothes
            WHERE user_id = :user_id
            ORDER BY cloth_id DESC
        """), {
            "user_id": user_id
        })
        
        items = []
        for row in result:
            items.append({
                "cloth_id": row.cloth_id,
                "name": row.name,
                "description": row.description,
                "image_url": row.image_url,
                "category": row.category,
                "brand": row.brand,
                "size": row.size,
                "condition_rating": row.condition_rating,
                "estimated_value": float(row.estimated_value) if row.estimated_value is not None else None,
                "is_available": row.is_available
            })
            
        return items

    
@app.post("/swipe")
def create_swipe(swipe: SwipeRequest):
    with engine.connect() as connection:
        # 1. Prevent duplicate swipes on the same item
        existing_swipe = connection.execute(text("""
            SELECT swipe_id
            FROM swipes
            WHERE swiper_user_id = :swiper_user_id
              AND swiped_cloth_id = :swiped_cloth_id
        """), {
            "swiper_user_id": swipe.swiper_user_id,
            "swiped_cloth_id": swipe.swiped_cloth_id
        }).fetchone()

        if existing_swipe:
            return {
                "message": "You already swiped on this item",
                "matched": False
            }

        # 2. Save the swipe
        connection.execute(text("""
            INSERT INTO swipes (swiper_user_id, swiped_cloth_id, action)
            VALUES (:swiper_user_id, :swiped_cloth_id, :action)
        """), {
            "swiper_user_id": swipe.swiper_user_id,
            "swiped_cloth_id": swipe.swiped_cloth_id,
            "action": swipe.action
        })

        connection.commit()

        # 3. If it is not a like, stop here
        if swipe.action != "like":
            return {
                "message": "Swipe saved",
                "matched": False
            }

        # 4. Find owner of liked item
        cloth_owner = connection.execute(text("""
            SELECT user_id
            FROM clothes
            WHERE cloth_id = :cloth_id
        """), {
            "cloth_id": swipe.swiped_cloth_id
        }).fetchone()

        if not cloth_owner:
            return {
                "message": "Cloth not found",
                "matched": False
            }

        owner_user_id = cloth_owner.user_id

        # 5. Prevent matching with yourself
        if owner_user_id == swipe.swiper_user_id:
            return {
                "message": "You cannot match with your own item",
                "matched": False
            }

        # 6. Check if owner already liked one of swiper's items
        reverse_like = connection.execute(text("""
            SELECT TOP 1 s.swiped_cloth_id
            FROM swipes s
            JOIN clothes c ON c.cloth_id = s.swiped_cloth_id
            WHERE s.swiper_user_id = :owner_user_id
              AND s.action = 'like'
              AND c.user_id = :swiper_user_id
        """), {
            "owner_user_id": owner_user_id,
            "swiper_user_id": swipe.swiper_user_id
        }).fetchone()

        if not reverse_like:
            return {
                "message": "Swipe saved",
                "matched": False
            }

        reverse_cloth_id = reverse_like.swiped_cloth_id

        # 7. Store users in fixed order
        user1_id = min(swipe.swiper_user_id, owner_user_id)
        user2_id = max(swipe.swiper_user_id, owner_user_id)

        # 8. Assign cloth IDs according to user order
        if user1_id == swipe.swiper_user_id:
            cloth1_id = reverse_cloth_id
            cloth2_id = swipe.swiped_cloth_id
        else:
            cloth1_id = swipe.swiped_cloth_id
            cloth2_id = reverse_cloth_id

        # 9. Check if match already exists
        existing_match = connection.execute(text("""
            SELECT match_id
            FROM matches
            WHERE user1_id = :user1_id
              AND user2_id = :user2_id
        """), {
            "user1_id": user1_id,
            "user2_id": user2_id
        }).fetchone()

        if existing_match:
            return {
                "message": "Swipe saved, match already exists",
                "matched": True,
                "match_id": existing_match.match_id
            }

        # 10. Create the match
        connection.execute(text("""
            INSERT INTO matches (user1_id, user2_id, cloth1_id, cloth2_id, status)
            VALUES (:user1_id, :user2_id, :cloth1_id, :cloth2_id, 'active')
        """), {
            "user1_id": user1_id,
            "user2_id": user2_id,
            "cloth1_id": cloth1_id,
            "cloth2_id": cloth2_id
        })

        connection.commit()

        new_match = connection.execute(text("""
            SELECT TOP 1 match_id
            FROM matches
            WHERE user1_id = :user1_id
              AND user2_id = :user2_id
            ORDER BY match_id DESC
        """), {
            "user1_id": user1_id,
            "user2_id": user2_id
        }).fetchone()

        return {
            "message": "It's a match!",
            "matched": True,
            "match_id": new_match.match_id
        }
        
@app.get("/matches/{user_id}")
def get_matches(user_id: int):
    with engine.connect() as connection:
        result = connection.execute(text("""
            SELECT
                m.match_id,
                CASE
                    WHEN m.user1_id = :user_id THEN m.user2_id
                    ELSE m.user1_id
                END AS other_user_id,

                u.username AS other_username,

                CASE
                    WHEN m.user1_id = :user_id THEN c2.name
                    ELSE c1.name
                END AS matched_item_name,

                CASE
                    WHEN m.user1_id = :user_id THEN c2.image_url
                    ELSE c1.image_url
                END AS matched_item_image_url,

                m.status
            FROM matches m
            JOIN users u
                ON u.user_id = CASE
                    WHEN m.user1_id = :user_id THEN m.user2_id
                    ELSE m.user1_id
                END
            JOIN clothes c1 ON c1.cloth_id = m.cloth1_id
            JOIN clothes c2 ON c2.cloth_id = m.cloth2_id
            WHERE m.user1_id = :user_id
               OR m.user2_id = :user_id
            ORDER BY m.match_id DESC
        """), {
            "user_id": user_id
        })

        matches = []
        for row in result:
            matches.append({
                "match_id": row.match_id,
                "other_user_id": row.other_user_id,
                "other_username": row.other_username,
                "matched_item_name": row.matched_item_name,
                "matched_item_image_url": row.matched_item_image_url,
                "status": row.status
            })

        return matches

# ============= AUTHENTICATION & SECURITY =============

# JWT configuration for login tokens
SECRET_KEY = "replace-with-random-secret"  # Secret key for signing tokens (should be random in production)
ALGORITHM = "HS256"  # Algorithm for token encryption
ACCESS_TOKEN_EXPIRE_MINUTES = 60  # How long login token lasts

# Helper functions for password security
def verify_password(plain, hashed):  # Check if plain password matches hashed password
    return bcrypt.checkpw(plain.encode('utf-8'), hashed.encode('utf-8'))

def get_password_hash(password):  # Convert plain password to hash (for storage)
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# Helper function to create login tokens
def create_access_token(data: dict):  # Generate JWT token that expires after ACCESS_TOKEN_EXPIRE_MINUTES
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# ============= REGISTRATION & LOGIN ENDPOINTS =============

class RegisterRequest(BaseModel):  # Validates new user signup data
    username: str
    email: str
    password: str

@app.post("/register")
def register(payload: RegisterRequest):
    with engine.connect() as conn:
        existing = conn.execute(text("SELECT user_id FROM users WHERE username = :u OR email = :e"),
                                 {"u": payload.username, "e": payload.email}).fetchone()
        if existing:
            return {"error":"user exists"}
        hashed = get_password_hash(payload.password)
        conn.execute(text("INSERT INTO users (username,email,password_hash) VALUES (:u,:e,:p)"),
                     {"u": payload.username, "e": payload.email, "p": hashed})
        conn.commit()
        return {"message":"ok"}

# login endpoint 
class LoginRequest(BaseModel):  # Validates login credentials
    username: str
    password: str

@app.post("/login")
def login(payload: LoginRequest):
    with engine.connect() as conn:
        row = conn.execute(text("SELECT user_id, password_hash FROM users WHERE username=:u"),
                           {"u":payload.username}).fetchone()
        if not row or not verify_password(payload.password, row.password_hash):
            raise HTTPException(status_code=401, detail="invalid credentials")
        token = create_access_token({"sub": str(row.user_id)})
        return {"access_token": token, "token_type":"bearer","user_id":row.user_id}

# ============= MESSAGES & CHAT =============
    
class MessageRequest(BaseModel):  # Validates chat message data
    match_id: int
    sender_user_id: int
    content: str
    
@app.post("/messages")
def send_message(message: MessageRequest):
    with engine.connect() as connection:
        connection.execute(text("""
            INSERT INTO messages (match_id, sender_user_id, content)
            VALUES (:match_id, :sender_user_id, :content)
        """), {
            "match_id": message.match_id,
            "sender_user_id": message.sender_user_id,
            "content": message.content
        })

        connection.commit()

        return {
            "message": "Message sent"
        }
    
@app.get("/messages/{match_id}")
def get_messages(match_id: int):
    with engine.connect() as connection:
        result = connection.execute(text("""
            SELECT m.message_id, m.sender_user_id, u.username AS sender_username, m.content, m.sent_at
            FROM messages m
            JOIN users u ON u.user_id = m.sender_user_id
            WHERE m.match_id = :match_id
            ORDER BY m.sent_at ASC
        """), {
            "match_id": match_id
        })

        messages = []
        for row in result:
            messages.append({
                "message_id": row.message_id,
                "sender_user_id": row.sender_user_id,
                "sender_username": row.sender_username,
                "content": row.content,
                "sent_at": str(row.sent_at)
            })

        return messages
    
@app.post("/listings/")
async def create_listing(
    name: str = Form(...),
    description: str = Form(...),
    user_id: int = Form(...),
    category: str = Form(...),
    brand: str = Form(...),
    size: str = Form(...),
    condition_rating: str = Form(...),
    image: UploadFile = File(...),
):
    
    upload_result = cloudinary.uploader.upload(
        image.file,
        folder="swipeswap/listings"
    )
    
    image_url = upload_result["secure_url"]
    
    with engine.connect() as connection:
        connection.execute(text("""
            INSERT INTO clothes (
                user_id,
                name,
                description,
                image_url,
                category,
                brand,
                size,
                condition_rating,
                is_available
            )
            VALUES (
                :user_id,
                :name,
                :description,
                :image_url,
                :category,
                :brand,
                :size,
                :condition_rating,
                1
            )
        """), {
            "user_id": user_id,
            "name": name,
            "description": description,
            "image_url": image_url,
            "category": category,
            "brand": brand,
            "size": size,
            "condition_rating": condition_rating
        })

        connection.commit()

    return {"message": "Listing created"}

# ============= TRADES & DEAL PROPOSALS =============

@app.post("/trades")
def create_trade(trade: TradeRequest):  # Create a trade proposal when user proposes a deal in chat
    with engine.connect() as connection:
        # Check if trade already exists for this match
        existing_trade = connection.execute(text("""
            SELECT trade_id, trade_status, proposer_user_id
            FROM trades
            WHERE match_id = :match_id
        """), {"match_id": trade.match_id}).fetchone()

        if existing_trade:
            if existing_trade.trade_status == 'pending':
                return {"message": "Trade already pending"}
            elif existing_trade.trade_status == 'agreed':
                return {"message": "Trade already agreed"}
            else:
                # Update to pending if was cancelled or something
                connection.execute(text("""
                    UPDATE trades
                    SET trade_status = 'pending', proposer_user_id = :proposer_user_id, meeting_method = :meeting_method, updated_at = GETDATE()
                    WHERE trade_id = :trade_id
                """), {"trade_id": existing_trade.trade_id, "proposer_user_id": trade.proposer_user_id, "meeting_method": trade.meeting_method})
                connection.commit()
                return {"message": "Trade proposal sent"}

        # Create new trade
        connection.execute(text("""
            INSERT INTO trades (match_id, proposer_user_id, trade_status, meeting_method)
            VALUES (:match_id, :proposer_user_id, 'pending', :meeting_method)
        """), {"match_id": trade.match_id, "proposer_user_id": trade.proposer_user_id, "meeting_method": trade.meeting_method})

        connection.commit()

        return {"message": "Trade proposal sent"}

@app.put("/trades/{trade_id}/accept")
def accept_trade(trade_id: int):  # Receiver accepts the trade proposal
    with engine.connect() as connection:
        # Get the trade and match
        trade = connection.execute(text("""
            SELECT t.match_id, m.cloth1_id, m.cloth2_id
            FROM trades t
            JOIN matches m ON m.match_id = t.match_id
            WHERE t.trade_id = :trade_id
        """), {"trade_id": trade_id}).fetchone()

        if not trade:
            return {"detail": "Trade not found"}

        # Update trade status to agreed and keep shipping step pending
        connection.execute(text("""
            UPDATE trades
            SET trade_status = 'agreed', updated_at = GETDATE()
            WHERE trade_id = :trade_id
        """), {"trade_id": trade_id})

        # Keep match active until receipt confirmation
        connection.execute(text("""
            UPDATE matches
            SET status = 'negotiating', updated_at = GETDATE()
            WHERE match_id = :match_id
        """), {"match_id": trade.match_id})

        # Set clothes unavailable
        connection.execute(text("""
            UPDATE clothes
            SET is_available = 0, updated_at = GETDATE()
            WHERE cloth_id IN (:cloth1_id, :cloth2_id)
        """), {"cloth1_id": trade.cloth1_id, "cloth2_id": trade.cloth2_id})

        connection.commit()

        return {"message": "Trade accepted"}

@app.put("/trades/{trade_id}/shipping")
def update_shipping_method(trade_id: int, payload: TradeShippingRequest):  # Set shipping method (shipping/meetup/drop-off)
    if payload.meeting_method not in ('shipping', 'meetup', 'drop-off'):
        raise HTTPException(status_code=400, detail='Invalid shipping method')

    with engine.connect() as connection:
        existing = connection.execute(text("""
            SELECT trade_id
            FROM trades
            WHERE trade_id = :trade_id
        """), {"trade_id": trade_id}).fetchone()

        if not existing:
            raise HTTPException(status_code=404, detail='Trade not found')

        connection.execute(text("""
            UPDATE trades
            SET meeting_method = :meeting_method, trade_status = 'shipping', updated_at = GETDATE()
            WHERE trade_id = :trade_id
        """), {"meeting_method": payload.meeting_method, "trade_id": trade_id})

        connection.commit()

        return {"message": "Shipping method set"}

@app.put("/trades/{trade_id}/received")
def mark_trade_received(trade_id: int):  # Mark item as received (completes the trade)
    with engine.connect() as connection:
        trade = connection.execute(text("""
            SELECT t.match_id
            FROM trades t
            WHERE t.trade_id = :trade_id
        """), {"trade_id": trade_id}).fetchone()

        if not trade:
            raise HTTPException(status_code=404, detail='Trade not found')

        connection.execute(text("""
            UPDATE trades
            SET trade_status = 'completed', completed_at = GETDATE(), updated_at = GETDATE()
            WHERE trade_id = :trade_id
        """), {"trade_id": trade_id})

        connection.execute(text("""
            UPDATE matches
            SET status = 'completed', updated_at = GETDATE()
            WHERE match_id = :match_id
        """), {"match_id": trade.match_id})

        connection.commit()

        return {"message": "Item received"}

@app.put("/trades/{trade_id}/decline")
def decline_trade(trade_id: int):  # Receiver declines the trade proposal (cancels it)
    with engine.connect() as connection:
        connection.execute(text("""
            UPDATE trades
            SET trade_status = 'cancelled', updated_at = GETDATE()
            WHERE trade_id = :trade_id
        """), {"trade_id": trade_id})

        connection.commit()

        return {"message": "Trade declined"}

@app.get("/trades/{user_id}")
def get_user_trades(user_id: int):
    with engine.connect() as connection:
        result = connection.execute(text("""
            SELECT t.trade_id, t.match_id, t.trade_status, t.proposer_user_id, t.meeting_method, t.created_at, t.completed_at,
                   m.user1_id, m.user2_id, m.cloth1_id, m.cloth2_id,
                   u1.username as user1_username, u2.username as user2_username,
                   c1.name as cloth1_name, c2.name as cloth2_name,
                   c1.image_url as cloth1_image, c2.image_url as cloth2_image
            FROM trades t
            JOIN matches m ON m.match_id = t.match_id
            JOIN users u1 ON u1.user_id = m.user1_id
            JOIN users u2 ON u2.user_id = m.user2_id
            JOIN clothes c1 ON c1.cloth_id = m.cloth1_id
            JOIN clothes c2 ON c2.cloth_id = m.cloth2_id
            WHERE m.user1_id = :user_id OR m.user2_id = :user_id
            ORDER BY t.created_at DESC
        """), {"user_id": user_id})

        trades = []
        for row in result:
            trades.append({
                "trade_id": row.trade_id,
                "match_id": row.match_id,
                "status": row.trade_status,
                "proposer_user_id": row.proposer_user_id,
                "meeting_method": row.meeting_method,
                "created_at": str(row.created_at),
                "completed_at": str(row.completed_at) if row.completed_at else None,
                "user1_id": row.user1_id,
                "user2_id": row.user2_id,
                "user1_username": row.user1_username,
                "user2_username": row.user2_username,
                "cloth1_id": row.cloth1_id,
                "cloth2_id": row.cloth2_id,
                "cloth1_name": row.cloth1_name,
                "cloth2_name": row.cloth2_name,
                "cloth1_image": row.cloth1_image,
                "cloth2_image": row.cloth2_image
            })

        return trades

@app.get("/trades/match/{match_id}")
def get_trade_for_match(match_id: int):
    with engine.connect() as connection:
        result = connection.execute(text("""
            SELECT trade_id, trade_status, proposer_user_id, meeting_method
            FROM trades
            WHERE match_id = :match_id
        """), {"match_id": match_id}).fetchone()

        if result:
            return {
                "trade_id": result.trade_id,
                "status": result.trade_status,
                "proposer_user_id": result.proposer_user_id,
                "meeting_method": result.meeting_method
            }
        else:
            return None