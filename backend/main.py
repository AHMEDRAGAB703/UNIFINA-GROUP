from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routers import auth, employees, attendance, public
app = FastAPI(title="Unifina Group API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(public.router, prefix="/api/public", tags=["Public"])
app.include_router(employees.router, prefix="/api/hr/employees", tags=["HR - Employees"])
app.include_router(attendance.router, prefix="/api/hr/attendance", tags=["HR - Attendance"])

app.mount("/", StaticFiles(directory="../frontend", html=True), name="frontend")