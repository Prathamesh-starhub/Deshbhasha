"""Pre-generate native-language audio for greetings and phrases.

    pip install gTTS
    DB_USER=root DB_PASSWORD=... python generate_audio.py

Writes MP3s under static/audio/ using the naming convention app.py expects:
    greetings/<language_id>.mp3
    phrases/<language_id>_<phrase_id>.mp3
Existing files are skipped, so it is safe to re-run after adding data.
Needs internet access (gTTS calls Google's TTS endpoint). Review the audio before
shipping: the engine can mispronounce, and Konkani/Marwari use the closest voice.
"""
import os
import time
from pathlib import Path

import mysql.connector
from gtts import gTTS
from gtts.lang import tts_langs

ROOT = Path(__file__).parent / "static" / "audio"
BORROWED = {"kok": "mr", "mwr": "hi"}  # no native voice: use the nearest language

conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='prathamesh', # Replace with your MySQL password
    database='tourism_db',
    charset="utf8mb4",
)
cur = conn.cursor(dictionary=True)
supported = set(tts_langs())

cur.execute("SELECT id, code FROM languages")
engine_lang = {r["id"]: BORROWED.get(r["code"], r["code"]) for r in cur.fetchall()}

jobs = []  # (language_id, text, relative output path)
cur.execute("SELECT language_id, native_text FROM greetings")
jobs += [(r["language_id"], r["native_text"], f"greetings/{r['language_id']}.mp3") for r in cur.fetchall()]
cur.execute("SELECT phrase_id, language_id, native_text FROM phrase_translations")
jobs += [(r["language_id"], r["native_text"], f"phrases/{r['language_id']}_{r['phrase_id']}.mp3") for r in cur.fetchall()]

made = skipped = unsupported = 0
for language_id, text, rel in jobs:
    lang = engine_lang[language_id]
    if lang not in supported:
        print(f"skip (gTTS has no '{lang}'): {rel}")
        unsupported += 1
        continue
    out = ROOT / rel
    if out.exists():
        skipped += 1
        continue
    out.parent.mkdir(parents=True, exist_ok=True)
    gTTS(text=text, lang=lang).save(str(out))
    made += 1
    time.sleep(0.4)  # be polite to the endpoint

print(f"done: {made} created, {skipped} already existed, {unsupported} unsupported")
conn.close()
