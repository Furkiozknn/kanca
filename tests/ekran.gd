extends Node2D
## Gorsel dogrulama araci: secili bolumleri kisa sure calistirip
## docs/ekran/ altina PNG yazar. Headless DEGIL calistirilir:
##   godot --path . --scene res://tests/ekran.tscn
## Oyuncu her karede bir kanca noktasina baglanir ki halat da goruntude olsun.

const BOLUMLER := [1, 3, 6, 8]

func _ready() -> void:
	_cek()

func _cek() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/ekran")
	await _menu_cek()
	for no: int in BOLUMLER:
		var bolum: Bolum = load(Bolumler.yol(no)).instantiate()
		add_child(bolum)
		for i in 10:
			await get_tree().process_frame
		_sallandir(bolum, no)
		for i in 25:
			await get_tree().process_frame
		await _kaydet("bolum_%02d" % no)
		if no == BOLUMLER[0]:
			bolum.call("_duraklat_degistir")
			for i in 5:
				await get_tree().process_frame
			await _kaydet("duraklat")
		bolum.free()
		await get_tree().process_frame
	print("Ekran goruntuleri: res://docs/ekran/")
	get_tree().quit()

## Oyuncuyu ikinci kanca noktasinin altina koyup savurur; halat gorunur olur.
func _sallandir(bolum: Bolum, no: int) -> void:
	var oyuncu: Oyuncu = bolum.find_child("Oyuncu", true, false)
	var noktalar: Array = Bolumler.veri(no)["kanca"]
	if oyuncu == null or noktalar.size() < 2:
		return
	var hedef: Vector2 = noktalar[1]
	oyuncu.global_position = hedef + Vector2(-70.0, 110.0)
	oyuncu.velocity = Vector2(330.0, -60.0)
	oyuncu.kanca_at((hedef - oyuncu.global_position).normalized())

func _menu_cek() -> void:
	# Control'un capalari, ust ogesi Node2D olursa sifir dikdortgene cozulur.
	# Oyunda menu sahne kokudur; burada ayni kosulu CanvasLayer ile taklit ediyoruz.
	var katman := CanvasLayer.new()
	add_child(katman)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	katman.add_child(menu)
	for i in 10:
		await get_tree().process_frame
	await _kaydet("menu")
	menu.call("_secim_goster")
	for i in 5:
		await get_tree().process_frame
	await _kaydet("bolum_sec")
	katman.free()
	await get_tree().process_frame

func _kaydet(ad: String) -> void:
	await RenderingServer.frame_post_draw
	var resim := get_viewport().get_texture().get_image()
	var hata := resim.save_png("res://docs/ekran/%s.png" % ad)
	if hata != OK:
		printerr("PNG yazilamadi: %s (%d)" % [ad, hata])
