extends RefCounted
class_name KaroSeti
## TileSet'i kodla kurar (ayri .tres yok). TileSet YALNIZ CARPISMA icin: gorunum
## Bolum'un ZeminCizim dugumunde duz dolgu olarak cizilir (karo dokusu yok), bu
## yuzden atlas kaynagi 16x16'lik tek bir duz beyaz karodur. Her karo tam kare
## carpisma tasir.

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
	var im := Image.create(BOY, BOY, false, Image.FORMAT_RGBA8)
	im.fill(Color.WHITE)
	kaynak.texture = ImageTexture.create_from_image(im)
	kaynak.texture_region_size = Vector2i(BOY, BOY)
	# Kaynak once TileSet'e baglanmali: karo verisi fizik katmanlarini
	# ancak bagli oldugu TileSet'ten gorebiliyor.
	ts.add_source(kaynak, 0)
	var yari := BOY / 2.0
	var kare := PackedVector2Array([
		Vector2(-yari, -yari), Vector2(yari, -yari), Vector2(yari, yari), Vector2(-yari, yari)])
	var koord := Vector2i(0, 0)
	kaynak.create_tile(koord)
	var kd := kaynak.get_tile_data(koord, 0)
	kd.add_collision_polygon(0)
	kd.set_collision_polygon_points(0, 0, kare)
	_onbellek = ts
	return _onbellek
