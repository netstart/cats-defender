extends Node2D
class_name EnemyView
## View de inimigo: espelha o estado da sim (3.4), animações Walk/Attack/Dead,
## HP bar flutuante (B1), knockback flash. Sai do targeting no frame 0 (3.6).

const ART := "res://assets/art/Enemies/"

var sim_id := -1
var enemy_type := ""
var is_boss := false
var sprite: AnimatedSprite2D = null
var hp_bar: TextureProgressBar = null
var _flash := 0.0

func _ready() -> void:
	z_index = 6
	y_sort_enabled = true

func setup(p_id: int, p_type: String, p_boss := false) -> void:
	sim_id = p_id
	enemy_type = p_type
	is_boss = p_boss
	sprite = AnimatedSprite2D.new()
	sprite.centered = true
	var dir := ART + p_type
	sprite.sprite_frames = FrameLoader.load_character(dir, {
		"walk": ["Walk", 22.0, true],
		"attack": ["Attack", 22.0, true],
		"dead": ["Dead", 30.0, false],
		"idle": ["Idle", 18.0, true],
	})
	add_child(sprite)
	sprite.play("walk")
	if is_boss:
		sprite.scale = Vector2(1.15, 1.15)
	# HP bar (TextureProgressBar, 4.x: sem sprite no pack -> barra desenhada)
	hp_bar = TextureProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.size = Vector2(60, 7)
	hp_bar.position = Vector2(-30, -95 * (1.15 if is_boss else 1.0))
	hp_bar.visible = is_boss   # sempre visível no boss (B1); normais sob demanda
	add_child(hp_bar)

func sync_from_sim(e: Dictionary, delta: float) -> void:
	var prog: float = e["progress"]
	position.x = prog_to_x(prog)
	var state: String = e["state"]
	var dead: bool = not e["alive"]
	if dead:
		if sprite.animation != "dead":
			sprite.play("dead")
	elif state == "siege" or state == "queue":
		if sprite.animation != "attack":
			sprite.play("attack")
	else:
		if sprite.animation != "walk":
			sprite.play("walk")
		# foot-sliding (3.6): speed_scale proporcional à velocidade atual
		var base_spd := 35.0
		var slowf: float = e.get("slow_factor", 1.0) if e.get("slow_until", -1.0) > 0 else 1.0
		sprite.speed_scale = clampf((float(e["speed"]) * slowf) / base_spd, 0.3, 2.5)
	if hp_bar:
		hp_bar.value = 100.0 * float(e["hp"]) / maxf(1.0, float(e["max_hp"]))
	if e.get("enraged", false):
		sprite.modulate = Color(1.2, 0.7, 0.7)
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0 and not e.get("enraged", false):
			sprite.modulate = Color.WHITE

static func prog_to_x(_p: float) -> float:
	return 0.0  # substituído pela cena do jogo via layout (ver game.gd)

func flash_hit() -> void:
	if sprite and not GameSettings.reduce_fx:
		sprite.modulate = Color(2.0, 2.0, 2.0)
	_flash = 0.08

func is_dead_finished() -> bool:
	return sprite != null and sprite.animation == "dead" and not sprite.is_playing()
