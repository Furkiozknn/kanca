extends Control
## Ana menu + bolum secme + ayarlar (ucu ayni sahnede, panel degistirerek).

var _ana: Control
var _secim: Control
var _ayar: Control

func _ready() -> void:
	RenderingServer.set_default_clear_color(Ayarlar.RENK_ARKAPLAN)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arka_plan()
	_ana = _ana_panel()
	add_child(_ana)
	_secim = _secim_paneli()
	add_child(_secim)
	_ayar = _ayar_paneli()
	add_child(_ayar)
	_secim.visible = false
	_ayar.visible = false
	_ana.find_child("Basla", true, false).grab_focus()
	Ses.muzik_cal("muzik_menu")

func _unhandled_input(olay: InputEvent) -> void:
	if olay.is_action_pressed("duraklat") and (_secim.visible or _ayar.visible):
		_ana_goster()
		get_viewport().set_input_as_handled()

# --- Arka plan --------------------------------------------------------

func _arka_plan() -> void:
	var gok := TextureRect.new()
	gok.texture = preload("res://assets/sprites/arka_gok.png")
	gok.stretch_mode = TextureRect.STRETCH_SCALE
	gok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gok)
	var ada := TextureRect.new()
	ada.texture = preload("res://assets/sprites/arka_uzak.png")
	ada.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ada.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ada.modulate = Color(1, 1, 1, 0.8)
	ada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ada)

# --- Paneller ---------------------------------------------------------

func _kutu_panel() -> Array:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)
	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 6)
	orta.add_child(kutu)
	return [kok, kutu]

func _ana_panel() -> Control:
	var p := _kutu_panel()
	var kok: Control = p[0]
	var kutu: VBoxContainer = p[1]

	var logo := TextureRect.new()
	logo.texture = preload("res://assets/sprites/logo.png")
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(
		logo.texture.get_width() * 2.0, logo.texture.get_height() * 2.0)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kutu.add_child(logo)
	kutu.add_child(_etiket("Sallan, bırak, uç. En kısa sürede bitir.", 12, Ayarlar.RENK_METIN))
	kutu.add_child(_bosluk(14))

	var acik := Kayit.acik_bolum()
	kutu.add_child(_dugme("Basla", "Başla  —  %d. bölüm" % acik, _basla))
	kutu.add_child(_dugme("Sec", "Bölüm Seç", _secim_goster))
	kutu.add_child(_dugme("Ayar", "Ayarlar", _ayar_goster))
	kutu.add_child(_dugme("Cikis", "Çıkış", _cikis))
	kutu.add_child(_bosluk(14))
	kutu.add_child(_etiket(
		"Fare: nişan  •  Sol tık: kanca  •  A/D: koş & salın\nBoşluk: zıpla  •  W/S: halatı kısalt/uzat  •  R: yeniden",
		10, Ayarlar.RENK_METIN_SOLUK))
	return kok

func _secim_paneli() -> Control:
	var p := _kutu_panel()
	var kok: Control = p[0]
	var kutu: VBoxContainer = p[1]

	kutu.add_child(_etiket("BÖLÜM SEÇ", 20, Color(1, 1, 1)))

	var izgara := GridContainer.new()
	izgara.columns = 5
	izgara.add_theme_constant_override("h_separation", 5)
	izgara.add_theme_constant_override("v_separation", 5)
	kutu.add_child(izgara)

	var acik := Kayit.acik_bolum()
	for no in range(1, Bolumler.sayi() + 1):
		izgara.add_child(_bolum_dugmesi(no, no <= acik))

	kutu.add_child(_bosluk(6))
	kutu.add_child(_etiket("Madalya: altın / gümüş / bronz hedef süreler bölüm içinde yazılı.",
		10, Ayarlar.RENK_METIN_SOLUK))
	kutu.add_child(_dugme("Geri", "Geri  (Esc)", _ana_goster))
	kutu.add_child(_dugme("Sifirla", "Kayıtları sıfırla", _sifirla))
	return kok

## Bolum dugmesi: numara, ad, en iyi sure ve kazanilan madalya.
func _bolum_dugmesi(no: int, acik: bool) -> Control:
	var d := Button.new()
	d.custom_minimum_size = Vector2(112, 44)
	d.add_theme_font_size_override("font_size", 10)
	var sure := Kayit.en_iyi(no)
	d.text = "%d. %s\n%s" % [no, Bolumler.ad(no), Bolum._bicim(sure) if sure > 0.0 else "—"]
	d.disabled = not acik
	d.pressed.connect(_bolume_git.bind(no))
	if sure > 0.0:
		var m := Bolum.madalya_simgesi(Bolumler.madalya(no, sure))
		m.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		m.offset_left = -15.0
		m.offset_top = 3.0
		m.offset_right = -3.0
		m.offset_bottom = 15.0
		d.add_child(m)
	return d

func _ayar_paneli() -> Control:
	return AyarPanel.yap(_ana_goster)

# --- Islevler ---------------------------------------------------------

func _basla() -> void:
	_bolume_git(Kayit.acik_bolum())

func _bolume_git(no: int) -> void:
	Ses.cal("menu")
	Gecis.git(Bolumler.yol(no))

func _secim_goster() -> void:
	Ses.cal("menu")
	_ana.visible = false
	_ayar.visible = false
	_secim.visible = true
	_secim.find_child("Geri", true, false).grab_focus()

func _ayar_goster() -> void:
	Ses.cal("menu")
	_ana.visible = false
	_secim.visible = false
	_ayar.visible = true
	_ayar.find_child("GeriAyar", true, false).grab_focus()

func _ana_goster() -> void:
	Ses.cal("menu")
	_secim.visible = false
	_ayar.visible = false
	_ana.visible = true
	_ana.find_child("Basla", true, false).grab_focus()

func _sifirla() -> void:
	Kayit.sifirla()
	get_tree().reload_current_scene()

func _cikis() -> void:
	get_tree().quit()

# --- Yardimcilar ------------------------------------------------------

func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var e := Bolum.etiket_yap(metin, boy, renk)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return e

func _dugme(ad: String, metin: String, islev: Callable) -> Button:
	var d := Button.new()
	d.name = ad
	d.text = metin
	d.add_theme_font_size_override("font_size", 13)
	d.pressed.connect(islev)
	return d

func _bosluk(yukseklik: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, yukseklik)
	return c
