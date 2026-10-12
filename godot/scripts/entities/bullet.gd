extends Sprite2D
class_name BulletView
## Projétil pooled (Sprite2D, não AnimatedSprite2D — 3.3). A posição lógica
## mora na sim; a view apenas interpola (3.7).

var sim_id := -1
var active := false

const TEXTURES := {
	"straight": "res://assets/art/Bullets/Artboard 1.png",
	"slow": "res://assets/art/Bullets/Artboard 1 copy.png",
	"grenade": "res://assets/art/Bullets/Artboard 1 copy 2.png",
}

func pool_activate() -> void:
	active = true
	visible = true

func pool_deactivate() -> void:
	active = false
	visible = false
	sim_id = -1

func setup(p_id: int, kind: String) -> void:
	sim_id = p_id
	texture = load(TEXTURES.get(kind, TEXTURES["straight"]))
	scale = Vector2(0.5, 0.5)
