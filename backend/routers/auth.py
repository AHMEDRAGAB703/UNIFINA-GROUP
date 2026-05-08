from fastapi import APIRouter, HTTPException
from schemas.user import LoginRequest, SignupRequest, TokenResponse
from database import get_connection
from jose import jwt
from datetime import datetime, timedelta
from config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES

router = APIRouter()

@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE email = %s", (data.email,))
    user = cursor.fetchone()
    cursor.close()
    conn.close()

    if not user or user["password_hash"] != data.password:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token_data = {
        "sub": str(user["id"]),
        "role": user["role"],
        "exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    }
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    return {"access_token": token, "role": user["role"]}

@router.post("/signup")
def signup(data: SignupRequest, admin_code: str = "UNIFINA-ADMIN-2025"):
    if admin_code != "UNIFINA-ADMIN-2025":
        raise HTTPException(status_code=403, detail="Invalid admin code")
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO users (email, password_hash, full_name, role) VALUES (%s, %s, %s, 'hr')",
            (data.email, data.password, data.full_name)
        )
        conn.commit()
    except Exception as e:
        raise HTTPException(status_code=400, detail="Email already exists")
    finally:
        cursor.close()
        conn.close()
    return {"message": "HR account created successfully"}