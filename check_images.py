"""List every place, the photo file name it expects, and whether the file exists.

    set DB_USER=root
    set DB_PASSWORD=your_password
    python check_images.py

Also rewrites IMAGE_CHECKLIST.md. Accepted extensions: .jpg .jpeg .png .webp
"""
import os
from pathlib import Path

import mysql.connector

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'prathamesh', # Replace with your MySQL password
    'database': 'tourism_db',
    'charset': "utf8mb4",
}
FOLDER = Path(__file__).parent / "static" / "images" / "places"
EXTS = (".jpg", ".jpeg", ".png", ".webp")

conn = mysql.connector.connect(**DB_CONFIG)
cur = conn.cursor(dictionary=True)
cur.execute(
    """
    SELECT s.name AS state, p.category, p.name, p.location, p.image_slug
    FROM places p JOIN states s ON s.id = p.state_id
    ORDER BY s.name, FIELD(p.category,'heritage','nature','food','culture','business'), p.id
    """
)
rows = cur.fetchall()
conn.close()

def found(slug):
    return next((slug + e for e in EXTS if (FOLDER / (slug + e)).is_file()), None)

lines = ["# Place photo checklist", "",
         "Save each photo in `static/images/places/` using the file name shown (`.jpg`, `.png` or `.webp`).", "",
         "| Done | State | Category | Place | Location | File name |", "|---|---|---|---|---|---|"]
have = 0
for r in rows:
    f = found(r["image_slug"])
    have += bool(f)
    lines.append(f"| {'x' if f else ' '} | {r['state']} | {r['category']} | {r['name']} | {r['location']} | `{r['image_slug']}.jpg` |")
    print(("OK      " if f else "MISSING ") + f"{r['state']:14} {r['name']:36} -> {r['image_slug']}.jpg")
(Path(__file__).parent / "IMAGE_CHECKLIST.md").write_text("\n".join(lines) + "\n", encoding="utf8")
print(f"\n{have} of {len(rows)} photos present. Checklist written to IMAGE_CHECKLIST.md")
