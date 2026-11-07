document.addEventListener("DOMContentLoaded", () => {
    const $ = (id) => document.getElementById(id);
    const stateSelect = $("stateSelect");
    const languageSelect = $("languageSelect");
    const alertBox = $("alertBox");
    const emptyState = $("emptyState");
    const loading = $("loading");
    const content = $("content");

    // Safe DOM builder: text always goes through textContent/append, never innerHTML.
    const el = (tag, props = {}, ...kids) => {
        const node = Object.assign(document.createElement(tag), props);
        kids.forEach((k) => node.append(k));
        return node;
    };

    async function getJSON(url, options) {
        const res = await fetch(url, options);
        if (!res.ok) {
            const body = await res.json().catch(() => ({}));
            if (body.detail) console.error(body.detail); // present only when Flask runs in debug mode
            throw new Error(body.error || `Request failed (${res.status})`);
        }
        return res.json();
    }

    /* ---------- Toast ---------- */
    const toastEl = $("toast");
    let toastTimer;
    function toast(msg) {
        toastEl.textContent = msg;
        toastEl.classList.add("show");
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => toastEl.classList.remove("show"), 2600);
    }
    const showError = (msg) => { alertBox.textContent = msg; alertBox.classList.remove("d-none"); };
    const clearError = () => alertBox.classList.add("d-none");

    /* ---------- Text-to-speech (Web Speech API) ---------- */
    const hasTTS = "speechSynthesis" in window;
    let voices = [];
    if (hasTTS) {
        const loadVoices = () => { voices = speechSynthesis.getVoices(); };
        loadVoices();
        // Chrome populates voices asynchronously.
        speechSynthesis.addEventListener("voiceschanged", loadVoices);
    }
    const norm = (tag) => tag.toLowerCase().replace("_", "-"); // Android reports "mr_IN"

    // True when the device has a voice for this language (e.g. "mr-IN" matches any "mr-*").
    const findVoice = (locale) => {
        const want = norm(locale);
        return (
            voices.find((v) => norm(v.lang) === want) ||
            voices.find((v) => norm(v.lang).split("-")[0] === want.split("-")[0])
        );
    };

    let currentAudio = null;
    function stopAll() {
        if (hasTTS) speechSynthesis.cancel();
        if (currentAudio) { currentAudio.pause(); currentAudio = null; }
    }

    // Preference order: pre-recorded file -> matching device voice -> honest "unavailable" message.
    function speak(text, locale, btn, audioUrl) {
        stopAll();
        if (audioUrl) {
            const audio = new Audio(audioUrl);
            currentAudio = audio;
            btn?.classList.add("speaking");
            audio.onended = audio.onerror = () => btn?.classList.remove("speaking");
            audio.play().catch(() => { btn?.classList.remove("speaking"); toast("Couldn't play the audio file."); });
            return;
        }
        const voice = hasTTS ? findVoice(locale) : null;
        if (!voice) {
            // Never read Indic script with an unrelated default voice: it sounds like a different language.
            return toast(`No ${locale} voice on this device. Try Chrome on Android, Edge, or add audio files.`);
        }
        const utter = new SpeechSynthesisUtterance(text);
        utter.voice = voice;
        utter.lang = voice.lang;
        utter.rate = 0.85; // slower is easier to imitate
        btn?.classList.add("speaking");
        utter.onend = utter.onerror = () => btn?.classList.remove("speaking");
        speechSynthesis.speak(utter);
    }

    // Visually mark buttons that cannot play anything on this device.
    const markAvailability = (btn, locale, audioUrl) => {
        const ok = Boolean(audioUrl) || (hasTTS && findVoice(locale));
        btn.classList.toggle("unavailable", !ok);
        if (!ok) btn.title = "No voice for this language on this device";
    };

    async function copyText(text) {
        try {
            await navigator.clipboard.writeText(text);
        } catch {
            const ta = el("textarea", { value: text });
            ta.style.position = "fixed";
            ta.style.opacity = "0";
            document.body.append(ta);
            ta.select();
            const ok = document.execCommand("copy");
            ta.remove();
            if (!ok) return toast("Couldn't copy to clipboard.");
        }
        toast("Copied to clipboard");
    }

    /* ---------- Cascading dropdowns ---------- */
    function setLanguageOptions(placeholder, languages = []) {
        languageSelect.replaceChildren(
            el("option", { value: "", selected: true, disabled: true, textContent: placeholder })
        );
        languages.forEach((l) => languageSelect.append(el("option", { value: l.id, textContent: l.name })));
        languageSelect.disabled = languages.length === 0;
    }

    const showOnly = (which) => {
        emptyState.classList.toggle("d-none", which !== "empty");
        loading.classList.toggle("d-none", which !== "loading");
        content.classList.toggle("d-none", which !== "content");
    };

    let loadToken = 0;
    let langAbort = null; // cancels a stale languages request if the state changes again
    stateSelect.addEventListener("change", async () => {
        langAbort?.abort();
        langAbort = new AbortController();
        ++loadToken; // invalidate any in-flight destination load
        stopAll();
        clearError();
        showOnly("empty");
        setLanguageOptions("Loading languages…");
        try {
            const langs = await getJSON(`/api/states/${stateSelect.value}/languages`, { signal: langAbort.signal });
            setLanguageOptions(langs.length ? "Choose a language…" : "No languages found", langs);
        } catch (err) {
            if (err.name === "AbortError") return;
            setLanguageOptions("Error loading languages");
            showError(err.message);
        }
    });

    /* ---------- Destination + phrasebook ---------- */
    const view = { language: null, phrases: [], categories: [], category: "all", query: "", places: [], placeCat: "all" };

    languageSelect.addEventListener("change", async () => {
        const token = ++loadToken;
        clearError();
        showOnly("loading");
        const qs = new URLSearchParams({ state_id: stateSelect.value, language_id: languageSelect.value });
        try {
            const [dest, book, places] = await Promise.all([
                getJSON(`/api/destination?${qs}`),
                getJSON(`/api/phrasebook?${qs}`),
                getJSON(`/api/states/${stateSelect.value}/places`),
            ]);
            if (token !== loadToken) return; // a newer selection superseded this one
            view.language = dest.language;
            view.overview = dest.state.overview;
            view.phrases = book.phrases;
            view.categories = book.categories;
            view.category = "all";
            view.query = "";
            view.places = places;
            view.placeCat = "all";
            $("phraseSearch").value = "";
            renderGreeting(dest);
            renderStats(dest);
            renderExplore(dest.state.name);
            renderPhrasebook();
            showOnly("content");
        } catch (err) {
            if (token !== loadToken) return;
            showOnly("empty");
            showError(err.message);
        }
    });

    function renderGreeting({ greeting, language, state }) {
        const card = $("greetingCard");
        if (!greeting) { card.classList.add("d-none"); return; }
        card.classList.remove("d-none");
        $("greetingEyebrow").textContent = `Cultural greeting · ${language.name}`;
        const native = $("greetingNative");
        native.textContent = greeting.native_text;
        native.lang = language.code;
        native.dir = language.script === "Perso-Arabic" ? "rtl" : "ltr"; // Urdu reads right-to-left
        $("greetingPhonetic").textContent = greeting.phonetic;
        $("greetingEnglish").textContent = `“${greeting.english_text}”`;
        // Replace the node to drop old listeners from the previous selection.
        const old = $("greetingAudio");
        const fresh = old.cloneNode(true);
        old.replaceWith(fresh);
        markAvailability(fresh, language.tts_locale, greeting.audio_url);
        fresh.addEventListener("click", () => speak(greeting.native_text, language.tts_locale, fresh, greeting.audio_url));
    }

    function renderStats({ state, language }) {
        $("statCapital").textContent = state.capital;
        $("statSeason").textContent = state.best_season;
        $("statScript").textContent = language.script;
        $("statTip").textContent = state.quick_tip;
    }


    /* ---------- Explore & Experience (places) ---------- */
    const CATS = {
        heritage: { label: "Heritage", icon: "bi-bank" },
        nature:   { label: "Nature", icon: "bi-tree-fill" },
        food:     { label: "Food", icon: "bi-cup-hot-fill" },
        culture:  { label: "Culture", icon: "bi-music-note-beamed" },
        business: { label: "Local Business", icon: "bi-shop" },
    };

    function renderExplore(stateName) {
        $("aboutEyebrow").textContent = `About ${stateName}`;
        $("aboutText").textContent = view.overview || "";
        renderPlacePills();
        renderPlaceList();
    }

    function renderPlacePills() {
        const row = $("explorePills");
        row.replaceChildren();
        const present = Object.keys(CATS).filter((c) => view.places.some((p) => p.category === c));
        const make = (slug, label) => {
            const pill = el("button", {
                type: "button",
                className: "pill" + (view.placeCat === slug ? " active" : ""),
                textContent: label,
            });
            pill.setAttribute("role", "tab");
            pill.setAttribute("aria-selected", String(view.placeCat === slug));
            pill.addEventListener("click", () => { view.placeCat = slug; renderPlacePills(); renderPlaceList(); });
            row.append(pill);
        };
        make("all", "All");
        present.forEach((c) => make(c, CATS[c].label));
    }

    function renderPlaceList() {
        const list = $("placeList");
        list.replaceChildren();
        const shown = view.places.filter((p) => view.placeCat === "all" || p.category === view.placeCat);
        if (!shown.length) {
            list.append(el("p", { className: "text-muted text-center py-3", textContent: "No places added yet." }));
            return;
        }
        shown.forEach((p) => {
            const cat = CATS[p.category];
            const meta = el("div", { className: "place-meta" },
                el("span", { className: "cat-badge" }, el("i", { className: `bi ${cat.icon} me-1` }), cat.label));
            if (p.is_hidden_gem) {
                meta.append(el("span", { className: "gem-badge" }, el("i", { className: "bi bi-gem me-1" }), "Hidden gem"));
            }
            const placeholder = () => el("div", { className: "place-img-placeholder" },
                el("i", { className: `bi ${cat.icon}` }));
            const media = el("div", { className: "place-media" });
            if (p.image_url) {
                const img = el("img", { className: "place-img", src: p.image_url, alt: p.name, loading: "lazy" });
                img.addEventListener("error", () => img.replaceWith(placeholder())); // broken file -> placeholder
                media.append(img);
            } else {
                media.append(placeholder());
            }
            if (p.image_url && p.image_credit) {
                media.append(el("div", { className: "photo-credit", textContent: `Photo: ${p.image_credit}` }));
            }
            // Create the Register button
            const regBtn = el("button", { 
                type: "button", 
                className: "btn btn-gold w-100 mt-3", 
                textContent: "For more information register" 
            });
            regBtn.addEventListener("click", () => openRegisterModal(p.id));

            const card = el("article", { className: "place-card" },
                media,
                meta,
                el("h3", { className: "place-name", textContent: p.name }),
                el("div", { className: "place-loc" }, el("i", { className: "bi bi-geo-alt-fill me-1" }), p.location),
                el("p", { className: "place-desc", textContent: p.description }),
                el("div", { className: "place-why" }, el("strong", { textContent: "Why it matters: " }), p.importance),
                regBtn // <-- Added the button here
            );
            card.dataset.cat = p.category;
            list.append(card);
        });
    }

    /* ---------- Phrasebook rendering & filtering ---------- */
    function renderPhrasebook() {
        const hasPhrases = view.phrases.length > 0;
        $("phrasebookTools").classList.toggle("d-none", !hasPhrases);
        renderPills();
        renderPhraseList();
    }

    function renderPills() {
        const row = $("pillRow");
        row.replaceChildren();
        const make = (slug, label) => {
            const pill = el("button", {
                type: "button",
                className: "pill" + (view.category === slug ? " active" : ""),
                textContent: label,
            });
            pill.setAttribute("role", "tab");
            pill.setAttribute("aria-selected", String(view.category === slug));
            pill.addEventListener("click", () => {
                view.category = slug;
                renderPills();
                renderPhraseList();
            });
            row.append(pill);
        };
        make("all", "All Situations");
        view.categories.forEach((c) => make(c.slug, c.name));
    }

    function renderPhraseList() {
        const list = $("phraseList");
        list.replaceChildren();

        if (!view.phrases.length) {
            list.append(el("p", { className: "text-muted text-center py-3",
                textContent: `The ${view.language.name} phrasebook is coming soon.` }));
            return;
        }

        const q = view.query.trim().toLowerCase();
        const matches = view.phrases.filter((p) =>
            (view.category === "all" || p.category_slug === view.category) &&
            (!q || [p.english, p.native, p.phonetic].some((s) => s.toLowerCase().includes(q)))
        );

        if (!matches.length) {
            list.append(el("p", { className: "text-muted text-center py-3", textContent: "No phrases match your search." }));
            return;
        }

        matches.forEach((p) => {
            const copyBtn = el("button", { type: "button", className: "icon-btn" },
                el("i", { className: "bi bi-clipboard" }));
            copyBtn.setAttribute("aria-label", `Copy ${p.english} in ${view.language.name}`);
            copyBtn.addEventListener("click", () => copyText(p.native));

            const speakBtn = el("button", { type: "button", className: "icon-btn speak" },
                el("i", { className: "bi bi-volume-up-fill" }));
            speakBtn.setAttribute("aria-label", `Play ${p.english} in ${view.language.name}`);
            markAvailability(speakBtn, view.language.tts_locale, p.audio_url);
            speakBtn.addEventListener("click", () => speak(p.native, view.language.tts_locale, speakBtn, p.audio_url));

            list.append(
                el("article", { className: "phrase-card" },
                    el("div", { className: "phrase-english", textContent: p.english }),
                    el("div", { className: "phrase-native", lang: view.language.code, dir: view.language.script === "Perso-Arabic" ? "rtl" : "ltr", textContent: p.native }),
                    el("div", { className: "phonetic", textContent: p.phonetic }),
                    el("div", { className: "phrase-actions" }, copyBtn, speakBtn))
            );
        });
    }

    $("phraseSearch").addEventListener("input", (e) => {
        view.query = e.target.value;
        renderPhraseList();
    });
        });
    // Opens the Modal and sets the specific Place ID
function openRegisterModal(placeId) {
    document.getElementById('regPlaceId').value = placeId;
    document.getElementById('registerForm').reset();
    
    // Bootstrap 5 Modal API
    const modal = new bootstrap.Modal(document.getElementById('registerModal'));
    modal.show();
}

// Handles form submission
async function submitRegistration(event) {
    event.preventDefault(); 

    const placeId = document.getElementById('regPlaceId').value;
    const name = document.getElementById('regName').value.trim();
    const phone = document.getElementById('regPhone').value.trim();
    const contactPref = document.querySelector('input[name="contactPref"]:checked').value;

    if (!name || !phone) {
        alert("Please fill in all fields.");
        return;
    }

    try {
        const response = await fetch('/api/register-interest', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: name,
                phone: phone,
                contact_preference: contactPref,
                place_id: parseInt(placeId)
            })
        });

        // Get raw text first (catches HTML error pages)
        const text = await response.text();
        
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.error("Flask returned HTML instead of JSON. Check your Flask terminal!", text);
            alert("Server crashed. Please check your terminal.");
            return;
        }

        if (response.ok) {
            const modalEl = document.getElementById('registerModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            modal.hide();
            alert(data.message); // Success!
        } else {
            alert("Error: " + (data.error || 'Registration failed'));
        }
    } catch (err) {
        console.error('Fetch Error:', err);
        alert('Network error. Is your Flask server running?');
    }
}

