extends Node2D
class_name KancaNoktasi
## Kancanin takilabilecegi tavan noktasi. Gorseli kodla cizilir (yer tutucu).

const GRUP := &"kanca_noktasi"

var _vurgulu := false
var _bagli := false

func _ready() -> void:
	add_to_group(GRUP)
	z_index = 5

## Nisangahta bu nokta secili mi (menzil icinde ve nisana en hizali).
func vurgu(acik: bool) -> void:
	if acik != _vurgulu:
		_vurgulu = acik
		queue_redraw()

## Kanca su an bu noktaya bagli mi.
func bagla(acik: bool) -> void:
	if acik != _bagli:
		_bagli = acik
		queue_redraw()

func _draw() -> void:
	var renk := Ayarlar.RENK_NOKTA
	if _bagli:
		renk = Ayarlar.RENK_NOKTA_BAGLI
	elif _vurgulu:
		renk = Ayarlar.RENK_NOKTA_VURGU
	draw_circle(Vector2.ZERO, 4.0, renk)
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 18, renk, 2.0)
	if _vurgulu or _bagli:
		draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 20, Color(renk, 0.5), 1.0)
