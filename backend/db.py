from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

load_dotenv()

SERVER = os.getenv("DB_SERVER", ".\\SQLEXPRESS")
DATABASE = os.getenv("DB_NAME", "swipestyle")
DRIVER = "ODBC Driver 17 for SQL Server"

# Build connection string with encryption enabled
# Use environment variables for credentials if provided, otherwise use trusted connection
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")

if db_user and db_password:
    # Username/password authentication (with encryption)
    connection_string = (
        f"mssql+pyodbc://{db_user}:{db_password}@{SERVER}/{DATABASE}"
        f"?driver={DRIVER.replace(' ', '+')}"
        "&Encrypt=yes"
        "&TrustServerCertificate=yes"
    )
else:
    # Windows trusted connection (with encryption)
    connection_string = (
        f"mssql+pyodbc://@{SERVER}/{DATABASE}"
        f"?driver={DRIVER.replace(' ', '+')}"
        "&trusted_connection=yes"
        "&Encrypt=yes"
        "&TrustServerCertificate=yes"
    )

engine = create_engine(connection_string)

def test_connection():
    with engine.connect() as connection:
        result = connection.execute(text("SELECT 1"))
        return result.scalar()