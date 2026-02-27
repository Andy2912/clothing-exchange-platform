import base64
from pathlib import Path

from pathlib import Path
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

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