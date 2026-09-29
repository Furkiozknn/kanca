extends Node2D
class_name KancaNoktasi
## Kancanin takilabilecegi nokta. Uc tur var:
##   TUR_SABIT     - yerinde durur
##   TUR_HAREKETLI - iki uc arasinda gidip gelir (halat capasi da hareket eder)
##   TUR_KIRILGAN  - bir kez tutulur; birakilinca kisa bir uyari sonrasi kirilir
##
## Gorsel kodla cizilir (duz renk): sabit = dolu disk (video demirinin aynisi),
## hareketli = disk + turuncu halka, kirilgan = kesik halka. Secili aday
## turuncuya doner, bagliyken buyur; menzil disi soluk. PNG yok.

const GRUP := &"kanca_noktasi"

enum { TUR_SABIT, TUR_HAREKETLI, TUR_KIRILGAN }

var tur := TUR_SABIT
var a := Vector2.ZERO          ## hareketli: bir uc
var b := Vector2.ZERO          ## hareketli: obur uc
var hiz := Ayarlar.HAREKETLI_HIZ
var faz := 0.0                 ## hareketli: baslangic fazi (0..1)

var _vurgulu := false
var _bagli := false
var _menzilde := true           ## menzil disindaki noktalar soluk/gri gorunur
var _rotada := false            ## altin madalyadan sonra acilan rota ipucu isareti
var _kirildi := false
var _kirilma_sayaci := 0.0
var _t := 0.0
var _gorsel: Node2D

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
	z_index = 6
	_gorsel = Node2D.new()
	_gorsel.draw.connect(_ciz)
	add_child(_gorsel)
	if tur == TUR_HAREKETLI:
		_t = faz * TAU
		position = _hareketli_konum()
	_renk_guncelle()

## Fizik karesinde hareket eder: headless botun ve testlerin gordugu hareket
## gercek oyundakiyle birebir ayni olsun (process delta gercek zamana bagli).
func _physics_process(delta: float) -> void:
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

## Nisan menzili icinde mi (disindakiler soluk cizilir).
func menzilde(acik: bool) -> void:
	if acik != _menzilde:
		_menzilde = acik
		_renk_guncelle()

## Rota ipucu: altin madalyadan sonra hayaletin kullandigi noktalar isaretlenir.
func rotada(acik: bool) -> void:
	if acik != _rotada:
		_rotada = acik
		_renk_guncelle()

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
		olay.parcacik_at(global_position, Tema.blok(), 12)

func _renk_guncelle() -> void:
	if _gorsel == null:
		return
	if _bagli:
		_gorsel.scale = Vector2(1.2, 1.2)
	elif _vurgulu:
		_gorsel.scale = Vector2(1.12, 1.12)
	elif _rotada and _menzilde:
		_gorsel.scale = Vector2(1.05, 1.05)
	else:
		_gorsel.scale = Vector2.ONE
	_gorsel.queue_redraw()

func _ciz() -> void:
	var b := Tema.blok()
	var renk := b
	if _bagli or _vurgulu:
		renk = Tema.TURUNCU
	elif not _menzilde:
		# Menzil disi: soluk - nereye kanca atilamayacagi bir bakista belli.
		renk = Color(b, 0.28)
	match tur:
		TUR_SABIT:
			_gorsel.draw_circle(Vector2.ZERO, 4.5, renk, true, -1.0, true)
		TUR_HAREKETLI:
			_gorsel.draw_circle(Vector2.ZERO, 3.5, renk, true, -1.0, true)
			var halka := Tema.TURUNCU if _menzilde else Color(Tema.TURUNCU, 0.3)
			_gorsel.draw_arc(Vector2.ZERO, 6.5, 0.0, TAU, 24, halka, 1.6, true)
		TUR_KIRILGAN:
			# Kesik halka: sekiz yay, aralarinda bosluk.
			for i in 8:
				var a0 := float(i) * TAU / 8.0
				_gorsel.draw_arc(Vector2.ZERO, 5.0, a0, a0 + TAU / 8.0 * 0.6, 5, renk, 2.0, true)
	if _rotada and _menzilde and not (_bagli or _vurgulu):
		# Altin madalyadan sonra acilan rota ipucu: turkuaz nokta halkasi.
		_gorsel.draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, Color(Tema.TURKUAZ, 0.9), 1.2, true)
