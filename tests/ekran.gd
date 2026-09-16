extends Node2D
## Gorsel dogrulama + yayin gorselleri. Headless DEGIL calistirilir:
##   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --path . --scene res://tests/ekran.tscn
##
## Cikti (pencere 1280x720, taban cozunurluk 640x360 -> yakalanan goruntu 1280x720):
##   docs/ekran/*.png      1280x720 - README ve gozle kontrol icin
##   yayin/ekran_N.png     1280x720 - itch.io sayfasi (4 adet)
##   yayin/kapak.png       630x500  - itch.io kapagi (arayuzsuz oyun goruntusu + logo)
##
## Oyuncu her karede bir kanca noktasina baglanir ki halat ve sallanma pozu da
## goruntude olsun.

const BOLUMLER := [1, 6, 9, 13]          ## yayin gorsellerine giren bolumler
const EK_BOLUMLER := [3, 10, 14]         ## sadece docs/ekran altina
const KAPAK_BOLUM := 13

func _ready() -> void:
	_cek()

func _cek() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/ekran"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://yayin"))

	await _menu_cek()

	# Pencere 1280x720, taban cozunurluk 640x360: yakalanan goruntu zaten
	# 1280x720 ve pixel art 2x buyutulmus halde render ediliyor. Ayrica
	# buyutmek gerekmiyor (ilk denemede 2560x1440 cikmisti).
	var yayin_sira := 1
	for no: int in BOLUMLER:
		var im := await _bolum_cek(no)
		_yaz(im, "res://docs/ekran/bolum_%02d.png" % no)
		_yaz(im, "res://yayin/ekran_%d.png" % yayin_sira)
		yayin_sira += 1
	for no: int in EK_BOLUMLER:
		var im := await _bolum_cek(no)
		_yaz(im, "res://docs/ekran/bolum_%02d.png" % no)

	await _kapak_yap()
	print("Ekran goruntuleri hazir: docs/ekran/ ve yayin/")
	get_tree().quit()

# --- Yakalama ---------------------------------------------------------

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
	if no == BOLUMLER[0]:
		bolum.call("_duraklat_degistir")
		for i in 6:
			await get_tree().process_frame
		_yaz(await _goruntu(), "res://docs/ekran/duraklat.png")
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

func _menu_cek() -> void:
	# Control'un capalari, ust ogesi Node2D olursa sifir dikdortgene cozulur.
	# Oyunda menu sahne kokudur; burada ayni kosulu CanvasLayer ile taklit ediyoruz.
	var katman := CanvasLayer.new()
	add_child(katman)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	katman.add_child(menu)
	for i in 12:
		await get_tree().process_frame
	_yaz(await _goruntu(), "res://docs/ekran/menu.png")
	menu.call("_secim_goster")
	for i in 6:
		await get_tree().process_frame
	_yaz(await _goruntu(), "res://docs/ekran/bolum_sec.png")
	menu.call("_ayar_goster")
	for i in 6:
		await get_tree().process_frame
	_yaz(await _goruntu(), "res://docs/ekran/ayarlar.png")
	katman.free()
	await get_tree().process_frame

func _goruntu() -> Image:
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

# --- Kapak ------------------------------------------------------------

## 630x500 itch.io kapagi: oyun goruntusunden kirpilmis kare + altta logo bandi.
func _kapak_yap() -> void:
	var im := await _bolum_cek(KAPAK_BOLUM, false)
	# 640x360 -> yuksekligi 500 yapacak sekilde buyut, ortadan 630 genislik kirp.
	var olcek := 500.0 / float(im.get_height())
	var genis := int(round(float(im.get_width()) * olcek))
	im.resize(genis, 500, Image.INTERPOLATE_NEAREST)
	var kapak := Image.create(630, 500, false, Image.FORMAT_RGBA8)
	kapak.blit_rect(im, Rect2i(maxi((genis - 630) / 2, 0), 0, 630, 500), Vector2i.ZERO)

	# Alt bant: logonun okunmasi icin karartma.
	for y in range(320, 500):
		var t := clampf(float(y - 320) / 120.0, 0.0, 1.0)
		for x in 630:
			var c := kapak.get_pixel(x, y)
			kapak.set_pixel(x, y, c.lerp(Palet.GOK_DIP, t * 0.82))

	var logo := load("res://assets/sprites/logo.png").get_image() as Image
	logo.convert(Image.FORMAT_RGBA8)
	var lo := 5
	logo.resize(logo.get_width() * lo, logo.get_height() * lo, Image.INTERPOLATE_NEAREST)
	if logo.get_width() > 600:
		lo = 4
		logo = (load("res://assets/sprites/logo.png").get_image() as Image)
		logo.convert(Image.FORMAT_RGBA8)
		logo.resize(logo.get_width() * lo, logo.get_height() * lo, Image.INTERPOLATE_NEAREST)
	kapak.blend_rect(logo, Rect2i(Vector2i.ZERO, logo.get_size()),
		Vector2i((630 - logo.get_width()) / 2, 395 - logo.get_height() / 2))
	_yaz(kapak, "res://yayin/kapak.png")

# --- Yardimcilar ------------------------------------------------------

func _yaz(im: Image, yol: String) -> void:
	var hata := im.save_png(yol)
	if hata != OK:
		printerr("PNG yazilamadi: %s (%d)" % [yol, hata])
	else:
		print("  %s  %dx%d" % [yol, im.get_width(), im.get_height()])
