import base64
from pydantic import BaseModel
from pathlib import Path
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from db import engine
from sqlalchemy import text
from fastapi import UploadFile, File

class SwipeRequest(BaseModel):
    swiper_user_id: int
    swiped_cloth_id: int
    action: str # "like" or "dislike"
    
class ProfileUpdateRequest(BaseModel):
    username: str
    about_me: str

app = FastAPI()
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
# CORS: laat Flutter Web toe
app.add_middleware(
    CORSMiddleware, 
    allow_origins=["*"],  # voor test ok
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).resolve().parent
PHOTO_PATH = BASE_DIR / "photo.jpg"

@app.get("/")
def home():
    return {"message": "API is working"}


BASE_DIR = Path(__file__).resolve().parent
PHOTO_PATH = BASE_DIR / "photo.jpg"

#profilepic
from fastapi.staticfiles import StaticFiles

app.mount("/profilePic", StaticFiles(directory="profilePic"), name="profilePic")

import shutil
@app.post("/upload-profile-pic")
async def upload_profile_pic(file: UploadFile):
    file_path = f"profilePic/{file.filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"url": f"/profilePic/{file.filename}"}
@app.get("/profile/{user_id}")

def get_profile(user_id: int):
    with engine.connect() as connection:
        result = connection.execute(text("""
            SELECT username, bio, profile_pic_url
            FROM users
            WHERE user_id = :user_id
        """), {"user_id": user_id}).fetchone()

        if not result:
            return {"detail": "User not found"}

        return {
            "username": result.username,
            "about_me": result.bio if result.bio else "",
            "profile_picture": result.profile_pic_url if result.profile_pic_url else ""
        }

@app.put("/profile/{user_id}/update")
def update_profile(user_id: int, profile: ProfileUpdateRequest):
    with engine.connect() as connection:
        result = connection.execute(text("""
            UPDATE users
            SET username = :username,
                bio = :bio
            WHERE user_id = :user_id
        """), {
            "username": profile.username,
            "bio": profile.about_me,
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



@app.get("/items")
def get_items():
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
        """))

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
    
class MessageRequest(BaseModel):
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
    
   