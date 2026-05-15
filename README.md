-Testing
Host on local server:
Back-end
virtual env:
python -m venv .venv

install requirements (backend)
pip install -r requirements.txt

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


delete trade:
    DELETE FROM [swipestyle].[dbo].[trades]
    WHERE trade_id = 1;


Error .env file:
    if you get: An environment file is configured but terminal environment injection is disabled. Enable "python.terminal.useEnvFile" to use environment variables from .env files in terminals.

    Press Ctrl + , to open Settings
    Search for python.terminal.useEnvFile
    Check the box to enable it
    Restart your terminal