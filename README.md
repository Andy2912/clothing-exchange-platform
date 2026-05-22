SwipeStyle is a clothing exchange application built with Flutter, FastAPI and SQL Server.

How to setup:

---

Database
Run the SQL scripts inside the MicrosoftSQLServerManagment to create the database:

schema.sql
seed.sql

---

Run schema.sql first to create the database structure.
After that run seed.sql to insert the demo data.

Backend Setup
Create virtual environment
python -m venv .venv

Activate virtual environment (Windows)
.venv\Scripts\activate

Install requirements
pip install -r requirements.txt

Start backend
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000

Alternative FastAPI command
fastapi dev main.py

---

Frontend Setup
cd flutter/app

Run in Android Emulator and install/open emulator
flutter run

---

Test Accounts
Username: testuser{userNumber}
Password: hashedpassword