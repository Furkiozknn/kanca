class_name Cizim
extends RefCounted
## Dunyanin kodla cizilen parcalari: oyuncu govdesi, parcacik dokusu, madalya.
## PNG yok: her sey duz dolgu, her olcekte keskin (canvas_items germesi).

const GOVDE_G := 12.0
const GOVDE_Y := 20.0

static var _nokta: ImageTexture = null
static var _cizgi: ImageTexture = null


## 6x6 yumusak kenarli disk: parcacik dokusu (beyaz; renk parcacikta).
static func nokta_dokusu() -> ImageTexture:
	if _nokta == null:
		_nokta = _disk(6)
	return _nokta


## 14x2 ince cizgi: ruzgar akintisi parcacigi.
static func cizgi_dokusu() -> ImageTexture:
	if _cizgi == null:
		var im := Image.create(14, 2, false, Image.FORMAT_RGBA8)
		im.fill(Color.WHITE)
		_cizgi = ImageTexture.create_from_image(im)
	return _cizgi


static func _disk(boy: int) -> ImageTexture:
	var im := Image.create(boy, boy, false, Image.FORMAT_RGBA8)
	var r := boy / 2.0
	for y in boy:
		for x in boy:
			var kapsama := 0.0
			for sy in 4:
				for sx in 4:
					if Vector2(x + (sx + 0.5) / 4.0 - r, y + (sy + 0.5) / 4.0 - r).length() <= r:
						kapsama += 1.0
			im.set_pixel(x, y, Color(1, 1, 1, kapsama / 16.0))
	return ImageTexture.create_from_image(im)


## Oyuncu govdesi: 12x20 hap (carpisma kutusuyla ayni), tek goz. `esnek`
## ezilme/germe, `bakis` -1/1, `nisan` goz yonu, `ofset` govde sarkmasi.
static func oyuncu_ciz(ci: CanvasItem, kutu: StyleBoxFlat, renk: Color, goz: Color,
		bakis: float, esnek: Vector2, nisan: Vector2, ofset: Vector2) -> void:
	ci.draw_set_transform(ofset, 0.0, esnek)
	kutu.bg_color = renk
	ci.draw_style_box(kutu, Rect2(-GOVDE_G * 0.5, -GOVDE_Y * 0.5, GOVDE_G, GOVDE_Y))
	var g := Vector2(bakis * 2.4, -4.0) + nisan.limit_length(1.0) * Vector2(1.2, 0.8)
	ci.draw_circle(g, 1.6, goz, true, -1.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func govde_kutusu() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(6)
	s.anti_aliasing = true
	return s


## Madalya simgesi (12x12): duz disk + ust serit. 0 altin, 1 gumus, 2 bronz.
class Madalya extends Control:
	var no := 0

	func _init(n: int = 0) -> void:
		no = n
		custom_minimum_size = Vector2(12, 12)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = n < 3

	func _draw() -> void:
		var renk := Tema.SARI
		if no == 1:
			renk = Tema.GUMUS
		elif no == 2:
			renk = Tema.BRONZ
		draw_circle(Vector2(6, 6), 5.5, renk, true, -1.0, true)
