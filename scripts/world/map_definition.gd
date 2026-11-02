class_name MapDefinition
extends Resource
## Static layout data for a skirmish map. Positions are on the XZ ground plane.

@export var map_id: StringName = &""
@export var display_name: String = ""
## Playable area size in world units, centered on the origin.
@export var size: Vector2 = Vector2(120.0, 120.0)
@export var player_start: Vector3 = Vector3.ZERO
@export var enemy_start: Vector3 = Vector3.ZERO
@export var scrap_sites: Array[Vector3] = []
## Scrap available at each scrap site before it is depleted.
@export var scrap_per_site: int = 600
@export var energy_sites: Array[Vector3] = []
@export var core_site: Vector3 = Vector3.ZERO
## Collective guards hold these points from the start of the match.
@export var sentry_posts: Array[Vector3] = []
## Rock formations: x, z, radius, height.
@export var rocks: Array[Vector4] = []
## Ruined structures: x, z, footprint size, height.
@export var ruins: Array[Vector4] = []
## Seed for deterministic decorative variation.
@export var decor_seed: int = 1


func half_extents() -> Vector2:
	return size * 0.5
