from fastapi import APIRouter, Depends, Query
from middleware.auth_guard import require_hr
from database import get_connection
from datetime import datetime
import os

router = APIRouter()

@router.get("/")
def get_attendance(
    date: str = Query(None),
    branch: str = Query(None),
    hr_user = Depends(require_hr)
):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    query = """
        SELECT a.attendance_id, CONCAT(e.first_name,' ',e.last_name) AS full_name,
               b.branch_name, d.name AS department,
               DATE(a.scan_time) AS work_date, a.scan_type,
               TIME(a.scan_time) AS scan_time, a.attendance_type,
               a.scan_source, a.status, a.reader_location
        FROM attendance a
        JOIN employees e ON a.employee_id = e.employee_id
        JOIN branches b ON a.branch_id = b.branch_id
        JOIN departments d ON e.department_id = d.department_id
        WHERE 1=1
    """
    params = []

    if date:
        query += " AND DATE(a.scan_time) = %s"
        params.append(date)
    if branch:
        query += " AND b.branch_name LIKE %s"
        params.append(f"%{branch}%")

    query += " ORDER BY a.scan_time DESC"

    cursor.execute(query, params)
    records = cursor.fetchall()
    cursor.close()
    conn.close()
    return records

@router.get("/late-report")
def get_late_report(hr_user = Depends(require_hr)):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT CONCAT(e.first_name,' ',e.last_name) AS full_name,
               b.branch_name, d.name AS department,
               COUNT(*) AS late_arrivals
        FROM attendance a
        JOIN employees e ON a.employee_id = e.employee_id
        JOIN branches b ON e.branch_id = b.branch_id
        JOIN departments d ON e.department_id = d.department_id
        WHERE a.scan_type = 'Check-In' AND a.status = 'Late'
        GROUP BY e.employee_id, full_name, b.branch_name, d.name
        HAVING late_arrivals >= 1
        ORDER BY late_arrivals DESC
    """)
    records = cursor.fetchall()
    cursor.close()
    conn.close()
    return records

@router.post("/rfid-scan")
def rfid_scan(card_uid: str, scanner_secret: str, location: str = "Main Entrance", branch_id: int = 1):
    if scanner_secret != os.getenv("SCANNER_SECRET", "rfid-scanner-key-2025"):
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Unauthorized scanner")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT rc.employee_id, rc.is_active,
               CONCAT(e.first_name,' ',e.last_name) AS full_name
        FROM rfid_cards rc
        JOIN employees e ON rc.employee_id = e.employee_id
        WHERE rc.card_uid = %s
    """, (card_uid,))
    card = cursor.fetchone()

    if not card or not card["is_active"]:
        cursor.execute("""
            INSERT INTO rfid_unknown_scans (card_uid, scan_time, reader_location, branch_id, flagged)
            VALUES (%s, %s, %s, %s, TRUE)
        """, (card_uid, datetime.now(), location, branch_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"result": "UNKNOWN_OR_INACTIVE", "card_uid": card_uid}

    cursor.execute("""
        SELECT scan_type FROM attendance
        WHERE employee_id = %s AND DATE(scan_time) = CURDATE()
        ORDER BY scan_time DESC LIMIT 1
    """, (card["employee_id"],))
    last = cursor.fetchone()

    scan_type = "Check-In" if not last or last["scan_type"] == "Check-Out" else "Check-Out"
    status = "On Time"

    if scan_type == "Check-In" and datetime.now().hour >= 9 and datetime.now().minute > 15:
        status = "Late"

    cursor.execute("""
        INSERT INTO attendance (employee_id, card_uid, scan_time, scan_type, reader_location, scan_source, attendance_type, status, branch_id)
        VALUES (%s, %s, %s, %s, %s, 'RFID', 'On-Site', %s, %s)
    """, (card["employee_id"], card_uid, datetime.now(), scan_type, location, status, branch_id))
    conn.commit()
    cursor.close()
    conn.close()

    return {
        "result": "OK",
        "employee": card["full_name"],
        "scan_type": scan_type,
        "status": status
    }