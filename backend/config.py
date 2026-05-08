from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_HOST = "localhost"
DATABASE_USER = "root"
DATABASE_PASSWORD = os.getenv("DATABASE_URL", "").split(":")[2].split("@")[0] if os.getenv("DATABASE_URL") else "1234"
DATABASE_NAME = "unifina_group"

SECRET_KEY = os.getenv("SECRET_KEY", "unifina-super-secret-key-2025")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 8

SCANNER_SECRET = os.getenv("SCANNER_SECRET", "rfid-scanner-key-2025")