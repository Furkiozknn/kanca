extends Control
## Ana menu + bolum secme + ayarlar (ucu ayni sahnede, panel degistirerek).
## Dunya: lacivert zemin, videodaki sarkac (tavan rayi, beyaz capa, turkuaz top,
## turuncu iz) ve tek turuncu vurgu. Basta yalniz buyuk OYNA ve tek satir nasil
## oynanir; geri kalani ikincil.

var _ana: Control
var _secim: Control
var _ayar: Control
var _yardim: Label
var _sifirla_dugme: Button
var _sifirla_sayac := 0.0
var _arka: Node2D


func _ready() -> void:
	# Menuye donen her yol gunluk kipi kapatmali; burada da temizleniyor ki
	# "Oyna" hicbir kosulda gunluk degistiricisiyle acilmasin.
	Gunluk.aktif = false
	Tema.aktif = 0
	RenderingServer.set_default_clear_color(Tema.zemin())
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
	UI.dugmeleri_bagla(self)
	_ana.find_child("Basla", true, false).grab_focus()
	_ana_gir()
	Ses.muzik_cal("muzik_menu")


func _unhandled_input(olay: InputEvent) -> void:
	if olay.is_action_pressed("duraklat") and (_secim.visible or _ayar.visible):
		_ana_goster()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_arka.visible = _ana.visible
	if _sifirla_sayac > 0.0:
		_sifirla_sayac -= delta
		if _sifirla_sayac <= 0.0 and _sifirla_dugme != null:
			_sifirla_dugme.text = tr("Kayıtları sıfırla")


# --- Arka plan --------------------------------------------------------

func _arka_plan() -> void:
	_arka = Sarkac.new()
	add_child(_arka)


# --- Paneller ---------------------------------------------------------

func _kutu_panel() -> Array:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)
	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 8)
	orta.add_child(kutu)
	return [kok, kutu]


func _ana_panel() -> Control:
	var p := _kutu_panel()
	var kok: Control = p[0]
	var kutu: VBoxContainer = p[1]

	# Koseler: sol ustte mono etiket, sag ustte dil dugmesi.
	var sol_ust := Tema.etiket(tr("HIZ · %d BÖLÜM") % Bolumler.sayi(), 8, Tema.etiket_rengi(Tema.KAGIT))
	sol_ust.position = Vector2(16, 14)
	kok.add_child(sol_ust)
	var dil := Button.new()
	dil.name = "DilDugme"
	dil.text = "EN" if Kayit.dil_etkin() == "tr" else "TR"
	dil.tooltip_text = "Türkçe / English"
	dil.custom_minimum_size = Vector2(38, 22)
	dil.add_theme_font_size_override("font_size", 10)
	dil.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dil.offset_left = -54.0
	dil.offset_right = -16.0
	dil.offset_top = 10.0
	dil.offset_bottom = 32.0
	dil.pressed.connect(_dil_degistir)
	kok.add_child(dil)

	# Baslik: KANCA + turuncu nokta (videonun kapanis karesi).
	var baslik := HBoxContainer.new()
	baslik.alignment = BoxContainer.ALIGNMENT_CENTER
	baslik.add_theme_constant_override("separation", 0)
	var b1 := Label.new()
	b1.text = "KANCA"
	b1.theme_type_variation = &"Baslik"
	b1.add_theme_font_size_override("font_size", 52)
	var b2 := Label.new()
	b2.text = "."
	b2.theme_type_variation = &"Baslik"
	b2.add_theme_font_size_override("font_size", 52)
	b2.add_theme_color_override("font_color", Tema.TURUNCU)
	baslik.add_child(b1)
	baslik.add_child(b2)
	kutu.add_child(baslik)

	_yardim = Tema.etiket(yardim_metni(), 8, Tema.etiket_rengi(Tema.KAGIT))
	_yardim.name = "Yardim"
	_yardim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(_yardim)
	kutu.add_child(_bosluk(6))

	var oyna := _dugme("Basla", tr("Oyna"), _basla, true)
	oyna.custom_minimum_size = Vector2(300, 38)
	oyna.add_theme_font_size_override("font_size", 22)
	kutu.add_child(oyna)

	var satir := HBoxContainer.new()
	satir.alignment = BoxContainer.ALIGNMENT_CENTER
	satir.add_theme_constant_override("separation", 6)
	satir.add_child(_dugme("Sec", tr("Bölüm Seç"), _secim_goster))
	satir.add_child(_dugme("Gunluk", tr("Günün Bölümü"), _gunluge_git))
	satir.add_child(_dugme("Ayar", tr("Ayarlar"), _ayar_goster))
	# Tarayicida quit() islevsiz; sekmeyi kapatmak kullanicinin isi.
	if not OS.has_feature("web"):
		satir.add_child(_dugme("Cikis", tr("Çıkış"), _cikis))
	kutu.add_child(satir)
	kutu.add_child(_bosluk(8))

	# Alt bilgi: siradaki bolum, gunun bolumu, ilerleme (hepsi kayittan).
	var acik := Kayit.acik_bolum()
	var siradaki := Tema.etiket(tr("SIRADAKİ: %s") % Tema.kisa_baslik(acik, Bolumler.ad(acik)),
		8, Tema.etiket_rengi(Tema.KAGIT))
	siradaki.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(siradaki)
	var gunluk := Tema.etiket(_gunluk_metni(), 8, Tema.etiket_rengi(Tema.KAGIT))
	gunluk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(gunluk)
	var ilerleme := Tema.etiket(_ilerleme_metni(), 8, Tema.etiket_rengi(Tema.KAGIT))
	ilerleme.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(ilerleme)
	return kok


## Kontrol yardimi girdi semasina gore. Tek satir; masaustu metni fare ve
## klavyeyi, dokunmatik metni parmagi anlatir.
static func yardim_metni() -> String:
	if Ayarlar.dokunmatik_mi():
		return Ceviri.t("Dokun: nişan al ve kanca tak · Parmağı kaldır: bırak · Basılıyken kaydır: halat")
	return Ceviri.t("Fare: nişan · Sol tık basılı: kanca · A/D: salın · W/S: halat · Boşluk: zıpla")


static func _ilerleme_metni() -> String:
	var madalya := 0
	var altin := 0
	for no in range(1, Bolumler.sayi() + 1):
		var m := Bolumler.madalya(no, Kayit.en_iyi(no))
		if m < 3:
			madalya += 1
		if m == 0:
			altin += 1
	return Ceviri.t("AÇIK BÖLÜM %d / %d · MADALYA %d · ALTIN %d") % [
		Kayit.acik_bolum(), Bolumler.sayi(), madalya, altin]


## Gunun meydan okumasi: bolum + degistirici + bugunku en iyi sure.
static func _gunluk_metni() -> String:
	var sure := Kayit.gunluk_en_iyi(Gunluk.tohum())
	return Ceviri.t("GÜNÜN BÖLÜMÜ: %s · EN İYİ %s") % [
		Gunluk.baslik(), Bolum._bicim(sure) if sure > 0.0 else "—"]


func _secim_paneli() -> Control:
	var p := _kutu_panel()
	var kok: Control = p[0]
	var kutu: VBoxContainer = p[1]
	kutu.add_theme_constant_override("separation", 6)

	var baslik := Tema.etiket(tr("BÖLÜM SEÇ"), 16, Tema.KAGIT, false, true)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(baslik)

	var izgara := GridContainer.new()
	izgara.columns = 5
	izgara.add_theme_constant_override("h_separation", 5)
	izgara.add_theme_constant_override("v_separation", 5)
	kutu.add_child(izgara)

	var acik := Kayit.acik_bolum()
	for no in range(1, Bolumler.sayi() + 1):
		izgara.add_child(_bolum_dugmesi(no, no <= acik))

	var not_e := Tema.etiket(tr("Madalya: altın / gümüş / bronz süreler bölüm içinde yazılı · AKIŞ ×N: yere değmeden en uzun kanca zinciri"),
		8, Tema.etiket_rengi(Tema.KAGIT))
	not_e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	not_e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	not_e.custom_minimum_size = Vector2(560, 0)
	kutu.add_child(not_e)

	var alt := HBoxContainer.new()
	alt.alignment = BoxContainer.ALIGNMENT_CENTER
	alt.add_theme_constant_override("separation", 8)
	var geri := _dugme("Geri", Ayarlar.kisayol(tr("Geri"), "Esc"), _ana_goster, true)
	geri.custom_minimum_size = Vector2(150, 28)
	geri.add_theme_font_size_override("font_size", 13)
	alt.add_child(geri)
	_sifirla_dugme = _dugme("Sifirla", tr("Kayıtları sıfırla"), _sifirla)
	_sifirla_dugme.custom_minimum_size = Vector2(150, 28)
	alt.add_child(_sifirla_dugme)
	kutu.add_child(alt)
	return kok


## Bolum dugmesi: numara, ad, en iyi sure ve kazanilan madalya.
func _bolum_dugmesi(no: int, acik: bool) -> Control:
	var d := Button.new()
	d.theme_type_variation = &"Kucuk"
	d.custom_minimum_size = Vector2(112, 44)
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
	# Akis rekoru (v0.5): sag alt kosede "×N". Madalya simgesiyle ayni
	# koseye koymamak icin altta; ikiden kisa zincir gosterilmez (HUD da oyle).
	var zincir := Kayit.akis(no)
	if zincir >= 2:
		var a := Tema.etiket("×%d" % zincir, 8, Tema.TURUNCU, true, true)
		a.name = "Akis"
		a.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		a.offset_left = -30.0
		a.offset_top = -14.0
		a.offset_right = -4.0
		a.offset_bottom = -2.0
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		d.add_child(a)
	return d


func _ayar_paneli() -> Control:
	return AyarPanel.yap(_ana_goster, false, _dil_yenile)


# --- Islevler ---------------------------------------------------------

func _basla() -> void:
	_bolume_git(Kayit.acik_bolum())


func _gunluge_git() -> void:
	Gunluk.aktif = true
	Ses.cal("menu")
	Gecis.git(Bolumler.yol(Gunluk.bolum_no()))


func _bolume_git(no: int) -> void:
	Ses.cal("menu")
	Gecis.git(Bolumler.yol(no))


func _secim_goster() -> void:
	Ses.cal("menu")
	_ana.visible = false
	_ayar.visible = false
	_secim.visible = true
	_sifirla_iptal()
	_secim.find_child("Geri", true, false).grab_focus()
	UI.sirayla_gir(_secim.find_child("Kutu", true, false).get_children())


func _ayar_goster() -> void:
	Ses.cal("menu")
	_ana.visible = false
	_secim.visible = false
	AyarPanel.ana_kutuya_don(_ayar)
	_ayar.visible = true
	_ayar.find_child("GeriAyar", true, false).grab_focus()
	UI.sirayla_gir(_ayar.find_child("Kutu", true, false).get_children())


func _ana_goster() -> void:
	Ses.cal("menu")
	_secim.visible = false
	_ayar.visible = false
	_ana.visible = true
	# Ayarlardan tek parmak semasi degistirilmis olabilir.
	_yardim.text = yardim_metni()
	_ana.find_child("Basla", true, false).grab_focus()
	_ana_gir()


func _ana_gir() -> void:
	UI.sirayla_gir(_ana.find_child("Kutu", true, false).get_children())


## Kayit sifirlama iki adimli: ilk dokunus sorar, 3 sn icinde ikincisi siler.
## (v0.7: tek dokunusla butun ilerleme siliniyordu - denetim bulgusu.)
func _sifirla() -> void:
	if _sifirla_sayac > 0.0:
		Kayit.sifirla()
		get_tree().reload_current_scene()
		return
	_sifirla_sayac = 3.0
	_sifirla_dugme.text = tr("Emin misin? Tekrar dokun")
	Ses.cal("menu")


func _sifirla_iptal() -> void:
	_sifirla_sayac = 0.0
	if _sifirla_dugme != null:
		_sifirla_dugme.text = tr("Kayıtları sıfırla")


func _dil_degistir() -> void:
	Kayit.ayar_yaz("dil", "en" if Kayit.dil_etkin() == "tr" else "tr")
	Ses.cal("menu")
	get_tree().reload_current_scene()


## Ayarlar'daki dil dugmesi: menuyu yeni dilde yeniden kur, ayarlar acik kalsin.
func _dil_yenile() -> void:
	get_tree().reload_current_scene.call_deferred()


func _cikis() -> void:
	get_tree().quit()


# --- Yardimcilar ------------------------------------------------------

func _dugme(ad: String, metin: String, islev: Callable, birincil := false) -> Button:
	var d := Button.new()
	d.name = ad
	d.text = metin
	d.add_theme_font_size_override("font_size", 12)
	if birincil:
		d.theme_type_variation = &"Birincil"
	d.pressed.connect(islev)
	return d


func _bosluk(yukseklik: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, yukseklik)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Menu arka plani: tavan rayi (kesik cizgi), beyaz capa, turkuaz top, turuncu
## iz. Videodaki "01 / SALLAN" sahnesinin canli hali; her karede yeniden cizilir
## (birkac daire: Intel UHD icin ihmal edilebilir).
class Sarkac extends Node2D:
	const RAY_Y := 44.0
	const CAPA := Vector2(44.0, 44.0)
	const BOY := 110.0
	const GENLIK := 0.5
	const HIZ := 1.9                 ## rad/sn (yaklasik 3,3 sn periyot)
	var _t := 0.0
	var _iz: Array[Vector2] = []
	var _iz_sayac := 0.0

	func _process(delta: float) -> void:
		_t += delta
		_iz_sayac += delta
		if _iz_sayac >= 0.03:
			_iz_sayac = 0.0
			_iz.append(_top())
			if _iz.size() > 16:
				_iz.remove_at(0)
		queue_redraw()

	func _top() -> Vector2:
		var a := GENLIK * sin(_t * HIZ)
		return CAPA + Vector2(sin(a), cos(a)) * BOY

	func _draw() -> void:
		var boy := get_viewport_rect().size.x
		var x := 0.0
		while x < boy:
			draw_rect(Rect2(x, RAY_Y - 1.0, 14.0, 2.0), Color(Tema.KESIK, 0.75))
			x += 24.0
		var top := _top()
		for i in _iz.size():
			var k := float(i + 1) / float(_iz.size())
			draw_circle(_iz[i], 1.0 + 3.0 * k, Color(Tema.TURUNCU, 0.75 * k), true, -1.0, true)
		draw_line(CAPA, top, Color(Tema.KAGIT, 0.9), 1.0, true)
		draw_circle(CAPA, 3.0, Tema.KAGIT, true, -1.0, true)
		draw_circle(top, 8.0, Tema.TURKUAZ, true, -1.0, true)
