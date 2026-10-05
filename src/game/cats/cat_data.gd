class_name CatData
extends Resource
## Definição imutável de um gato (data-driven: números vivem em .tres).

const TIER_MULTIPLIERS: Array[float] = [1.0, 2.2, 5.0]
const MAX_TIER := 3

@export var id: StringName = &"cat_01"
@export var display_name := "Gato"
@export var atlas_name := "cat_01"
## DPS base no tier 1. Tier 2 = 2.2x, tier 3 = 5x (aplicado por CatTower).
@export var damage := 10.0
@export var fire_rate := 1.0  # tiros por segundo
@export var projectile_speed := 620.0
@export var range := 900.0
@export var bullet_texture: Texture2D
@export var muzzle_color := Color(1.0, 0.85, 0.4)

static func damage_for_tier(base: float, tier: int) -> float:
	var idx := clampi(tier - 1, 0, TIER_MULTIPLIERS.size() - 1)
	return base * TIER_MULTIPLIERS[idx]
