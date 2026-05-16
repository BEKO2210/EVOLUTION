extends Node
##
## SaveSystem — JSON IO, schema versioning, migrations, Steam Cloud sync.
##
## Phase 1 / P1-002. Stub interface only — real implementation in P1-004.
## Schema + migration strategy spec'd in docs/decisions/ADR-0003-save-system.md.
##
## Save file layout: user://save_slot_<n>.json
## Slot 0 is the Steam-Cloud-synced "main" slot. Slots 1-3 are local-only.
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal migration_applied(from_version: int, to_version: int)
signal save_corruption_detected(slot: int, reason: String)

# ----------------------------------------------------------------------------
# CONSTANTS
# ----------------------------------------------------------------------------
const CURRENT_SCHEMA_VERSION: int = 1
const SLOT_CLOUD: int = 0
const SLOT_LOCAL_1: int = 1
const SLOT_LOCAL_2: int = 2
const SLOT_LOCAL_3: int = 3
const MAX_SLOT: int = 3

## Map of schema migrations: from_version -> Callable(dict) -> dict.
## P1-004 fills this as save schema evolves.
const MIGRATIONS: Dictionary = {}

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Real periodic-save Timer setup happens in P1-004.
	pass

# ----------------------------------------------------------------------------
# PUBLIC API — stubs
# ----------------------------------------------------------------------------

## Persist current GameState to disk slot. Returns success.
## Stub: real JSON serialization + checksum + Cloud-sync land in P1-004.
func save(slot: int = SLOT_CLOUD) -> bool:
	push_warning("[SaveSystem] save(slot=%d) is a stub; real impl in P1-004." % slot)
	save_completed.emit(slot, false)
	return false

## Load slot into GameState. Returns success.
## Stub: real JSON parse + checksum + migration land in P1-004.
func load_slot(slot: int = SLOT_CLOUD) -> bool:
	push_warning("[SaveSystem] load_slot(slot=%d) is a stub; real impl in P1-004." % slot)
	load_completed.emit(slot, false)
	return false

## Run migrations from the save's schema_version up to CURRENT_SCHEMA_VERSION.
## Stub: no migrations exist in v1.
func migrate(save_dict: Dictionary) -> Dictionary:
	var version: int = int(save_dict.get("schema_version", 0))
	while version < CURRENT_SCHEMA_VERSION:
		if not MIGRATIONS.has(version):
			push_error("[SaveSystem] missing migration from v%d -> v%d" % [version, version + 1])
			return save_dict
		var migrator: Callable = MIGRATIONS[version]
		save_dict = migrator.call(save_dict)
		migration_applied.emit(version, version + 1)
		version += 1
	return save_dict

## Return list of available save slots with metadata (for slot picker UI).
## Stub.
func list_slots() -> Array:
	return []

## Export a save slot to an external file path (disaster recovery).
## Stub.
func export_to_file(_slot: int, _path: String) -> bool:
	push_warning("[SaveSystem] export_to_file is a stub; real impl in P1-004.")
	return false

## Import a save from an external file path.
## Stub.
func import_from_file(_path: String, _target_slot: int) -> bool:
	push_warning("[SaveSystem] import_from_file is a stub; real impl in P1-004.")
	return false
