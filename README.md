--Testing

install requirements (backend)
pip install -r requirements.txt

Host on local server:
Back-end
virtual env:
python -m venv .venv

Backend starten:
uvicorn main:app --reload --host 0.0.0.0 --port 8000

controles get backend:
    cd /backend
 -> fastapi dev main.py


Front-end
    cd flutter/app
- run flutter in chrome
    flutter run -d chrome
- run flutter in emulator
    flutter emulators --launch emulator_id
    flutter run

    username: testuser1
    password: hashedpassword