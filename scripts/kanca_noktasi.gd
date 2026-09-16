extends Node2D
class_name KancaNoktasi
## Kancanin takilabilecegi nokta. Uc tur var:
##   TUR_SABIT     - yerinde durur
##   TUR_HAREKETLI - iki uc arasinda gidip gelir (halat capasi da hareket eder)
##   TUR_KIRILGAN  - bir kez tutulur; birakilinca kisa bir uyari sonrasi kirilir
##
## Gorsel assets/sprites/kanca_noktasi.png (3 kare, 16x16). Vurgu ve bagli
## durumlari modulate ile gosterilir.

const GRUP := &"kanca_noktasi"
const DOKU := preload("res://assets/sprites/kanca_noktasi.png")
const KARE := 16

enum { TUR_SABIT, TUR_HAREKETLI, TUR_KIRILGAN }

var tur := TUR_SABIT
var a := Vector2.ZERO          ## hareketli: bir uc
var b := Vector2.ZERO          ## hareketli: obur uc
var hiz := Ayarlar.HAREKETLI_HIZ
var faz := 0.0                 ## hareketli: baslangic fazi (0..1)

var _vurgulu := false
var _bagli := false
var _kirildi := false
var _kirilma_sayaci := 0.0
var _t := 0.0
var _gorsel: Sprite2D

## Bolum kurulumundan once cagrilir.
static func yap(yer: Vector2, t: int = TUR_SABIT) -> KancaNoktasi:
	var n := KancaNoktasi.new()
	n.position = yer
	n.tur = t
	n.a = yer
	n.b = yer
	return n

func _ready() -> void:
	add_to_group(GRUP)
	z_index = 5
	_gorsel = Sprite2D.new()
	_gorsel.texture = DOKU
	_gorsel.hframes = 3
	_gorsel.frame = tur
	add_child(_gorsel)
	if tur == TUR_HAREKETLI:
		_t = faz * TAU
		position = _hareketli_konum()
	_renk_guncelle()

func _process(delta: float) -> void:
	if tur == TUR_HAREKETLI and not _kirildi:
		var uzunluk := a.distance_to(b)
		if uzunluk > 1.0:
			_t += delta * hiz / uzunluk * PI
			position = _hareketli_konum()
	if _kirilma_sayaci > 0.0:
		_kirilma_sayaci -= delta
		_gorsel.visible = fmod(_kirilma_sayaci, 0.12) > 0.06
		if _kirilma_sayaci <= 0.0:
			_kir()

func _hareketli_konum() -> Vector2:
	return a.lerp(b, 0.5 - 0.5 * cos(_t))

# --- Durum ------------------------------------------------------------

## Nisangahta bu nokta secili mi.
func vurgu(acik: bool) -> void:
	if acik != _vurgulu:
		_vurgulu = acik
		_renk_guncelle()

## Kanca su an bu noktaya bagli mi.
func bagla(acik: bool) -> void:
	if acik == _bagli:
		return
	_bagli = acik
	_renk_guncelle()
	if not acik and tur == TUR_KIRILGAN and not _kirildi:
		_kirilma_sayaci = Ayarlar.KIRILGAN_UYARI

## Kanca atilabilir mi (kirilmis nokta aday olamaz).
func kullanilabilir() -> bool:
	return not _kirildi

func _kir() -> void:
	_kirildi = true
	_gorsel.visible = false
	remove_from_group(GRUP)
	Ses.cal("kirilma")
	var olay := get_tree().get_first_node_in_group(&"bolum")
	if olay != null and olay.has_method("parcacik_at"):
		olay.parcacik_at(global_position, Palet.NOKTA_KIRIK, 12)

func _renk_guncelle() -> void:
	if _gorsel == null:
		return
	if _bagli:
		_gorsel.modulate = Color(1.35, 1.2, 0.75)
		_gorsel.scale = Vector2(1.15, 1.15)
	elif _vurgulu:
		_gorsel.modulate = Color(1.5, 1.5, 1.5)
		_gorsel.scale = Vector2(1.08, 1.08)
	else:
		_gorsel.modulate = Color(1, 1, 1)
		_gorsel.scale = Vector2.ONE
