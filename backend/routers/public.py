from fastapi import APIRouter
from database import get_connection

router = APIRouter()

@router.get("/team")
def get_public_team():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT e.employee_id, CONCAT(e.first_name,' ',e.last_name) AS full_name,
               e.job_title, d.name AS department, d.division, b.branch_name
        FROM employees e
        JOIN departments d ON e.department_id = d.department_id
        JOIN branches b ON e.branch_id = b.branch_id
        WHERE e.status = 'Active'
        ORDER BY e.hire_date
    """)
    team = cursor.fetchall()
    cursor.close()
    conn.close()
    return team

@router.post("/contact")
def submit_contact(name: str, email: str, message: str, phone: str = None):
    return {"message": "Thank you for contacting Unifina Group. We will get back to you shortly."}