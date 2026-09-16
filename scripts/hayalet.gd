extends Sprite2D
class_name Hayalet
## Bolumun en iyi kosusunun yari saydam tekrari. Ornekler sabit araliklarla
## alinmis konumlar; oynatirken aradaki kareler dogrusal ara degerle bulunur.
## Ayarlardan kapatilabilir.
##
## Iki kaynak var (Kayit.ayar("hayalet_kip")):
##   1 = oyuncunun kendi en iyi kosusu (user://hayalet_NN.dat)
##   2 = ALTIN HAYALET - botun kosusu (scripts/rota_verisi.gd "iz" alani),
##       yalniz o bolumde altin madalya kazanildiysa.
##
## Ornekleme 10 Hz (v0.3'te 20 Hz idi): kayit yariya indi, ara deger zaten
## 60 Hz'e cikariyor. Aralik kayda YAZILIYOR (Kayit.hayalet_yaz), yoksa bu
## sabiti degistirmek eski kayitlari yari hizda oynatirdi.

const ARALIK := 0.10                  ## saniyede 10 ornek
const DOKU := preload("res://assets/sprites/oyuncu.png")

var _ornekler := PackedVector2Array()
var _aralik := ARALIK
var _t := 0.0
var _onceki := Vector2.ZERO

func _ready() -> void:
	texture = DOKU
	hframes = 10
	frame = 8                          # sallanma karesi
	modulate = Color(0.55, 0.8, 1.0, 0.42)
	z_index = 3   # oyuncunun (4) arkasinda
	visible = false

## altin=true: botun rotasi. Renk ayrisir ki hangisini izledigin belli olsun.
func kur(ornekler: PackedVector2Array, aralik := ARALIK, altin := false) -> void:
	_ornekler = ornekler
	_aralik = aralik if aralik > 0.001 else ARALIK
	if altin:
		modulate = Color(Palet.ALTIN, 0.62)
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
	var i := int(_t / _aralik)
	if i >= _ornekler.size() - 1:
		visible = false
		return
	var yeni := _ornekler[i].lerp(_ornekler[i + 1], fmod(_t, _aralik) / _aralik)
	if absf(yeni.x - _onceki.x) > 0.5:
		flip_h = yeni.x < _onceki.x
	_onceki = yeni
	position = yeni
