extends GutTest
## Merge: mesmo tipo+tier → tier+1; tipos diferentes → sem merge; tier máx 3.

var grid: SlotGrid
var cat_a: CatTower
var cat_b: CatTower
var cat_data: CatData

func before_each() -> void:
	Engine.get_main_loop().root.add_child(_make_tree())

func _make_tree() -> Node:
	var root_node := Node.new()
	grid = SlotGrid.new()
	root_node.add_child(grid)
	cat_data = CatData.new()
	cat_data.id = &"cat_01"
	cat_data.atlas_name = "cat_01"
	cat_data.damage = 10.0
	cat_data.fire_rate = 1.0
	cat_data.projectile_speed = 600.0
	cat_data.range = 900.0
	return root_node

func _place_cat(tier: int, slot: int) -> CatTower:
	var cat := CatTower.new()
	cat.setup(cat_data, tier)
	assert_true(grid.place(cat, slot))
	return cat

func test_merge_mesmo_tier_sobe_nivel() -> void:
	cat_a = _place_cat(1, 0)
	cat_b = _place_cat(1, 1)
	var result := grid.try_merge(0, 1)
	assert_eq(result, 1)
	assert_eq(grid.get_at(1).tier, 2)
	assert_null(grid.get_at(0))

func test_merge_tipos_diferentes_falha() -> void:
	cat_a = _place_cat(1, 0)
	var other := CatData.new()
	other.id = &"cat_02"
	other.atlas_name = "cat_02"
	cat_b = CatTower.new()
	cat_b.setup(other, 1)
	grid.place(cat_b, 1)
	assert_eq(grid.try_merge(0, 1), -1)

func test_terceiro_tier_e_o_maximo() -> void:
	cat_a = _place_cat(3, 0)
	cat_b = _place_cat(3, 1)
	assert_eq(grid.try_merge(0, 1), -1)

func test_dps_escala_1_22_5() -> void:
	assert_almost_eq(CatData.damage_for_tier(10.0, 1), 10.0, 0.01)
	assert_almost_eq(CatData.damage_for_tier(10.0, 2), 22.0, 0.01)
	assert_almost_eq(CatData.damage_for_tier(10.0, 3), 50.0, 0.01)
