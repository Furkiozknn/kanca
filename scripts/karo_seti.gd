extends RefCounted
class_name KaroSeti
## assets/sprites/karo.png uzerinden TileSet'i kodla kurar (ayri .tres yok).
## Atlas 4 sutun x 3 satir:
##   sutun 0 = sol kenar, 1 = ic, 2 = sag kenar, 3 = iki kenar da acik
##   satir  0 = ust (yosunlu), 1 = ic, 2 = alt
## Her karo tam kare carpisma tasir.

const DOKU := preload("res://assets/sprites/karo.png")
const BOY := 16

static var _onbellek: TileSet = null

static func al() -> TileSet:
	if _onbellek != null:
		return _onbellek
	var ts := TileSet.new()
	ts.tile_size = Vector2i(BOY, BOY)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)

	var kaynak := TileSetAtlasSource.new()
	kaynak.texture = DOKU
	kaynak.texture_region_size = Vector2i(BOY, BOY)
	# Kaynak once TileSet'e baglanmali: karo verisi fizik katmanlarini
	# ancak bagli oldugu TileSet'ten gorebiliyor.
	ts.add_source(kaynak, 0)
	var yari := BOY / 2.0
	var kare := PackedVector2Array([
		Vector2(-yari, -yari), Vector2(yari, -yari), Vector2(yari, yari), Vector2(-yari, yari)])
	for sy in 3:
		for sx in 4:
			var koord := Vector2i(sx, sy)
			kaynak.create_tile(koord)
			var kd := kaynak.get_tile_data(koord, 0)
			kd.add_collision_polygon(0)
			kd.set_collision_polygon_points(0, 0, kare)
	_onbellek = ts
	return _onbellek

## Dikdortgen icindeki (tx, ty) karosu icin atlas koordinati.
static func koord(tx: int, ty: int, tx0: int, ty0: int, tx1: int, ty1: int) -> Vector2i:
	var sx := 1
	if tx0 == tx1:
		sx = 3
	elif tx == tx0:
		sx = 0
	elif tx == tx1:
		sx = 2
	var sy := 1
	if ty == ty0:
		sy = 0
	elif ty == ty1:
		sy = 2
	return Vector2i(sx, sy)
