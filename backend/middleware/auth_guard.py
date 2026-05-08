from fastapi import HTTPException, Header
from jose import jwt, JWTError
from config import SECRET_KEY, ALGORITHM

def require_hr(authorization: str = Header(...)):
    try:
        token = authorization.replace("Bearer ", "")
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("role") not in ["hr", "admin"]:
            raise HTTPException(status_code=403, detail="HR access required")
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")