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
	orta.name = "AnaKutu"
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
	kutu.add_child(_oran("Nişan", "nisan_hassasiyet", "yardım", "tam nişan"))
	kutu.add_child(_bosluk(6))
	kutu.add_child(_anahtar("Tam ekran", "tam_ekran"))
	kutu.add_child(_anahtar("Hayalet (en iyi koşun)", "hayalet"))
	kutu.add_child(_anahtar("Ekran sarsıntısı", "sarsinti"))
	kutu.add_child(_anahtar("Rota ipucu (altın madalyadan sonra)", "rota_ipucu"))
	kutu.add_child(_anahtar("Tek parmak şeması (dokunmatik)", "dokunmatik"))
	kutu.add_child(_bosluk(8))

	# Tus atama ayri bir kutuda; ayni kok icinde gorunurluk degistiriliyor.
	var tus_orta := CenterContainer.new()
	tus_orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tus_orta.name = "TusKutusu"
	tus_orta.visible = false
	kok.add_child(tus_orta)
	tus_orta.add_child(_tus_kutusu(func() -> void:
		tus_orta.visible = false
		orta.visible = true
		kok.find_child("TusAtama", true, false).grab_focus()
		Ses.cal("menu")))

	var t := Button.new()
	t.name = "TusAtama"
	t.text = "Tuş atama"
	t.add_theme_font_size_override("font_size", 13)
	t.pressed.connect(func() -> void:
		orta.visible = false
		tus_orta.visible = true
		tus_orta.find_child("GeriTus", true, false).grab_focus()
		Ses.cal("menu"))
	kutu.add_child(t)

	var d := Button.new()
	d.name = "GeriAyar"
	d.text = "Geri  (Esc)"
	d.add_theme_font_size_override("font_size", 13)
	d.pressed.connect(geri)
	kutu.add_child(d)
	return kok

## Ayarlar her acilista ana kutudan baslasin (tus atama acik kalmasin).
static func ana_kutuya_don(kok: Control) -> void:
	var tus := kok.find_child("TusKutusu", true, false)
	if tus != null:
		tus.visible = false
	var ana := kok.find_child("AnaKutu", true, false)
	if ana != null:
		ana.visible = true

## Tus atama kutusu: her eylem icin bir TusDugmesi + varsayilana don.
static func _tus_kutusu(geri: Callable) -> Control:
	var kutu := VBoxContainer.new()
	kutu.add_theme_constant_override("separation", 3)
	var baslik := Bolum.etiket_yap("TUŞ ATAMA", 16, Color(1, 1, 1))
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(baslik)
	kutu.add_child(Bolum.etiket_yap("Tuşa bas: değiştir · Esc: vazgeç", 10, Ayarlar.RENK_METIN_SOLUK))

	var dugmeler: Array[TusDugmesi] = []
	for eylem: String in Tuslar.EYLEMLER:
		var satir := HBoxContainer.new()
		satir.add_theme_constant_override("separation", 8)
		var e := Bolum.etiket_yap(String(Tuslar.EYLEMLER[eylem]), 11, Ayarlar.RENK_METIN)
		e.custom_minimum_size = Vector2(150, 0)
		satir.add_child(e)
		var d := TusDugmesi.yap(eylem)
		dugmeler.append(d)
		satir.add_child(d)
		kutu.add_child(satir)

	kutu.add_child(_bosluk(6))
	var sifirla := Button.new()
	sifirla.text = "Varsayılana dön"
	sifirla.add_theme_font_size_override("font_size", 12)
	sifirla.pressed.connect(func() -> void:
		Kayit.tuslari_sifirla()
		for d: TusDugmesi in dugmeler:
			d._yaz()
		Ses.cal("menu"))
	kutu.add_child(sifirla)

	var g := Button.new()
	g.name = "GeriTus"
	g.text = "Geri"
	g.add_theme_font_size_override("font_size", 12)
	g.pressed.connect(geri)
	kutu.add_child(g)
	return kutu

## Etiketli oran kaydiraci (uclarinda ne anlama geldigi yazili).
static func _oran(baslik: String, ad: String, sol: String, sag: String) -> Control:
	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 8)
	var e := Bolum.etiket_yap(baslik, 12, Ayarlar.RENK_METIN)
	e.custom_minimum_size = Vector2(56, 0)
	satir.add_child(e)
	var k := HSlider.new()
	k.custom_minimum_size = Vector2(150, 18)
	k.min_value = 0.0
	k.max_value = 1.0
	k.step = 0.05
	k.value = float(Kayit.ayar(ad))
	var not_metni := Bolum.etiket_yap("", 10, Ayarlar.RENK_METIN_SOLUK)
	not_metni.custom_minimum_size = Vector2(72, 0)
	k.value_changed.connect(func(v: float) -> void:
		Kayit.ayar_yaz(ad, v)
		not_metni.text = sol if v < 0.34 else (sag if v > 0.66 else "orta")
		Ses.cal("menu"))
	satir.add_child(k)
	not_metni.text = sol if k.value < 0.34 else (sag if k.value > 0.66 else "orta")
	satir.add_child(not_metni)
	return satir

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
