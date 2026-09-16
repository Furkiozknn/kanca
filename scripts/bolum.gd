extends Node2D
class_name Bolum
## Tek bir bolumun tamami: geometriyi Bolumler.VERI tablosundan kurar,
## sureyi tutar, olum/bitis akisini ve arayuzu yonetir.
##
## Sahne dosyalari (scenes/bolumler/bolum_NN.tscn) sadece bolum_no tasir;
## boylece 8 bolum tek kod yolundan uretilir ve veri tek yerde durur.

const OYUNCU_SAHNE := preload("res://scenes/oyuncu.tscn")
const MENU_YOLU := "res://scenes/menu.tscn"

@export var bolum_no: int = 1

var _veri: Dictionary = {}
var _oyuncu: Oyuncu = null
var _sure: float = 0.0
var _sayiyor: bool = false
var _duraklatildi: bool = false
var _bitti: bool = false

var _sure_etiket: Label
var _eniyi_etiket: Label
var _duraklat_panel: Control
var _bitis_panel: Control
var _bitis_metin: Label
var _sonraki_dugme: Button

func _ready() -> void:
	_veri = Bolumler.veri(bolum_no)
	RenderingServer.set_default_clear_color(Ayarlar.RENK_ARKAPLAN)
	_dunyayi_kur()
	_arayuzu_kur()
	_basa_al()
	_alanlari_ac.call_deferred()

## Oyuncu dogru yere yerlestikten sonra tehlike/bitis alanlarini acar.
## (Yeni kurulan Area2D ayni karede bayat bir ortusmeyi body_entered sayabiliyor.)
func _alanlari_ac() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	for a in find_children("", "Area2D", true, false):
		a.monitoring = true

# --- Dunya ------------------------------------------------------------

func _dunyayi_kur() -> void:
	var dunya := Node2D.new()
	dunya.name = "Dunya"
	add_child(dunya)

	for r: Rect2 in _veri["zemin"]:
		dunya.add_child(_kati_blok(r))
	for r: Rect2 in _veri["diken"]:
		dunya.add_child(_diken(r))
	for p: Vector2 in _veri["kanca"]:
		var nokta := KancaNoktasi.new()
		nokta.position = p
		dunya.add_child(nokta)

	dunya.add_child(_bitis_bayragi(_veri["bitis"]))

	_oyuncu = OYUNCU_SAHNE.instantiate()
	add_child(_oyuncu)
	_kamera_sinirla()

func _kati_blok(r: Rect2) -> StaticBody2D:
	var govde := StaticBody2D.new()
	govde.position = r.position + r.size * 0.5
	var sekil := RectangleShape2D.new()
	sekil.size = r.size
	var carpisma := CollisionShape2D.new()
	carpisma.shape = sekil
	govde.add_child(carpisma)
	govde.add_child(_dikdortgen(r.size, Ayarlar.RENK_ZEMIN))
	# Ust kenar cizgisi: zeminin nerede bittigi net gorunsun.
	var ust := _dikdortgen(Vector2(r.size.x, 4.0), Ayarlar.RENK_ZEMIN_UST)
	ust.position = Vector2(0.0, -r.size.y * 0.5 + 2.0)
	govde.add_child(ust)
	return govde

func _diken(r: Rect2) -> Area2D:
	var alan := Area2D.new()
	alan.position = r.position + r.size * 0.5
	alan.monitorable = false
	alan.monitoring = false   # bayat ortusme tuzagi: ilk fizik karesinden sonra acilir
	var sekil := RectangleShape2D.new()
	sekil.size = r.size
	var carpisma := CollisionShape2D.new()
	carpisma.shape = sekil
	alan.add_child(carpisma)
	# Testere disleri
	var noktalar := PackedVector2Array()
	var dis_sayisi := maxi(1, int(r.size.x / 12.0))
	var genislik := r.size.x / float(dis_sayisi)
	for i in dis_sayisi:
		var x := -r.size.x * 0.5 + i * genislik
		noktalar.append(Vector2(x, r.size.y * 0.5))
		noktalar.append(Vector2(x + genislik * 0.5, -r.size.y * 0.5))
		noktalar.append(Vector2(x + genislik, r.size.y * 0.5))
	var gorsel := Polygon2D.new()
	gorsel.polygon = noktalar
	gorsel.color = Ayarlar.RENK_DIKEN
	alan.add_child(gorsel)
	alan.body_entered.connect(_tehlikeye_degdi)
	return alan

func _bitis_bayragi(yer: Vector2) -> Area2D:
	var alan := Area2D.new()
	alan.position = yer
	alan.monitorable = false
	alan.monitoring = false   # bayat ortusme tuzagi: ilk fizik karesinden sonra acilir
	var sekil := RectangleShape2D.new()
	sekil.size = Vector2(24, 56)
	var carpisma := CollisionShape2D.new()
	carpisma.shape = sekil
	alan.add_child(carpisma)
	var direk := _dikdortgen(Vector2(3, 56), Ayarlar.RENK_BITIS)
	alan.add_child(direk)
	var bayrak := Polygon2D.new()
	bayrak.polygon = PackedVector2Array([Vector2(2, -28), Vector2(22, -20), Vector2(2, -12)])
	bayrak.color = Ayarlar.RENK_BITIS
	alan.add_child(bayrak)
	alan.name = "Bitis"
	alan.body_entered.connect(_bitise_degdi)
	return alan

func _dikdortgen(boyut: Vector2, renk: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var y := boyut * 0.5
	p.polygon = PackedVector2Array([-y, Vector2(y.x, -y.y), y, Vector2(-y.x, y.y)])
	p.color = renk
	return p

func _kamera_sinirla() -> void:
	var sinir := Rect2(_veri["basla"], Vector2.ZERO)
	for r: Rect2 in _veri["zemin"]:
		sinir = sinir.merge(r)
	sinir = sinir.expand(_veri["bitis"] + Vector2(80, 0))
	var kamera: Camera2D = _oyuncu.get_node("Kamera")
	kamera.limit_left = int(sinir.position.x) - 40
	kamera.limit_right = int(sinir.end.x) + 40
	kamera.limit_top = int(sinir.position.y) - 140
	kamera.limit_bottom = int(sinir.end.y) + 60

# --- Akis -------------------------------------------------------------

func _basa_al() -> void:
	_oyuncu.kanca_birak()
	_oyuncu.global_position = _veri["basla"]
	_oyuncu.velocity = Vector2.ZERO
	_oyuncu.girdi_aktif = true
	_oyuncu.set_physics_process(true)
	_sure = 0.0
	_sayiyor = true
	_bitti = false
	_duraklatildi = false
	_duraklat_panel.visible = false
	_bitis_panel.visible = false
	_sure_yaz()

func _process(delta: float) -> void:
	if _sayiyor:
		_sure += delta
		_sure_yaz()
	if not _bitti and not _duraklatildi and _oyuncu.global_position.y > Ayarlar.OLUM_Y:
		_basa_al()

func _tehlikeye_degdi(govde: Node2D) -> void:
	if govde == _oyuncu and not _bitti:
		_basa_al()

func _bitise_degdi(govde: Node2D) -> void:
	if govde != _oyuncu or _bitti:
		return
	_bitti = true
	_sayiyor = false
	_oyuncu.girdi_aktif = false
	_oyuncu.kanca_birak()
	_oyuncu.set_physics_process(false)

	var rekor := Kayit.sure_yaz(bolum_no, _sure)
	Kayit.bolum_ac(mini(bolum_no + 1, Bolumler.sayi()))

	var satirlar := [
		"%d. bölüm — %s" % [bolum_no, Bolumler.ad(bolum_no)],
		"Süre: %s" % _bicim(_sure),
		"YENİ REKOR!" if rekor else "En iyi: %s" % _bicim(Kayit.en_iyi(bolum_no)),
	]
	_bitis_metin.text = "\n".join(PackedStringArray(satirlar))
	_bitis_panel.visible = true
	_sonraki_dugme.disabled = bolum_no >= Bolumler.sayi()
	_sonraki_dugme.grab_focus()

func _unhandled_input(olay: InputEvent) -> void:
	if olay.is_action_pressed("duraklat"):
		if _bitti:
			_menuye()
		else:
			_duraklat_degistir()
	elif olay.is_action_pressed("yeniden") and not _duraklatildi:
		_yeniden()
	elif _bitti and olay.is_action_pressed("ui_accept") and not _sonraki_dugme.disabled:
		_sonraki()
	else:
		return
	get_viewport().set_input_as_handled()

func _duraklat_degistir() -> void:
	_duraklatildi = not _duraklatildi
	_duraklat_panel.visible = _duraklatildi
	_sayiyor = not _duraklatildi
	_oyuncu.set_physics_process(not _duraklatildi)
	if _duraklatildi:
		_duraklat_panel.find_child("Devam", true, false).grab_focus()

func _yeniden() -> void:
	_basa_al()

func _sonraki() -> void:
	if bolum_no < Bolumler.sayi():
		get_tree().change_scene_to_file(Bolumler.yol(bolum_no + 1))

func _menuye() -> void:
	get_tree().change_scene_to_file(MENU_YOLU)

# --- Arayuz -----------------------------------------------------------

func _sure_yaz() -> void:
	_sure_etiket.text = "Süre  %s" % _bicim(_sure)

static func _bicim(saniye: float) -> String:
	if saniye <= 0.0:
		return "--:--"
	return "%02d:%05.2f" % [int(saniye) / 60, fmod(saniye, 60.0)]

func _arayuzu_kur() -> void:
	var katman := CanvasLayer.new()
	katman.name = "Arayuz"
	add_child(katman)

	_sure_etiket = _etiket("", 16, Color(1, 1, 1))
	_sure_etiket.position = Vector2(12, 8)
	katman.add_child(_sure_etiket)

	_eniyi_etiket = _etiket("En iyi  %s" % _bicim(Kayit.en_iyi(bolum_no)), 11, Color(0.7, 0.75, 0.85))
	_eniyi_etiket.position = Vector2(12, 30)
	katman.add_child(_eniyi_etiket)

	var baslik := _etiket("%d. %s" % [bolum_no, _veri["ad"]], 11, Color(0.7, 0.75, 0.85))
	baslik.position = Vector2(12, 46)
	katman.add_child(baslik)

	var yardim := _etiket("R: yeniden   Esc: duraklat", 10, Color(0.55, 0.6, 0.7))
	yardim.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	yardim.offset_left = -12.0
	yardim.offset_right = -12.0
	yardim.offset_top = 10.0
	yardim.offset_bottom = 26.0
	yardim.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	katman.add_child(yardim)

	var ipucu := String(_veri["ipucu"])
	if ipucu != "":
		var e := _etiket(ipucu, 11, Color(0.95, 0.9, 0.6))
		e.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		e.offset_top = -34.0
		e.offset_bottom = -14.0
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		katman.add_child(e)

	_duraklat_panel = _panel("DURAKLATILDI", [
		{"ad": "Devam", "metin": "Devam", "islev": _duraklat_degistir},
		{"ad": "Yeniden", "metin": "Bölümü yeniden başla", "islev": _yeniden},
		{"ad": "Menu", "metin": "Menüye dön", "islev": _menuye},
	])
	katman.add_child(_duraklat_panel)

	_bitis_panel = _panel("BÖLÜM BİTTİ", [
		{"ad": "Sonraki", "metin": "Sonraki bölüm  (Enter)", "islev": _sonraki},
		{"ad": "Yeniden", "metin": "Tekrar dene  (R)", "islev": _yeniden},
		{"ad": "Menu", "metin": "Menüye dön  (Esc)", "islev": _menuye},
	])
	katman.add_child(_bitis_panel)
	_bitis_metin = _bitis_panel.find_child("Baslik", true, false)
	_sonraki_dugme = _bitis_panel.find_child("Sonraki", true, false)

func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var e := Label.new()
	e.text = metin
	e.add_theme_font_size_override("font_size", boy)
	e.add_theme_color_override("font_color", renk)
	return e

func _panel(baslik: String, dugmeler: Array) -> Control:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.mouse_filter = Control.MOUSE_FILTER_STOP
	kok.visible = false

	var perde := ColorRect.new()
	perde.color = Color(0.04, 0.05, 0.09, 0.82)
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(perde)

	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)

	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 8)
	orta.add_child(kutu)

	var b := _etiket(baslik, 16, Color(1, 1, 1))
	b.name = "Baslik"
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(b)

	for d: Dictionary in dugmeler:
		var dugme := Button.new()
		dugme.name = String(d["ad"])
		dugme.text = String(d["metin"])
		dugme.add_theme_font_size_override("font_size", 12)
		dugme.pressed.connect(d["islev"])
		kutu.add_child(dugme)

	return kok
