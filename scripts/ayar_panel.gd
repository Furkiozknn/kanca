extends RefCounted
class_name AyarPanel
## Ayarlar paneli. Hem ana menude hem duraklatma menusunde ayni panel kullanilir
## (duraklatmadaki "Ayarlar" dugmesi bolumu terk etmesin diye).
##
## Iki sutun: SES ve GORUNTU (muzik, efekt, DIL, tam ekran) | OYNANIS (nisan,
## hayalet, sarsinti, rota ipucu, tek parmak). Butun degerler Kayit uzerinden
## okunur/yazilir; Kayit.ayar_yaz zaten ses duzeyini, pencere kipini ve dili
## uyguluyor.

const SUTUN_G := 236.0

## geri: "Geri" dugmesine basilinca cagrilacak islev.
## perde: arkaya karartma koyulsun mu (bolum icinde evet, menude hayir).
## dil_degisti: dil dugmesine basilinca cagrilir (cagiran arayuzu yeniden kurar).
static func yap(geri: Callable, perde := false, dil_degisti := Callable()) -> Control:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.mouse_filter = Control.MOUSE_FILTER_STOP if perde else Control.MOUSE_FILTER_PASS
	kok.visible = false

	if perde:
		var p := Panel.new()
		p.theme_type_variation = &"Perde"
		p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kok.add_child(p)

	var orta := CenterContainer.new()
	orta.name = "AnaKutu"
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)

	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 6)
	orta.add_child(kutu)

	var baslik := Tema.etiket(Ceviri.t("AYARLAR"), 16, Tema.KAGIT, false, true)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(baslik)

	var sutunlar := HBoxContainer.new()
	sutunlar.add_theme_constant_override("separation", 30)
	kutu.add_child(sutunlar)

	var sol := _sutun(Ceviri.t("SES VE GÖRÜNTÜ"))
	sol.add_child(_kaydirac(Ceviri.t("Müzik"), "muzik_ses", "muzik_acik"))
	sol.add_child(_kaydirac(Ceviri.t("Efekt"), "efekt_ses", "efekt_acik"))
	sol.add_child(_dil(dil_degisti))
	sol.add_child(_anahtar(Ceviri.t("Tam ekran"), "tam_ekran"))
	sol.add_child(_anahtar(Ceviri.t("Sade geçişler (hareketi azalt)"), "gecis_sade"))
	sutunlar.add_child(sol)

	var sag := _sutun(Ceviri.t("OYNANIŞ"))
	sag.add_child(_oran(Ceviri.t("Nişan"), "nisan_hassasiyet", Ceviri.t("yardım"), Ceviri.t("tam nişan")))
	sag.add_child(_secim(Ceviri.t("Hayalet"), "hayalet_kip",
		[Ceviri.t("Kapalı"), Ceviri.t("En iyi koşun"), Ceviri.t("Altın hayalet (bot)")]))
	sag.add_child(_anahtar(Ceviri.t("Ekran sarsıntısı"), "sarsinti"))
	sag.add_child(_anahtar(Ceviri.t("Rota ipucu (altından sonra)"), "rota_ipucu"))
	sag.add_child(_anahtar(Ceviri.t("Tek parmak şeması (dokunmatik)"), "dokunmatik"))
	sutunlar.add_child(sag)

	# Tus atama ayri bir kutuda; ayni kok icinde gorunurluk degistiriliyor.
	# Dokunmatikte HIC KURULMAZ: telefonda klavye yok, atanacak tus da yok.
	if Ayarlar.dokunmatik_mi():
		var d2 := _geri_dugmesi("GeriAyar", Ceviri.t("Geri"), geri)
		kutu.add_child(d2)
		return kok

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

	var alt := HBoxContainer.new()
	alt.alignment = BoxContainer.ALIGNMENT_CENTER
	alt.add_theme_constant_override("separation", 10)
	var t := Button.new()
	t.name = "TusAtama"
	t.text = Ceviri.t("Tuş atama")
	t.custom_minimum_size = Vector2(150, 28)
	t.pressed.connect(func() -> void:
		orta.visible = false
		tus_orta.visible = true
		tus_orta.find_child("GeriTus", true, false).grab_focus()
		Ses.cal("menu"))
	alt.add_child(t)
	var d := _geri_dugmesi("GeriAyar", Ayarlar.kisayol(Ceviri.t("Geri"), "Esc"), geri)
	d.theme_type_variation = &"Birincil"
	d.add_theme_font_size_override("font_size", 13)
	d.custom_minimum_size = Vector2(150, 28)
	alt.add_child(d)
	kutu.add_child(alt)
	return kok

static func _geri_dugmesi(ad: String, metin: String, geri: Callable) -> Button:
	var d := Button.new()
	d.name = ad
	d.text = metin
	d.custom_minimum_size = Vector2(0, 28)
	d.pressed.connect(geri)
	return d

## Ayarlar her acilista ana kutudan baslasin (tus atama acik kalmasin).
static func ana_kutuya_don(kok: Control) -> void:
	var tus := kok.find_child("TusKutusu", true, false)
	if tus != null:
		tus.visible = false
	var ana := kok.find_child("AnaKutu", true, false)
	if ana != null:
		ana.visible = true

static func _sutun(baslik: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(SUTUN_G, 0)
	v.add_theme_constant_override("separation", 4)
	v.add_child(Tema.etiket(baslik, 8, Tema.etiket_rengi(Tema.KAGIT)))
	return v

## Dil: etkin dilin adini gosteren dugme; basinca digerine gecer.
static func _dil(degisti: Callable) -> Control:
	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 8)
	var e := Tema.etiket(Ceviri.t("Dil"), 12, Tema.KAGIT, false)
	e.custom_minimum_size = Vector2(56, 0)
	satir.add_child(e)
	var d := Button.new()
	d.name = "Dil"
	d.text = "English" if Kayit.dil_etkin() == "tr" else "Türkçe"
	d.tooltip_text = "Türkçe / English"
	d.custom_minimum_size = Vector2(110, 24)
	d.pressed.connect(func() -> void:
		Kayit.ayar_yaz("dil", "en" if Kayit.dil_etkin() == "tr" else "tr")
		Ses.cal("menu")
		if degisti.is_valid():
			degisti.call())
	satir.add_child(d)
	return satir

## Tus atama kutusu: her eylem icin bir TusDugmesi + varsayilana don.
static func _tus_kutusu(geri: Callable) -> Control:
	var kutu := VBoxContainer.new()
	kutu.add_theme_constant_override("separation", 3)
	var baslik := Tema.etiket(Ceviri.t("TUŞ ATAMA"), 16, Tema.KAGIT, false, true)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(baslik)
	var not_e := Tema.etiket(Ceviri.t("Tuşa bas: değiştir · Esc: vazgeç"), 8, Tema.etiket_rengi(Tema.KAGIT))
	not_e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(not_e)

	var dugmeler: Array[TusDugmesi] = []
	for eylem: String in Tuslar.EYLEMLER:
		var satir := HBoxContainer.new()
		satir.add_theme_constant_override("separation", 8)
		var e := Tema.etiket(Ceviri.t(String(Tuslar.EYLEMLER[eylem])), 11, Tema.KAGIT, false)
		e.custom_minimum_size = Vector2(170, 0)
		satir.add_child(e)
		var d := TusDugmesi.yap(eylem)
		dugmeler.append(d)
		satir.add_child(d)
		kutu.add_child(satir)

	var alt := HBoxContainer.new()
	alt.alignment = BoxContainer.ALIGNMENT_CENTER
	alt.add_theme_constant_override("separation", 8)
	var sifirla := Button.new()
	sifirla.text = Ceviri.t("Varsayılana dön")
	sifirla.custom_minimum_size = Vector2(150, 26)
	sifirla.pressed.connect(func() -> void:
		Kayit.tuslari_sifirla()
		for d: TusDugmesi in dugmeler:
			d._yaz()
		Ses.cal("menu"))
	alt.add_child(sifirla)
	var g := Button.new()
	g.name = "GeriTus"
	g.text = Ceviri.t("Geri")
	g.custom_minimum_size = Vector2(120, 26)
	g.theme_type_variation = &"Birincil"
	g.add_theme_font_size_override("font_size", 12)
	g.pressed.connect(geri)
	alt.add_child(g)
	kutu.add_child(alt)
	return kutu

## Coktan secmeli ayar (deger = secenegin sirasi). Hayalet kaynagi icin:
## acik/kapali yetmiyor, ucuncu bir secenek var (botun altin kosusu).
static func _secim(baslik: String, ad: String, secenekler: Array) -> Control:
	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 8)
	var e := Tema.etiket(baslik, 12, Tema.KAGIT, false)
	e.custom_minimum_size = Vector2(56, 0)
	satir.add_child(e)
	var s := OptionButton.new()
	s.name = ad
	s.custom_minimum_size = Vector2(170, 24)
	for metin: String in secenekler:
		s.add_item(metin)
	s.selected = clampi(int(Kayit.ayar(ad)), 0, secenekler.size() - 1)
	s.item_selected.connect(func(i: int) -> void:
		Kayit.ayar_yaz(ad, i)
		Ses.cal("menu"))
	satir.add_child(s)
	return satir

## Etiketli oran kaydiraci (uclarinda ne anlama geldigi yazili).
static func _oran(baslik: String, ad: String, sol: String, sag: String) -> Control:
	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 8)
	var e := Tema.etiket(baslik, 12, Tema.KAGIT, false)
	e.custom_minimum_size = Vector2(56, 0)
	satir.add_child(e)
	var k := HSlider.new()
	k.custom_minimum_size = Vector2(100, 20)
	k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	k.min_value = 0.0
	k.max_value = 1.0
	k.step = 0.05
	k.value = float(Kayit.ayar(ad))
	var not_metni := Tema.etiket("", 8, Tema.etiket_rengi(Tema.KAGIT))
	not_metni.custom_minimum_size = Vector2(60, 0)
	k.value_changed.connect(func(v: float) -> void:
		Kayit.ayar_yaz(ad, v)
		not_metni.text = sol if v < 0.34 else (sag if v > 0.66 else Ceviri.t("orta"))
		Ses.cal("menu"))
	satir.add_child(k)
	not_metni.text = sol if k.value < 0.34 else (sag if k.value > 0.66 else Ceviri.t("orta"))
	satir.add_child(not_metni)
	return satir

## Ses kaydiraci + ac/kapa dugmesi tek satirda.
static func _kaydirac(baslik: String, oran_ad: String, acik_ad: String) -> Control:
	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 8)
	var e := Tema.etiket(baslik, 12, Tema.KAGIT, false)
	e.custom_minimum_size = Vector2(56, 0)
	satir.add_child(e)

	var yuzde := Tema.etiket("", 8, Tema.etiket_rengi(Tema.KAGIT))
	yuzde.custom_minimum_size = Vector2(28, 0)

	var k := HSlider.new()
	k.custom_minimum_size = Vector2(100, 20)
	k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	c.button_pressed = bool(Kayit.ayar(ad))
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.toggled.connect(func(v: bool) -> void:
		Kayit.ayar_yaz(ad, v)
		Ses.cal("menu"))
	return c
