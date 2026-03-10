from sqlalchemy import create_engine, text

SERVER = ".\\SQLEXPRESS"
DATABASE = "swipestyle"
DRIVER = "ODBC Driver 17 for SQL Server"

connection_string = (
    f"mssql+pyodbc://@{SERVER}/{DATABASE}"
    f"?driver={DRIVER.replace(' ', '+')}"
    "&trusted_connection=yes"
)

engine = create_engine(connection_string)

def test_connection():
    with engine.connect() as connection:
        result = connection.execute(text("SELECT 1"))
        return result.scalar()