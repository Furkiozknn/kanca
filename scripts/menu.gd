extends Control
## Ana menu + bolum secme ekrani (ikisi ayni sahnede, panel degistirerek).

var _ana: Control
var _secim: Control

func _ready() -> void:
	RenderingServer.set_default_clear_color(Ayarlar.RENK_ARKAPLAN)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ana = _ana_panel()
	add_child(_ana)
	_secim = _secim_paneli()
	add_child(_secim)
	_secim.visible = false
	_ana.find_child("Basla", true, false).grab_focus()

func _unhandled_input(olay: InputEvent) -> void:
	if olay.is_action_pressed("duraklat") and _secim.visible:
		_ana_goster()
		get_viewport().set_input_as_handled()

# --- Paneller ---------------------------------------------------------

func _ana_panel() -> Control:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)

	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 6)
	orta.add_child(kutu)

	kutu.add_child(_etiket("KANCA", 34, Color(0.95, 0.85, 0.45)))
	kutu.add_child(_etiket("Sallan, bırak, uç. En kısa sürede bitir.", 12, Color(0.65, 0.7, 0.82)))
	kutu.add_child(_bosluk(14))

	var acik := Kayit.acik_bolum()
	var basla := _dugme("Basla", "Başla  —  %d. bölüm" % acik, _basla)
	kutu.add_child(basla)
	kutu.add_child(_dugme("Sec", "Bölüm Seç", _secim_goster))
	kutu.add_child(_dugme("Cikis", "Çıkış", _cikis))
	kutu.add_child(_bosluk(14))
	kutu.add_child(_etiket(
		"Fare: nişan  •  Sol tık: kanca  •  A/D: koş & salın\nBoşluk: zıpla  •  W/S: halatı kısalt/uzat  •  R: yeniden",
		10, Color(0.5, 0.55, 0.68)))
	return kok

func _secim_paneli() -> Control:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)

	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 6)
	orta.add_child(kutu)

	kutu.add_child(_etiket("BÖLÜM SEÇ", 20, Color(1, 1, 1)))

	var izgara := GridContainer.new()
	izgara.columns = 4
	izgara.add_theme_constant_override("h_separation", 6)
	izgara.add_theme_constant_override("v_separation", 6)
	kutu.add_child(izgara)

	var acik := Kayit.acik_bolum()
	for no in range(1, Bolumler.sayi() + 1):
		var d := Button.new()
		d.custom_minimum_size = Vector2(118, 40)
		d.add_theme_font_size_override("font_size", 11)
		var sure := Kayit.en_iyi(no)
		d.text = "%d. %s\n%s" % [no, Bolumler.ad(no), Bolum._bicim(sure) if sure > 0.0 else "—"]
		d.disabled = no > acik
		d.pressed.connect(_bolume_git.bind(no))
		izgara.add_child(d)

	kutu.add_child(_bosluk(10))
	kutu.add_child(_dugme("Geri", "Geri  (Esc)", _ana_goster))
	kutu.add_child(_dugme("Sifirla", "Kayıtları sıfırla", _sifirla))
	return kok

# --- Islevler ---------------------------------------------------------

func _basla() -> void:
	_bolume_git(Kayit.acik_bolum())

func _bolume_git(no: int) -> void:
	get_tree().change_scene_to_file(Bolumler.yol(no))

func _secim_goster() -> void:
	_ana.visible = false
	_secim.visible = true
	_secim.find_child("Geri", true, false).grab_focus()

func _ana_goster() -> void:
	_secim.visible = false
	_ana.visible = true
	_ana.find_child("Basla", true, false).grab_focus()

func _sifirla() -> void:
	Kayit.sifirla()
	get_tree().reload_current_scene()

func _cikis() -> void:
	get_tree().quit()

# --- Yardimcilar ------------------------------------------------------

func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var e := Label.new()
	e.text = metin
	e.add_theme_font_size_override("font_size", boy)
	e.add_theme_color_override("font_color", renk)
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
