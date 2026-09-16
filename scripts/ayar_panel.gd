extends RefCounted
class_name AyarPanel
## Ayarlar paneli. Hem ana menude hem duraklatma menusunde ayni panel kullanilir
## (duraklatmadaki "Ayarlar" dugmesi bolumu terk etmesin diye).
##
## Butun degerler Kayit uzerinden okunur/yazilir; Kayit.ayar_yaz zaten ses
## duzeyini ve pencere kipini uyguluyor.

## geri: "Geri" dugmesine basilinca cagrilacak islev.
## perde: arkaya karartma koyulsun mu (bolum icinde evet, menude hayir).
static func yap(geri: Callable, perde := false) -> Control:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.mouse_filter = Control.MOUSE_FILTER_STOP if perde else Control.MOUSE_FILTER_PASS
	kok.visible = false

	if perde:
		var p := ColorRect.new()
		p.color = Color(Palet.GOK_DIP, 0.85)
		p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		kok.add_child(p)

	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)

	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 6)
	orta.add_child(kutu)

	var baslik := Bolum.etiket_yap("AYARLAR", 20, Color(1, 1, 1))
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(baslik)
	kutu.add_child(_bosluk(6))
	kutu.add_child(_kaydirac("Müzik", "muzik_ses", "muzik_acik"))
	kutu.add_child(_kaydirac("Efekt", "efekt_ses", "efekt_acik"))
	kutu.add_child(_bosluk(6))
	kutu.add_child(_anahtar("Tam ekran", "tam_ekran"))
	kutu.add_child(_anahtar("Hayalet (en iyi koşun)", "hayalet"))
	kutu.add_child(_anahtar("Ekran sarsıntısı", "sarsinti"))
	kutu.add_child(_bosluk(10))

	var d := Button.new()
	d.name = "GeriAyar"
	d.text = "Geri  (Esc)"
	d.add_theme_font_size_override("font_size", 13)
	d.pressed.connect(geri)
	kutu.add_child(d)
	return kok

## Ses kaydiraci + ac/kapa dugmesi tek satirda.
static func _kaydirac(baslik: String, oran_ad: String, acik_ad: String) -> Control:
	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 8)
	var e := Bolum.etiket_yap(baslik, 12, Ayarlar.RENK_METIN)
	e.custom_minimum_size = Vector2(56, 0)
	satir.add_child(e)

	var yuzde := Bolum.etiket_yap("", 11, Ayarlar.RENK_METIN_SOLUK)
	yuzde.custom_minimum_size = Vector2(38, 0)

	var k := HSlider.new()
	k.custom_minimum_size = Vector2(150, 18)
	k.min_value = 0.0
	k.max_value = 1.0
	k.step = 0.05
	k.value = float(Kayit.ayar(oran_ad))
	k.value_changed.connect(func(v: float) -> void:
		Kayit.ayar_yaz(oran_ad, v)
		yuzde.text = "%d%%" % int(v * 100.0)
		Ses.cal("menu"))
	satir.add_child(k)
	yuzde.text = "%d%%" % int(k.value * 100.0)
	satir.add_child(yuzde)

	var ac := CheckButton.new()
	ac.button_pressed = bool(Kayit.ayar(acik_ad))
	ac.toggled.connect(func(v: bool) -> void:
		Kayit.ayar_yaz(acik_ad, v)
		Ses.cal("menu"))
	satir.add_child(ac)
	return satir

static func _anahtar(baslik: String, ad: String) -> Control:
	var c := CheckButton.new()
	c.text = baslik
	c.add_theme_font_size_override("font_size", 12)
	c.button_pressed = bool(Kayit.ayar(ad))
	c.toggled.connect(func(v: bool) -> void:
		Kayit.ayar_yaz(ad, v)
		Ses.cal("menu"))
	return c

static func _bosluk(yukseklik: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, yukseklik)
	return c
