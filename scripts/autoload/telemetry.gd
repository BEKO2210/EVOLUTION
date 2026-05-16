extends Node
##
## Telemetry — opt-in event pipeline.
##
## Phase 1 / P1-002. Stub only — real Sentry-for-crashes + custom-endpoint-
## for-game-events integration in P1-009 (achievement system) + Phase 3 docs.
##
## DSGVO compliance:
##   - Opt-in default OFF. First-run dialog asks explicitly.
##   - No personally identifiable information (PII) — no user IDs, no IPs.
##   - Only anonymous gameplay events (stage reached, prestige performed,
##     session length, crash reports).
##   - All transmission gated on `opt_in == true`.
##

# ----------------------------------------------------------------------------
# STATE
# ----------------------------------------------------------------------------
var opt_in: bool = false                     ## must be explicitly enabled via consent UI
var session_id: String = ""                  ## random per-launch, no cross-session linkage
var session_start_unix: int = 0

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	session_id = _random_session_id()
	session_start_unix = int(Time.get_unix_time_from_system())

# ----------------------------------------------------------------------------
# PUBLIC API — stubs
# ----------------------------------------------------------------------------

## Record a gameplay event. Silently dropped if opt-in is false.
## Stub: real impl batches + POSTs to telemetry endpoint in Phase 3.
func track(_event_name: String, _props: Dictionary = {}) -> void:
	if not opt_in:
		return
	# TODO P1-009/Phase-3: batch events, periodic flush to endpoint, retry on failure.
	# Defensive: never throw, never block game loop.

## Sentry-style crash report. Always-on but gated on opt_in for compliance.
func report_crash(_error: String, _stack: String) -> void:
	if not opt_in:
		return
	# TODO P1-009: Sentry SDK integration, DSN as build-time env var.
	pass

## Update consent state. Persisted via GameState.sound-style settings save.
func set_opt_in(consent: bool) -> void:
	opt_in = consent
	# Persisting handled by SaveSystem in settings block (P1-004).

# ----------------------------------------------------------------------------
# INTERNAL
# ----------------------------------------------------------------------------
func _random_session_id() -> String:
	# Cheap UUID-ish identifier; not cryptographically secure (not needed —
	# this is anonymous gameplay telemetry, not auth).
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var chars: String = "0123456789abcdef"
	var out: String = ""
	for i in 16:
		out += chars[rng.randi() % chars.length()]
	return out
