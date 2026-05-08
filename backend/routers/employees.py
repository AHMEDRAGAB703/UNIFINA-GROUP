from fastapi import APIRouter, Depends, Query
from middleware.auth_guard import require_hr
from database import get_connection

router = APIRouter()

@router.get("/")
def get_employees(
    department: str = Query(None),
    branch: str = Query(None),
    search: str = Query(None),
    hr_user = Depends(require_hr)
):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    query = """
        SELECT e.employee_id, CONCAT(e.first_name,' ',e.last_name) AS full_name,
               e.job_title, e.email, e.phone, e.salary, e.status,
               e.work_arrangement, d.name AS department, b.branch_name
        FROM employees e
        JOIN departments d ON e.department_id = d.department_id
        JOIN branches b ON e.branch_id = b.branch_id
        WHERE 1=1
    """
    params = []

    if department:
        query += " AND d.name = %s"
        params.append(department)
    if branch:
        query += " AND b.branch_name LIKE %s"
        params.append(f"%{branch}%")
    if search:
        query += " AND (e.first_name LIKE %s OR e.last_name LIKE %s OR e.job_title LIKE %s)"
        params.extend([f"%{search}%", f"%{search}%", f"%{search}%"])

    query += " ORDER BY b.branch_name, d.name, e.last_name"

    cursor.execute(query, params)
    employees = cursor.fetchall()
    cursor.close()
    conn.close()
    return employees

@router.get("/{employee_id}")
def get_employee(employee_id: int, hr_user = Depends(require_hr)):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT e.*, CONCAT(e.first_name,' ',e.last_name) AS full_name,
               d.name AS department, d.division, b.branch_name,
               rc.card_uid, rc.is_active AS card_active
        FROM employees e
        JOIN departments d ON e.department_id = d.department_id
        JOIN branches b ON e.branch_id = b.branch_id
        LEFT JOIN rfid_cards rc ON e.employee_id = rc.employee_id
        WHERE e.employee_id = %s
    """, (employee_id,))
    employee = cursor.fetchone()
    cursor.close()
    conn.close()
    if not employee:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Employee not found")
    return employee