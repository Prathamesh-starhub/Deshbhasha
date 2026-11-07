8# DeshBhasha – Multilingual Indian Tourism Portal

### 📌 Project Overview
*   **Goal:** A mobile-first web app for tourists to explore Indian states through local languages.
*   **Core Workflow:** Users select a **State** → Select a **Language** → View curated content.
*   **Content Delivered:** Local greetings, cultural facts, curated places, and a speakable phrasebook.
*   **Lead Generation:** Visitors can register for more info via WhatsApp or phone call.

### 🌟 Key Features
*   **Smart Navigation:** Cascading dropdowns (Language menu unlocks only after State selection).
*   **Coverage:** Supports 10 States and 11 Languages (using many-to-many relationships).
*   **Audio Support:** Native text to speech using pre-generated MP3s or browser Web Speech API.
*   **Curated Places:** 50+ places across categories (Heritage, Nature, Food, Culture, Business).
*   **Interactive Phrasebook:** 9 essential travel phrases with phonetics, translation, and audio.
*   **Lead Capture:** "Register for Info" modal that captures specific contact preferences.

### 🛠 Tech Stack
*   **Frontend:** HTML5, Bootstrap 5 (CSS), Vanilla JS (Fetch API, Web Speech API).
*   **Backend:** Python 3, Flask, MySQL Connector (Pooled).
*   **Database:** MySQL 8 (UTF8mb4 for native scripts).
*   **Tools:** `gTTS` (Google Text-to-Speech) for generating audio assets.

### 📂 Database Structure (`tourism_db`)
*   **`states`**: Stores state facts, capital, and best season to visit.
*   **`languages`**: Stores native scripts and TTS locale codes (e.g., `hi-IN`).
*   **`state_languages`**: Links states to their spoken languages (many-to-many).
*   **`places`**: Tourist spots with categories, descriptions, and "Hidden Gem" flags.
*   **`greetings`**: Cultural greetings mapped to languages.
*   **`phrases` & `phrase_translations`**: Travel phrases translated into all 11 languages.
*   **`users`**: Registered leads with hashed passwords and contact preferences.

### 🔌 API Endpoints
*   `GET /`: Loads the main application.
*   `GET /api/states/<id>/languages`: Fetches available languages for a state.
*   `GET /api/destination`: Returns state stats, greeting, and audio URL.
*   `GET /api/phrasebook`: Returns translated phrases for the selected language.
*   `GET /api/states/<id>/places`: Returns curated places with images.
*   `POST /api/register`: Saves user contact details and preferences.

### 🚀 Setup Instructions
1.  **Prerequisites:** Install Python 3 and MySQL Server.
2.  **Dependencies:** Run `pip install -r requirements.txt`.
3.  **Database Init:** Import the schema using `mysql -u root -p < db.sql`.
4.  **Configuration:** Set environment variables `DB_USER` and `DB_PASSWORD`.
5.  **Run:** Execute `python app.py` and visit `http://127.0.0.1:5000`.

### 📸 Content Management
*   **Images:** Place JPG/PNG files in `static/images/places/` matching the `image_slug`.
*   **Audio:** Run `python generate_audio.py` to auto-create missing speech files.
*   **Data:** Edit `db.sql` or use SQL `INSERT` commands to add new states/places.

### ⚠️ Current Limitations
*   **Native Content:** Translations need verification by native speakers.
*   **Audio:** Some dialects (e.g., Marwari) fall back to the nearest major language voice (Hindi).
*   **Security:** Registration does not yet include email verification or rate limiting.

Al Acknowledgment: This project was developed with assistance from Claude for code generation, and Ul development.
