extends Node2D
## Gorsel dogrulama + yayin gorselleri. Headless DEGIL calistirilir:
##   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --path . --scene res://tests/ekran.tscn -- [ek_klasor]
##
## Cikti (pencere 1280x720, taban cozunurluk 640x360 -> yakalanan goruntu 1280x720):
##   docs/ekran/*.png      1280x720 - README ve gozle kontrol icin
##   yayin/ekran_N.png     1280x720 - itch.io sayfasi (4 adet)
##   yayin/kapak.png       630x500  - itch.io kapagi (arayuzsuz oyun goruntusu + baslik)
##   <ek_klasor>/*.png     ayni kareler (varsa), kanit klasoru icin
##
## Oyuncunun kaydina (user://kayit.cfg) YAZMAZ: Kayit.salt_okunur; sahte ilerleme
## yalniz bellekte. Oyuncu her karede bir kanca noktasina baglanir ki halat ve
## sallanma pozu da goruntude olsun.

const KAPAK_BOLUM := 13
const KAPAK_ALANI := Rect2i(0, 0, 630, 500)

var _ek := ""


func _ready() -> void:
	Kayit.salt_okunur = true   # arac oyuncunun kaydina yazmasin
	var arg := OS.get_cmdline_user_args()
	if arg.size() > 0:
		_ek = arg[0]
		DirAccess.make_dir_recursive_absolute(_ek)
	_cek()


func _sahte_ilerleme() -> void:
	## Bellekte: acik bolum, sureler (karisik madalyalar), akis rekorlari.
	Kayit._cfg.set_value("ilerleme", "acik", Bolumler.sayi())
	for no in range(1, Bolumler.sayi() + 1):
		var e := Bolumler.madalya_esikleri(no)
		var oran: float = [0.96, 0.98, 1.06, 1.3][no % 4]
		Kayit._cfg.set_value("sureler", str(no), float(e[0]) * oran if no % 4 != 3 else float(e[1]) * 0.97)
		Kayit._cfg.set_value("akis", str(no), 2 + (no * 5) % 9)


func _dil(kod: String) -> void:
	Kayit.ayar_yaz("dil", kod)


func _cek() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/ekran"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://yayin"))
	_sahte_ilerleme()

	_dil("tr")
	await _menu_cek("tr")
	_dil("en")
	await _menu_cek("en")
	_dil("tr")

	# Oyun ici: her iki tema, halat, ruzgar alani.
	var yayin_sira := 1
	for no: int in [1, 6, 9, 13]:
		var im := await _bolum_cek(no)
		_yaz(im, "res://docs/ekran/bolum_%02d.png" % no)
		_yaz(im, "res://yayin/ekran_%d.png" % yayin_sira)
		yayin_sira += 1
	for no: int in [3, 10, 14]:
		_yaz(await _bolum_cek(no), "res://docs/ekran/bolum_%02d.png" % no)

	_yaz(await _nisan_cek(6), "res://docs/ekran/nisan.png")
	_yaz(await _ilk_oyun_cek(), "res://docs/ekran/ilk_oyun.png")

	# Duraklat ve bolum sonu, iki dilde.
	for kod in ["tr", "en"]:
		_dil(kod)
		_yaz(await _duraklat_cek(), "res://docs/ekran/duraklat_%s.png" % kod)
		_yaz(await _bitis_cek(false, 0.0), "res://docs/ekran/bitis_%s.png" % kod)
	_dil("tr")
	_yaz(await _bitis_cek(false, 9.0), "res://docs/ekran/bitis_gumus.png")
	_yaz(await _gunluk_cek(), "res://docs/ekran/gunluk.png")
	_yaz(await _hud_cek(false), "res://docs/ekran/hud.png")
	_yaz(await _hud_cek(true), "res://docs/ekran/hud_dokunmatik.png")
	_yaz(await _yeniden_dugmesi_cek(), "res://docs/ekran/yeniden_dokunmatik.png")
	_yaz(await _telefon_cek(), "res://docs/ekran/telefon.png")
	_yaz(await _secim_cek(true), "res://docs/ekran/bolum_sec_dokunmatik.png")
	_yaz(await _bitis_cek(true, 0.0), "res://docs/ekran/bitis_dokunmatik.png")

	await _kapak_yap()
	print("Ekran goruntuleri hazir: docs/ekran/ ve yayin/")
	get_tree().quit()


# --- Yakalama ---------------------------------------------------------

func _bekle(sn: float) -> void:
	await get_tree().create_timer(sn).timeout


## arayuz=false: sure/ipucu gibi arayuz katmani gizlenir (kapak icin).
func _bolum_cek(no: int, arayuz := true) -> Image:
	var bolum: Bolum = load(Bolumler.yol(no)).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().process_frame
	if not arayuz:
		var k: CanvasLayer = bolum.find_child("Arayuz", true, false)
		if k != null:
			k.visible = false
	_sallandir(bolum, no)
	for i in 28:
		await get_tree().process_frame
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	return im


## Oyuncuyu bir kanca noktasinin altina koyup savurur; halat gorunur olur.
func _sallandir(bolum: Bolum, no: int) -> void:
	var oyuncu: Oyuncu = bolum.find_child("Oyuncu", true, false)
	var noktalar := Bolumler.tum_kanca(no)
	if oyuncu == null or noktalar.size() < 2:
		return
	var hedef: Vector2 = noktalar[1]
	oyuncu.global_position = hedef + Vector2(-70.0, 110.0)
	oyuncu.velocity = Vector2(360.0, -60.0)
	oyuncu.kanca_at_hemen((hedef - oyuncu.global_position).normalized())


## Kanca atmadan, aday nokta secili haldeyken goruntu: kesik nisan cizgisi,
## menzil disi noktalarin soluk hali ve "AKIS xN" sayaci gorunur.
func _nisan_cek(no: int) -> Image:
	var bolum: Bolum = load(Bolumler.yol(no)).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().physics_frame
	var oyuncu: Oyuncu = bolum.find_child("Oyuncu", true, false)
	var noktalar := Bolumler.tum_kanca(no)
	if oyuncu != null and noktalar.size() >= 2:
		var hedef: Vector2 = noktalar[1]
		oyuncu.global_position = hedef + Vector2(-110.0, 120.0)
		oyuncu.velocity = Vector2(280.0, -90.0)
	bolum.set("_zincir", 4)
	bolum.call("_akis_yaz")
	for i in 6:
		await get_tree().physics_frame
	await get_tree().process_frame
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	return im


## Ilk oyun: hic bitirilmemis 1. bolum, ipucu gorunur.
func _ilk_oyun_cek() -> Image:
	var eski: Variant = Kayit._cfg.get_value("sureler", "1", 0.0)
	Kayit._cfg.set_value("sureler", "1", 0.0)
	var bolum: Bolum = load(Bolumler.yol(1)).instantiate()
	add_child(bolum)
	for i in 30:
		await get_tree().process_frame
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	Kayit._cfg.set_value("sureler", "1", eski)
	return im


## HUD dogrulamasi: dokunmatik=true tek parmak metinlerini ve Duraklat dugmesini gosterir.
func _hud_cek(dokunmatik: bool) -> Image:
	Ayarlar.dokunmatik_zorla = 1 if dokunmatik else 0
	var bolum: Bolum = load(Bolumler.yol(1)).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().physics_frame
	var oyuncu: Oyuncu = bolum.find_child("Oyuncu", true, false)
	if oyuncu != null:
		oyuncu.global_position = Vector2(330, 212)
		oyuncu.velocity = Vector2(120.0, 0.0)
	bolum.set("_zincir", 3)
	bolum.call("_akis_yaz")
	for i in 6:
		await get_tree().physics_frame
	await get_tree().process_frame
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	Ayarlar.dokunmatik_zorla = -1
	return im


## Gunluk meydan okuma: HUD'da "GUNLUK · <degistirici>" gorunmeli.
func _gunluk_cek() -> Image:
	Gunluk.tohum_zorla = 20260916
	Gunluk.aktif = true
	var bolum: Bolum = load(Bolumler.yol(Gunluk.bolum_no())).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().process_frame
	_sallandir(bolum, Gunluk.bolum_no())
	for i in 24:
		await get_tree().process_frame
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	Gunluk.aktif = false
	Gunluk.tohum_zorla = 0
	return im


## Dokunmatikte olumden sonra beliren tek dokunusluk "Bastan basla" dugmesi.
func _yeniden_dugmesi_cek() -> Image:
	Ayarlar.dokunmatik_zorla = 1
	var bolum: Bolum = load(Bolumler.yol(1)).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().physics_frame
	bolum.call("_oldu")
	bolum.set("_yeniden_sayac", Bolum.YENIDEN_GORUNME - Bolum.YENIDEN_BEKLEME - 0.01)
	bolum.call("_yeniden_dugmesini_guncelle")
	for i in 4:
		await get_tree().process_frame
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	Ayarlar.dokunmatik_zorla = -1
	return im


## Telefon orani (915x412, yatay): stretch aspect=keep, yanlara siyah bant.
func _telefon_cek() -> Image:
	Ayarlar.dokunmatik_zorla = 1
	var eski := DisplayServer.window_get_size()
	DisplayServer.window_set_size(Vector2i(915, 412))
	for i in 4:
		await get_tree().process_frame
	var bolum: Bolum = load(Bolumler.yol(6)).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().process_frame
	_sallandir(bolum, 6)
	for i in 24:
		await get_tree().process_frame
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	DisplayServer.window_set_size(eski)
	for i in 3:
		await get_tree().process_frame
	Ayarlar.dokunmatik_zorla = -1
	return im


func _menu_cek(dil: String) -> void:
	# Control'un capalari, ust ogesi Node2D olursa sifir dikdortgene cozulur.
	# Oyunda menu sahne kokudur; burada ayni kosulu CanvasLayer ile taklit ediyoruz.
	var katman := CanvasLayer.new()
	add_child(katman)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	katman.add_child(menu)
	await _bekle(0.9)
	_yaz(await _goruntu(), "res://docs/ekran/menu_%s.png" % dil)
	menu.call("_secim_goster")
	await _bekle(0.7)
	_yaz(await _goruntu(), "res://docs/ekran/bolum_sec_%s.png" % dil)
	menu.call("_ayar_goster")
	await _bekle(0.7)
	_yaz(await _goruntu(), "res://docs/ekran/ayarlar_%s.png" % dil)
	if dil == "tr":
		var tus_dugmesi: Button = menu.find_child("TusAtama", true, false)
		if tus_dugmesi != null:
			tus_dugmesi.emit_signal("pressed")
			await _bekle(0.3)
			_yaz(await _goruntu(), "res://docs/ekran/tus_atama.png")
	katman.free()
	await get_tree().process_frame


## Bolum secme ekrani dokunmatikte (tus eksiz "Geri").
func _secim_cek(dokunmatik: bool) -> Image:
	Ayarlar.dokunmatik_zorla = 1 if dokunmatik else 0
	var katman := CanvasLayer.new()
	add_child(katman)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	katman.add_child(menu)
	for i in 6:
		await get_tree().process_frame
	menu.call("_secim_goster")
	await _bekle(0.7)
	var im := await _goruntu()
	katman.free()
	await get_tree().process_frame
	Ayarlar.dokunmatik_zorla = -1
	return im


func _duraklat_cek() -> Image:
	var bolum: Bolum = load(Bolumler.yol(1)).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().process_frame
	_sallandir(bolum, 1)
	for i in 10:
		await get_tree().process_frame
	bolum.call("_duraklat_degistir")
	await _bekle(0.5)
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	return im


## Bolum sonu karti: gercek akisla (rekor + madalya). sure > 0 verilirse o sure
## bitis suresi olur (madalya secimi icin), 0 ise altin esiginin biraz altinda.
func _bitis_cek(dokunmatik: bool, sure: float) -> Image:
	Ayarlar.dokunmatik_zorla = 1 if dokunmatik else 0
	var eski: Variant = Kayit._cfg.get_value("sureler", "1", 0.0)
	Kayit._cfg.set_value("sureler", "1", 30.0)
	var bolum: Bolum = load(Bolumler.yol(1)).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().physics_frame
	var oyuncu: Oyuncu = bolum.find_child("Oyuncu", true, false)
	var altin: float = Bolumler.madalya_esikleri(1)[0]
	bolum.set("_sure", sure if sure > 0.0 else altin - 0.7)
	bolum.set("_en_uzun_zincir", 5)
	bolum.call("_bitise_degdi", oyuncu)
	await _bekle(0.6)
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	Kayit._cfg.set_value("sureler", "1", eski)
	Ayarlar.dokunmatik_zorla = -1
	return im


func _goruntu() -> Image:
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


# --- Kapak ------------------------------------------------------------

## 630x500 itch.io kapagi: oyun goruntusunden kirpilmis kare + altta "KANCA." basligi.
func _kapak_yap() -> void:
	var bolum: Bolum = load(Bolumler.yol(KAPAK_BOLUM)).instantiate()
	add_child(bolum)
	for i in 12:
		await get_tree().process_frame
	var k: CanvasLayer = bolum.find_child("Arayuz", true, false)
	if k != null:
		k.visible = false
	_sallandir(bolum, KAPAK_BOLUM)
	# Baslik: oyuncu katmaninin ustunde, kameradan bagimsiz.
	var katman := CanvasLayer.new()
	katman.layer = 50
	bolum.add_child(katman)
	var band := ColorRect.new()
	band.color = Color(Tema.zemin(), 0.9)
	band.position = Vector2(0, 280)
	band.size = Vector2(640, 80)
	katman.add_child(band)
	var baslik := HBoxContainer.new()
	baslik.position = Vector2(0, 288)
	baslik.size = Vector2(640, 64)
	baslik.alignment = BoxContainer.ALIGNMENT_CENTER
	baslik.add_theme_constant_override("separation", 0)
	var b1 := Label.new()
	b1.text = "KANCA"
	b1.theme_type_variation = &"Baslik"
	b1.add_theme_font_size_override("font_size", 52)
	b1.add_theme_color_override("font_color", Tema.blok())
	var b2 := Label.new()
	b2.text = "."
	b2.theme_type_variation = &"Baslik"
	b2.add_theme_font_size_override("font_size", 52)
	b2.add_theme_color_override("font_color", Tema.TURUNCU)
	baslik.add_child(b1)
	baslik.add_child(b2)
	katman.add_child(baslik)
	for i in 28:
		await get_tree().process_frame
	var im := await _goruntu()
	bolum.free()
	await get_tree().process_frame
	# 1280x720 -> yuksekligi 500 yap, ortadan 630 genislik kirp.
	var olcek := 500.0 / float(im.get_height())
	var genis := int(round(float(im.get_width()) * olcek))
	im.resize(genis, 500, Image.INTERPOLATE_BILINEAR)
	var kapak := Image.create(630, 500, false, Image.FORMAT_RGBA8)
	kapak.blit_rect(im, Rect2i(maxi((genis - 630) / 2, 0), 0, 630, 500), Vector2i.ZERO)
	_yaz(kapak, "res://yayin/kapak.png")


# --- Yardimcilar ------------------------------------------------------

func _yaz(im: Image, yol: String) -> void:
	var hata := im.save_png(yol)
	if hata != OK:
		printerr("PNG yazilamadi: %s (%d)" % [yol, hata])
		return
	print("  %s  %dx%d" % [yol, im.get_width(), im.get_height()])
	if _ek != "" and yol.begins_with("res://docs/ekran/"):
		im.save_png("%s/%s" % [_ek, yol.get_file()])
