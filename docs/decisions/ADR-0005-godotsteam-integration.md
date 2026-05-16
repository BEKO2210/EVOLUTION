# ADR-0005 — GodotSteam-Integration

**Status:** Akzeptiert (Spike-Ergebnis, Phase 1 / P1-012)
**Datum:** Phase 1
**Bezug:** ADR-0001 (Godot-Engine-Wahl), TDD Sektion 13

## Kontext

Die Steam-Integration des Spiels (Achievements, Cloud-Save, Steam Input, später optional Workshop/Trading Cards) wird über das Community-Plugin **GodotSteam** gemacht — es gibt keine First-Party-Steam-API in Godot.

Historisch war GodotSteam ein **Engine-Modul**, das heißt: du musstest dir Godot selbst neu kompilieren (`SCons platform=linuxbsd module_godotsteam_enabled=yes`). Das kostete ~1 Tag Setup pro Plattform und blockiert CI auf normalen Cloud-Buildern, weil dort Compilation der C++-Engine zu langsam und ressourcen-intensiv ist.

Seit GodotSteam Version 4.x (parallel zur Godot-4-Linie) existiert **`GodotSteam GDExtension`** — dasselbe Plugin als dynamisch geladene Library (`.dll`/`.so`/`.dylib`), die zur Laufzeit in ein **Standard-Godot-Binary** geladen wird. Kein eigener Engine-Build mehr nötig.

P1-012 (Phase 1 Spike) hat zwei Fragen zu klären:

1. Reicht die **GDExtension** für unseren Feature-Bedarf (Achievements + Cloud-Save + Steam Input + Rich Presence) ohne dass wir auf das alte Modul-Setup zurückfallen müssen?
2. Welche **konkrete Version** von GodotSteam ist mit unserer gepinnten Godot-Version (`.godot-version` = `4.3-stable`) kompatibel?

## Optionen

### Option A — GodotSteam-GDExtension (bevorzugt)

**Pro:**
- Standard-Godot-Binary ausreichend (kein C++-Compile-Schritt)
- CI-friendly: Build geht in <2 Minuten auf GitHub Actions
- Hot-Reload im Editor möglich (Library wird beim Re-Open frisch geladen)
- Update-Pfad: nur Library-Datei austauschen, kein Engine-Rebuild
- Identische API zum Modul-Build — bestehende Tutorials/Docs gelten

**Contra:**
- Erfordert plattform-spezifische `.dll`/`.so`/`.dylib`-Files im Repo (`addons/godotsteam/`)
- Plus die `steam_api64.dll` / `libsteam_api.so` von Steamworks SDK
- Beide sind Binär-Files → ggf. via Git LFS (siehe `.gitattributes`)
- GDExtension-Variante hinkt manchmal 1–2 Wochen hinter dem Modul-Build her bei Godot-Patch-Releases

### Option B — GodotSteam als Engine-Modul (Fallback)

**Pro:**
- Maximale Performance (statisch gelinkt, kein dynamic-link-Overhead — irrelevant für unsere Call-Frequenz)
- Erste Wahl wenn GDExtension auf der gepinnten Godot-Version nicht stabil ist

**Contra:**
- Jeder Dev braucht lokale C++-Build-Umgebung (Visual Studio, Xcode, SCons, Python)
- CI braucht entweder einen eigenen Godot-Build-Step (~15 min) oder einen vorbgebauten Custom-Binary in einem Artifact-Store
- Onboarding neuer Devs: 1 Tag setup statt 1 Stunde
- Update auf neue Godot-Version = Full-Rebuild + Test über alle Plattformen

## Entscheidung

**Option A — GodotSteam-GDExtension.**

Konkrete Version: **GodotSteam 4.13 GDExtension oder höher** (kompatibel mit Godot 4.3-stable). Vor Phase 2 final-Pinnung gegen den dann aktuellen GodotSteam-Release.

Wir installieren NICHT vorzeitig — das Plugin landet erst im Repo wenn ein Dev tatsächlich auf eine echte Steam-AppID build-testet (vermutlich Anfang Phase 2 / Vertical Slice). In Phase 1 reicht das Setup-Doc + die `steam_api.gd`-Hooks die sauber no-op-en wenn die Extension nicht geladen ist.

## Begründung

1. **Phase-1-Reichweite:** Wir brauchen den Steam-Hook erst wenn die Marketing-Phase (Phase 5) anfängt. Bis dahin haben wir 6+ Monate, in denen die GDExtension-Version weiter reift.
2. **CI-Friendlich:** Unsere `tools/run_tests.sh` Pipeline läuft in <2 min auf headless Godot. Ein Modul-Build würde das auf ~15 min hochziehen und unsere PR-Velocity zerstören.
3. **Solo-Dev-Realismus:** ADR-0001 hat Godot gewählt teilweise wegen der schnellen Iteration. Ein eigener Engine-Build für jeden Dev (oder CI-Build-Cache mit Storage-Aufwand) widerspricht der Wahl.
4. **Risiko-Pfad klar:** Sollte die GDExtension auf einer Plattform brechen (z.B. macOS-arm64 hat historisch nachhinken können), fallen wir punktuell für diese Plattform auf Modul-Build zurück, statt alles umzustellen. ADR-0001 nennt das schon als Review-Trigger.

## Akzeptierte Trade-offs

- **Binär-Plugin-Files im Repo.** Die GodotSteam-GDExtension-Releases enthalten kleine .dll/.so/.dylib-Files (~1–3 MB pro Plattform). Wir committen sie im Phase-2-Setup-PR direkt, statt Git LFS aufzusetzen — die Größe rechtfertigt LFS-Overhead nicht. (LFS-Patterns sind in `.gitattributes` bereits vorbereitet, falls Asset-Größen später explodieren.)
- **Steam SDK Lizenz.** Steamworks SDK ist nicht open-source. Die `steam_api64.dll`/`libsteam_api.so`-Files dürfen mit dem Spiel verteilt werden (Steam-EULA erlaubt das explizit für veröffentlichte Spiele), aber wir nehmen sie auch ins Repo. Hinweis in `ATTRIBUTIONS.md`.
- **Plattform-Build-Matrix wächst.** Statt 3 Builds (Win/Linux/macOS) brauchen wir 3 Builds × 2 (mit/ohne GodotSteam). Plus ein "no-Steam"-Build für freie Distribution (z.B. itch.io ohne Steam-Account-Anforderung). Total: 6 Build-Targets. Tools/CI-Scripts müssen das in Phase 5 abbilden.

## Konsequenzen

- `scripts/autoload/steam_api.gd` wird in P1-012 mit GodotSteam-Aufrufen ausgestattet, **aber durch eine Feature-Detection geschützt**: wenn die GDExtension nicht geladen ist (`Engine.has_singleton("Steam") == false`), bleibt alles no-op. Bricht keine Tests, bricht den normalen Godot-Build nicht.
- `scenes/dev/steam_smoke_test.tscn` ist eine dev-only Test-Scene mit Buttons für Init / Username / Test-Achievement / Cloud-Save-Write. Wird ausgeführt **nach manueller Installation des Plugins** (Anleitung in `docs/steam/godotsteam-setup.md`).
- Real-Verifikation auf Spacewar (AppID 480) ist Phase-5-Aufgabe — wir können die ohne Steam-Account oder Test-AppID-Approval nicht in CI automatisieren.
- `docs/steam/godotsteam-setup.md` enthält Schritt-für-Schritt-Setup für Phase 2 / Phase 5 wenn die Integration scharf geschaltet wird.

## Review-Trigger (wann diese Entscheidung neu evaluieren)

- GodotSteam GDExtension wird für Godot 4.x officially deprecated → Eskalation zu Modul-Build
- macOS-arm64-Support bricht → punktueller Modul-Build für macOS, Rest bleibt GDExtension
- Steam ändert Steamworks SDK Distribution-Policy → ADR-Update + ggf. Repo-Anpassung
- Steam Deck Verified Anforderungen erfordern speziellere Integration (z.B. SteamInput v2) → Re-Spike

## Verwandte Dokumente

- ADR-0001 — Engine-Wahl (begründet warum Godot überhaupt; ADR-0005 baut darauf auf)
- `docs/steam/godotsteam-setup.md` — Setup-Anleitung
- `docs/steam/steam-deck-checklist.md` — Deck-Verified-Kriterien (Cloud-Save + Steam-Input sind dort referenziert)
- `production/phase-1-backlog.md` — P1-012 Spike-Ticket
