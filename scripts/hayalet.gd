extends Sprite2D
class_name Hayalet
## Bolumun en iyi kosusunun yari saydam tekrari. Ornekler sabit araliklarla
## alinmis konumlar; oynatirken aradaki kareler dogrusal ara degerle bulunur.
## Ayarlardan kapatilabilir.

const ARALIK := 0.05                  ## saniyede 20 ornek
const DOKU := preload("res://assets/sprites/oyuncu.png")

var _ornekler := PackedVector2Array()
var _t := 0.0
var _onceki := Vector2.ZERO

func _ready() -> void:
	texture = DOKU
	hframes = 10
	frame = 8                          # sallanma karesi
	modulate = Color(0.55, 0.8, 1.0, 0.42)
	z_index = 3   # oyuncunun (4) arkasinda
	visible = false

func kur(ornekler: PackedVector2Array) -> void:
	_ornekler = ornekler
	basla()

func basla() -> void:
	_t = 0.0
	visible = _ornekler.size() >= 2
	if visible:
		position = _ornekler[0]
		_onceki = position

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var i := int(_t / ARALIK)
	if i >= _ornekler.size() - 1:
		visible = false
		return
	var yeni := _ornekler[i].lerp(_ornekler[i + 1], fmod(_t, ARALIK) / ARALIK)
	if absf(yeni.x - _onceki.x) > 0.5:
		flip_h = yeni.x < _onceki.x
	_onceki = yeni
	position = yeni
