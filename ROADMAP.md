# 🎮 Evolution Clicker — Roadmap

## ✅ Bereits implementiert
- [x] Grundgerüst (HTML/CSS/JS in einer Datei)
- [x] Klick-Mechanik (Zelle anklicken für DNA)
- [x] 12 Auto-Upgrades (linearer Freischalt-Baum)
- [x] 12 Klick-Upgrades (linearer Freischalt-Baum)
- [x] Mobile-First Design (Portrait, Touch-optimiert)
- [x] Prestige-System (x2/x4/x8... Multiplier)
- [x] Auto-Clicker (1-50 Klicks/s)
- [x] Offline-Earnings (bis 2h)
- [x] localStorage Speicherstand
- [x] Big Numbers (K, M, B, T, Q)

---

## 🐛 Bekannte Bugs (Fixen vor neuen Features)

### Bug 1: Zelle verschwindet bei Tab-Wechsel
**Problem:** Wenn man auf "Klick" oder "Boosts" tab drückt, wird die Zelle versteckt.
**Ursache:** Code versucht `mainArea` zu togglen, aber es gibt keinen "Main" Tab.
**Fix:** Entferne `mainArea.classList.toggle(...)` aus `switchTab()`.
**Status:** 🔧 Behoben in v2.1

### Bug 2: Auto-Clicker klickt nicht auf die Zelle
**Problem:** Auto-Clicker erhöht DNA, aber es fehlt die visuelle Animation.
**Fix:** Auto-Clicker soll `clickCell()` aufrufen (mit Animation & Floating Text).
**Status:** ⏳ Offen

### Bug 3: Mehrfach-Touch auf Mobile
**Problem:** Doppel-tap zoomt die Seite auf Mobile Browsern.
**Fix:** `touch-action: manipulation` im CSS hinzufügen (bereits vorhanden, aber nicht überall).
**Status:** ⏳ Offen

---

## 🗓️ Phase 1 — Polishing (Woche 1)

- [ ] **Bugfixes** (alle oben genannten)
- [ ] **Animationen:** Zelle pulsiert stärker bei Klick
- [ ] **Sound-Effekte:** Klick-Sound, Upgrade-Kauf-Sound, Prestige-Sound
- [ ] **Haptisches Feedback:** Vibration auf Mobile bei Klick (optional)
- [ ] **Start-Tutorial:** Erster Spieler bekommt Guide
- [ ] **Erreichbarkeits-Check:** Farbkontraste, Textgrößen

---

## 🗓️ Phase 2 — Content Update (Woche 2)

- [ ] **6 weitere Auto-Upgrades** (bis 18 total)
  - Z.B. Immunität, Symbiose, Fortpflanzung
- [ ] **6 weitere Klick-Upgrades** (bis 18 total)
  - Z.B. Epigenetik, Gen-Editing, CRISPR
- [ ] **Mutations-System:**
  - Zufällige Mutationen (Buffs/Debuffs)
  - Mutationen korrigierbar mit DNA
- [ ] **Forschungs-Baum:**
  - Einmalige Upgrades (nicht stapelbar)
  - Z.B. "Doppelte Klick-Power", "50% schneller"

---

## 🗓️ Phase 3 — Meta-Game (Woche 3)

- [ ] **Achievements:**
  - 30+ Achievements ("Klicke 1000x", "Kaufe 100 Mitochondrien")
  - Belohnungen: Permanente Mini-Boni
- [ ] **Daily Rewards:**
  - Login-Bonus jeden Tag
  - Streak-System (7 Tage = großer Bonus)
- [ ] **Events:**
  - "Doppelte DNA" Wochenende
  - "Mutation-Welle" Event
- [ ] **Statistiken-Seite:**
  - Gesamt-Klicks, Spielzeit, Effizienz

---

## 🗓️ Phase 4 — Social/Cloud (Woche 4+)

- [ ] **Leaderboard:**
  - Wer hat die meiste DNA?
  - Wöchentliche Reset
- [ ] **Cloud-Save:**
  - Speicherstand exportieren/importieren (Code)
  - Optional: Backend-Anbindung
- [ ] **Teilen:**
  - Screenshot-Generator von der Zelle
  - "Ich bin bei Stufe X!" teilen

---

## 🎯 LLM-Nutzung für Entwicklung

### Aktuell verfügbare LLMs auf dem System:

| Modell | Parameter | RAM-Bedarf | Status |
|--------|-----------|------------|--------|
| Gemma 4 E2B | 2.3B eff. | ~4 GB | ✅ Läuft |
| Gemma 4 E4B | 4.5B eff. | ~10 GB | ❌ Zu groß |

### Weitere Modelle zum Testen (passend für 7GB RAM):

| Modell | Parameter | RAM | Einsatz |
|--------|-----------|-----|---------|
| **Qwen2.5-Coder 1.5B** | 1.5B | ~2 GB | Code-Generierung |
| **DeepSeek-Coder V2 Lite** | 2.4B | ~3 GB | Code-Generierung |
| **CodeLlama 3B** | 3B | ~3.5 GB | Code-Generierung |
| **Phi-4 Mini** | 3.8B | ~4 GB | Allrounder |
| **TinyLlama 1.1B** | 1.1B | ~1.5 GB | Schnelle Antworten |

### Empfohlener Workflow:

1. **Gemma 4 E2B** → Game-Design, Balancing, Content-Ideen
2. **Qwen2.5-Coder 1.5B** → Code-Generierung (schneller & präziser für Code)
3. **Ich (Kimi)** → Integration, Bugfixes, Architektur

---

## 🔧 Technische To-Dos

- [ ] Performance-Optimierung (Canvas statt CSS für viele Partikel?)
- [ ] Service Worker für Offline-App (PWA)
- [ ] App-Icon & Manifest für "Add to Homescreen"
- [ ] Testen auf: iOS Safari, Android Chrome, Desktop

---

## 📊 Balancing-Ziele

| Phase | Spielzeit | DNA/s | Klick-Power |
|-------|-----------|-------|-------------|
| Early | 0-10 min | 0-10 | 1-20 |
| Mid | 10-60 min | 10-1K | 20-1K |
| Late | 1-6h | 1K-100K | 1K-100K |
| Endgame | 6h+ | 100K+ | 100K+ |
| Post-Prestige | Reset | x2-x32 | x2-x32 |

---

**Letzte Aktualisierung:** 2026-05-15
**Nächster Schritt:** Bugfixes Phase 1
