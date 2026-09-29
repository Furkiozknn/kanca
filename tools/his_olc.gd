extends Node
## Kanca girdi gecikmesi olcumu: tus basisi olayindan kancanin tutunmasina
## (`kanca_takildi` sinyali) ve tus birakma olayindan kancanin kopmasina
## (`kanca_koptu`) gecen sure. Gercek zamanli kosar (--fixed-fps YOK): fizik 60 Hz
## oldugu icin adim bekleyen bir yolun gecikmesi 0-16,7 ms + ucus suresi dagilir.
##   godot --path . --scene res://tools/his_olc.tscn -- [deneme_sayisi] [hizli]
## Pencereli kos (headless'ta Input.parse_input_event dugumlere ulasmiyor).
## "hizli": vsync kapali, kare siniri yok (yuksek yenileme hizli ekran
## benzetimi: fizik adimi kareden seyrek olur, adim bekleme suresi gorunur).
## Her denemede basis, fizik adimina gore rastgele bir fazda yapilir. Olay
## Input.parse_input_event ile yollanir (gercek klavye gibi _input'a ulasir).
## Sonuc docs/TASARIM.md'de: ortalama, %95, en yuksek.

const OYUNCU_SAHNE := preload("res://scenes/oyuncu.tscn")

var _t0: int = 0
var _tak: Array[float] = []
var _kop: Array[float] = []
var _bekleyen := ""


func _ready() -> void:
	Kayit.salt_okunur = true
	var n := 60
	var arg := OS.get_cmdline_user_args()
	if arg.size() > 0:
		n = int(arg[0])
	if arg.has("hizli"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	_kos(n)


func _olay(eylem: StringName, basildi: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = eylem
	ev.pressed = basildi
	Input.parse_input_event(ev)


func _kos(n: int) -> void:
	var o: Oyuncu = OYUNCU_SAHNE.instantiate()
	add_child(o)
	var nokta := KancaNoktasi.yap(Vector2(90, -70), KancaNoktasi.TUR_SABIT)
	add_child(nokta)
	o.kanca_takildi.connect(func(_y: Vector2) -> void:
		if _bekleyen == "tak" and _t0 > 0:
			_tak.append(float(Time.get_ticks_usec() - _t0) / 1000.0)
			_t0 = 0)
	o.kanca_koptu.connect(func(_h: Vector2, _b: bool) -> void:
		if _bekleyen == "kop" and _t0 > 0:
			_kop.append(float(Time.get_ticks_usec() - _t0) / 1000.0)
			_t0 = 0)
	await get_tree().create_timer(0.3).timeout
	var i := 0
	while i < n:
		o.kanca_birak()
		o.global_position = Vector2.ZERO
		o.velocity = Vector2.ZERO
		await get_tree().create_timer(0.08 + randf() * 0.0167).timeout   # rastgele faz
		_bekleyen = "tak"
		_t0 = Time.get_ticks_usec()
		_olay(&"kanca_at", true)
		var kalan := 0
		while _t0 > 0 and kalan < 60:
			await get_tree().process_frame
			kalan += 1
		await get_tree().create_timer(0.12 + randf() * 0.0167).timeout
		_bekleyen = "kop"
		_t0 = Time.get_ticks_usec()
		_olay(&"kanca_at", false)
		kalan = 0
		while _t0 > 0 and kalan < 60:
			await get_tree().process_frame
			kalan += 1
		_bekleyen = ""
		await get_tree().create_timer(0.1).timeout
		i += 1
	_yaz("TAK", _tak)
	_yaz("KOP", _kop)
	get_tree().quit(0)


func _yaz(ad: String, olcu: Array[float]) -> void:
	if olcu.is_empty():
		print("HIS_OLCUM %s deneme=0" % ad)
		return
	olcu.sort()
	var top := 0.0
	for x in olcu:
		top += x
	print("HIS_OLCUM %s deneme=%d ort_ms=%.1f p95_ms=%.1f en_yuksek_ms=%.1f en_dusuk_ms=%.1f" % [
		ad, olcu.size(), top / olcu.size(), olcu[int(olcu.size() * 0.95)],
		olcu[olcu.size() - 1], olcu[0]])
