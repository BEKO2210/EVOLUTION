# 01 — Game Pillars

Pillars sind die nicht-verhandelbaren Säulen. Jedes Feature, jede Design-Entscheidung wird gegen sie validiert. Wenn ein Feature gegen einen Pillar verstößt, fliegt es raus — auch wenn es technisch reizvoll wäre.

---

## Pillar 1 — Meditative Schönheit

**Bedeutung:** Das Spiel soll sich anfühlen wie ein lebendiges Aquarium, kein Slot-Automat. Visuelle und akustische Reize werden bewusst dosiert, niemals als Aufmerksamkeits-Falle eingesetzt.

**Design-Regeln:**
- Keine ungewollten Animationen außerhalb des aktiven Fokusbereichs
- Keine Pop-ups, die den Spielfluss unterbrechen (Achievement-Toasts erlaubt, aber dezent)
- Keine schreienden Farben außerhalb der etablierten Palette
- Keine Audio-Stings ohne Spielerhandlung
- Reduzierte Bewegung (`prefers-reduced-motion`) ist eine vollwertige Spielvariante, kein Kompromiss
- Maximaler Visual-Noise: 5 % der Bildfläche (Particles, FX) — alles andere ist ruhig

**Beispiele erlaubter Features:**
- Adaptive Musik-Layer die langsam mit Progression aufbauen
- Subtile Cell-Wobble-Animation auch im Idle
- Stage-Übergangs-Animation (1× pro Stage, kurz)
- Bio-Hud-Pulse synchron zum Cell-Beat

**Beispiele verbotener Features:**
- Aufmerksamkeit-Pop-ups („Du hast lange nicht gespielt!")
- Push-Notifications die zur Rückkehr drängen
- Blinkende „Klick mich!"-Marker auf günstigen Upgrades (User pickt selbst, was er kauft)
- Battle-Pass-Style FOMO-Mechanik
- Konfetti-Explosionen auf jeder Aktion
- Werbe-Banner für andere Apps des Studios

---

## Pillar 2 — Mathematische Tiefe ohne Komplexitäts-Wand

**Bedeutung:** Das Spiel hat eine tiefe, theory-craftbare Wirtschaft, aber der Einstieg ist trivial. Tiefe entsteht durch das Zusammenspiel weniger, klarer Systeme — nicht durch Feature-Stapelung.

**Design-Regeln:**
- Höchstens 5 gleichzeitig aktive Multiplier-Quellen pro Wert
- Jede Multiplier-Quelle ist im UI nachvollziehbar (Tooltip zeigt die Kette)
- Formeln sind in `data/balance_constants.json` extern, vom Designer ohne Code änderbar
- Prestige-Skill-Tree hat klare Knoten mit klaren Effekten — keine versteckten Synergien
- Sub-Sekunden-Operationen werden im Code zusammengefasst, aber dem Spieler einzeln angezeigt

**Beispiele erlaubter Features:**
- Skill-Tree mit 6–10 Knoten und klaren Trade-offs
- Stat-Panel mit Sparkline-Charts (Lifetime-DNA, Klicks/Tag)
- Codex der Formeln freischaltbar nach erster Prestige
- Theorycrafting-Discord erlaubt; offizielles Wiki nicht erforderlich aber willkommen

**Beispiele verbotener Features:**
- Versteckte Modifier ohne UI-Repräsentation
- Random-Drops mit unsichtbarer Drop-Rate
- „Lucky"-Mechaniken die auf Zufall ohne Player-Agency basieren
- Pay-Walls für Stat-Visualisierung („Premium-Stats-Pack")
- Loot-Box-Mechaniken jeglicher Art

---

## Pillar 3 — Endlose Progression mit Respekt vor Spielerzeit

**Bedeutung:** Das Spiel kann theoretisch unendlich gespielt werden, aber jede Spielzeit-Investition zahlt sich aus. Es gibt keine „verschwendeten" Stunden, keine Reset-Strafen, kein Grinding ohne Belohnung.

**Design-Regeln:**
- Offline-Progress ist Standard, nicht Premium-Feature
- Offline-Effizienz ≥50 %, ohne Forschung 100 %
- Kein Save kann durch Player-Aktion verloren gehen (alle Resets sind explizit + reversibel im Wert)
- Achievement-Completion ist in <300 h erreichbar (kein Honor-Mode-Marathon)
- Daily-Login-Bonus existiert, aber der Verlust einer Daily ist nie spielentscheidend
- Idle-Sessions im Hintergrund verbrauchen <5 % Batterie/Stunde auf Steam Deck

**Beispiele erlaubter Features:**
- Auto-Buyer (in Phase 3 freischaltbar via Forschung)
- Multiple Save-Slots
- Save-Export/Import für Disaster-Recovery
- Optional: 2x Speed nach Prestige (Player-Komfort)
- Pause-Funktion die Idle-Tick einfriert

**Beispiele verbotener Features:**
- Permadeath
- Save-Wipe als „Strafe" für Inaktivität
- Zeit-begrenzte Events mit exklusiven Achievements (FOMO)
- „Energie"-Systeme die Spielen limitieren
- Pay-to-Skip-Cooldowns
- Verlust permanenten Fortschritts durch Bugs (alle Migrations sind getestet)

---

## Pillar 4 — Plattform-übergreifend, ohne Pay-to-Win, ohne Werbung

**Bedeutung:** Ein einmaliger Kauf, ein Spiel. Auf Steam Desktop, auf Steam Deck, später auf dem Handy — überall dasselbe vollständige Spiel.

**Design-Regeln:**
- Premium-Modell: ein Preis, ein Spiel, alle Features
- Keine In-Game-Käufe (DLC für Major-Content-Updates erlaubt, post v1.0)
- Keine Werbung (intern oder extern)
- Mobile-Companion-App (Phase 7) hat denselben Preis, kein zusätzlicher Verkauf
- Cloud-Save synct über alle Plattformen
- UI ist responsive: Desktop, Steam Deck (1280×800), Tablet (16:9 + 16:10), Phone (Portrait + Landscape)
- Touch-Targets ≥44×44 dp auf Mobile

**Beispiele erlaubter Features:**
- Major Content Update als kostenpflichtiges DLC (3–6 Monate post-launch, neue Stages, neue Prestige-Layer)
- Cosmetic-DLC (Cell-Themes, UI-Themes) — aber NICHT Pay-to-Progress
- Kostenloser Demo via Steam Next Fest und permanent
- Plattform-übergreifender Cloud-Save

**Beispiele verbotener Features:**
- Microtransactions
- Loot Boxes
- Premium-Währung
- „Energie kaufen"
- „2x Speed Booster für 0.99 €"
- Werbeintegrationen
- Daten-Verkauf an Dritte
- Account-Bindung außerhalb Steam (kein separater Login)

---

## Pillar-Validierungs-Checkliste (Feature-Gate)

Vor jeder Feature-Implementation:

- [ ] Pillar 1: Stört das Feature die Ruhe des Spiels?
- [ ] Pillar 2: Erhöht es die Mechanik-Komplexität ohne sichtbaren Tiefe-Gewinn?
- [ ] Pillar 3: Verschwendet es Spielerzeit oder bestraft Pausen?
- [ ] Pillar 4: Bricht es das Premium-Modell oder das Plattform-Versprechen?

Wenn auch nur ein Pillar verletzt wird: **Feature gestrichen oder umdesignt.** Keine Ausnahmen.
