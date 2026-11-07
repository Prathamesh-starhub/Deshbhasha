import logging
import os
from contextlib import contextmanager

from flask import Flask, jsonify, render_template, request, url_for
from mysql.connector import Error as MySQLError
from mysql.connector import pooling

app = Flask(__name__)
log = logging.getLogger(__name__)

# Local development credentials. Don't commit or share this file with a real password.
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'prathamesh',  # Replace with your MySQL password
    'database': 'tourism_db',
    'charset': 'utf8mb4',
}
pool = pooling.MySQLConnectionPool(pool_name="deshbhasha", pool_size=5, **DB_CONFIG)


@contextmanager
def db_cursor():
    """Borrow a pooled connection and always hand it back, even on error."""
    conn = pool.get_connection()
    try:
        cur = conn.cursor(dictionary=True)
        try:
            yield cur
            conn.commit()      # <-- Automatically saves the data!
        except Exception:
            conn.rollback()    # <-- Undoes the data if there's an error
            raise
        finally:
            cur.close()
    finally:
        conn.close()  # releases to the pool

def audio_url(rel_path):
    """URL of a pre-generated audio file under static/audio/, or None if it doesn't exist."""
    full = os.path.join(app.static_folder, "audio", rel_path)
    return url_for("static", filename=f"audio/{rel_path}") if os.path.isfile(full) else None


IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".webp")


def image_url(slug):
    """URL of static/images/places/<slug>.<ext> if a file exists, else None."""
    if not slug:
        return None
    folder = os.path.join(app.static_folder, "images", "places")
    for ext in IMAGE_EXTS:
        if os.path.isfile(os.path.join(folder, slug + ext)):
            return url_for("static", filename=f"images/places/{slug}{ext}")
    return None


def error(message, status, detail=None):
    body = {"error": message}
    if detail and app.debug:  # never leak driver internals in production
        body["detail"] = detail
    return jsonify(body), status


def selection_args():
    """Parse and validate ?state_id=&language_id= ; returns (state_id, language_id) or None."""
    state_id = request.args.get("state_id", type=int)
    language_id = request.args.get("language_id", type=int)
    if state_id is None or language_id is None:
        return None
    return state_id, language_id


@app.route("/")
def index():
    with db_cursor() as cur:
        cur.execute("SELECT id, name FROM states ORDER BY name")
        states = cur.fetchall()
    return render_template("index.html", states=states)


@app.route("/api/states/<int:state_id>/languages")
def get_languages(state_id):
    with db_cursor() as cur:
        cur.execute(
            """
            SELECT l.id, l.name, l.code, sl.is_primary
            FROM state_languages sl
            JOIN languages l ON l.id = sl.language_id
            WHERE sl.state_id = %s
            ORDER BY sl.is_primary DESC, l.name
            """,
            (state_id,),
        )
        rows = cur.fetchall()
    for r in rows:
        r["is_primary"] = bool(r["is_primary"])
    return jsonify(rows)


@app.route("/api/states/<int:state_id>/places")
def get_places(state_id):
    """Heritage / nature / food / culture / business highlights for a state."""
    with db_cursor() as cur:
        cur.execute(
            """
            SELECT id, category, name, location, description, importance, is_hidden_gem,
                   image_slug, image_credit
            FROM places
            WHERE state_id = %s
            ORDER BY FIELD(category, 'heritage', 'nature', 'food', 'culture', 'business'), id
            """,
            (state_id,),
        )
        rows = cur.fetchall()
    for r in rows:
        r["is_hidden_gem"] = bool(r["is_hidden_gem"])
        r["image_url"] = image_url(r.pop("image_slug"))
    return jsonify(rows)


@app.route("/api/destination")
def get_destination():
    """State stats + language metadata + greeting for one (state, language) pair."""
    args = selection_args()
    if args is None:
        return error("state_id and language_id are required integers", 400)
    state_id, language_id = args

    with db_cursor() as cur:
        # The join on state_languages also proves the language is spoken in the state.
        cur.execute(
            """
            SELECT s.name AS state_name, s.capital, s.best_season, s.quick_tip, s.overview,
                   l.id AS language_id, l.name AS language_name, l.code,
                   l.script, l.tts_locale
            FROM states s
            JOIN state_languages sl ON sl.state_id = s.id
            JOIN languages l        ON l.id = sl.language_id
            WHERE s.id = %s AND l.id = %s
            """,
            (state_id, language_id),
        )
        row = cur.fetchone()
        if row is None:
            return error("language is not spoken in this state", 404)

        cur.execute(
            "SELECT native_text, english_text, phonetic FROM greetings WHERE language_id = %s",
            (language_id,),
        )
        greeting = cur.fetchone()  # may be None
        if greeting:
            greeting["audio_url"] = audio_url(f"greetings/{language_id}.mp3")

    return jsonify({
        "state": {
            "name": row["state_name"], "capital": row["capital"],
            "best_season": row["best_season"], "quick_tip": row["quick_tip"],
            "overview": row["overview"],
        },
        "language": {
            "id": row["language_id"], "name": row["language_name"], "code": row["code"],
            "script": row["script"], "tts_locale": row["tts_locale"],
        },
        "greeting": greeting,
    })


@app.route("/api/phrasebook")
def get_phrasebook():
    """All phrases available in the chosen language, grouped by category order."""
    args = selection_args()
    if args is None:
        return error("state_id and language_id are required integers", 400)
    _, language_id = args

    with db_cursor() as cur:
        cur.execute(
            """
            SELECT p.id, c.slug AS category_slug, c.name AS category_name,
                   p.english_text AS english, t.native_text AS native, t.phonetic
            FROM phrases p
            JOIN phrase_categories c  ON c.id = p.category_id
            JOIN phrase_translations t ON t.phrase_id = p.id AND t.language_id = %s
            ORDER BY c.sort_order, p.id
            """,
            (language_id,),
        )
        phrases = cur.fetchall()
    for p in phrases:
        p["audio_url"] = audio_url(f"phrases/{language_id}_{p['id']}.mp3")

    categories, seen = [], set()
    for p in phrases:
        if p["category_slug"] not in seen:
            seen.add(p["category_slug"])
            categories.append({"slug": p["category_slug"], "name": p["category_name"]})
    return jsonify({"categories": categories, "phrases": phrases})

@app.route("/api/register-interest", methods=["POST"])
def register_interest():
    try:
        data = request.get_json()
        if not data:
            return error("Missing JSON payload", 400)

        name = data.get("name", "").strip()
        phone = data.get("phone", "").strip()
        contact_preference = data.get("contact_preference")
        place_id = data.get("place_id")

        if not name or not phone or contact_preference not in ['whatsapp', 'call'] or not place_id:
            return error("All fields are required.", 400)

        with db_cursor() as cur:
            # 1. Check if place exists
            cur.execute("SELECT id FROM places WHERE id = %s", (place_id,))
            if not cur.fetchone():
                return jsonify({"error": f"Place with ID {place_id} not found in database."}), 404

            # 2. Insert user details
            cur.execute(
                """
                INSERT INTO users (name, phone, contact_preference, place_id)
                VALUES (%s, %s, %s, %s)
                """,
                (name, phone, contact_preference, place_id)
            )
        

        return jsonify({"message": "Registration successful! We will contact you soon."}), 201
        
    except Exception as e:
        import traceback
        traceback.print_exc() # This prints the red error in your Flask terminal
        return jsonify({"error": f"Database error: {str(e)}"}), 500


if __name__ == "__main__":
    app.run(debug=os.getenv("FLASK_DEBUG") == "1")