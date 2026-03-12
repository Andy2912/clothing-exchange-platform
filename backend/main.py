import base64
from pathlib import Path
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from db import engine
from sqlalchemy import text

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

# ✅ Base64 JSON
@app.get("/photo")
def get_photo_base64():
    with open(PHOTO_PATH, "rb") as f:
        encoded = base64.b64encode(f.read()).decode("utf-8")
    return {"image": encoded}

@app.get("/photo")
def get_photo():
    with open(PHOTO_PATH, "rb") as f:
        encoded = base64.b64encode(f.read()).decode("utf-8")
    return {"image": encoded}

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