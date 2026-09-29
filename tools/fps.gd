extends SceneTree
## Olcum araci: bir bolum sahnesini gercek render ile calistirir, kare suresini olcer.
##   godot --path . -s res://tools/fps.gd -- <bolum_no> <kare_sayisi> [gecis]
## "gecis" verilirse 0,7 sn arayla sirayla sekiz gecis ailesi (Gecis autoload)
## oynatilir; kaplama gorunurken olculen kareler ayri satirda (FPS_GECIS) basilir.
## Vsync kapali, 90 kare isinma. Sag tus basili tutulur, kanca_at 0,7 sn'de bir
## basilip birakilir (halat, parcacik, sarsinti ve iz calissin). Sonuc: ortalama
## ms, %99 ms, FPS. Kayit dosyasina dokunmaz (Kayit.salt_okunur).

func _initialize() -> void:
	var arg := OS.get_cmdline_user_args()
	var no := int(arg[0]) if arg.size() > 0 else 10
	var kare_n := int(arg[1]) if arg.size() > 1 else 600
	var gecis_ac: bool = arg.size() > 2 and arg[2] == "gecis"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.get_node("Kayit").salt_okunur = true
	var bolum: Node = load("res://scenes/bolumler/bolum_%02d.tscn" % no).instantiate()
	root.add_child(bolum)
	_kos(bolum, no, kare_n, gecis_ac)


const TURLER: Array = [&"iris", &"glitch", &"bloklar", &"itme", &"perde", &"flas", &"kararma", &"zoom"]


func _kos(bolum: Node, no: int, kare_n: int, gecis_ac: bool) -> void:
	var sureler: Array[float] = []
	var g: Node = root.get_node("Gecis")
	var gecis_sureler: Array[float] = []
	var k := 0
	var son := Time.get_ticks_usec()
	var i := 0
	Input.action_press("move_right")
	while i < kare_n + 90:
		await process_frame
		var s := Time.get_ticks_usec()
		if i >= 90:
			if gecis_ac and g.get("_kaplama").visible:
				gecis_sureler.append(float(s - son) / 1000.0)
			else:
				sureler.append(float(s - son) / 1000.0)
		if gecis_ac and i >= 90 and (i - 90) % 42 == 21 and not g.get("_kaplama").visible:
			g.call("acilis", TURLER[k % TURLER.size()], k % 2, 0.46, 1.0)   # ortu tam kapali baslar, acilir
			k += 1
		son = s
		if i % 42 == 0:
			Input.action_press("kanca_at")
		elif i % 42 == 20:
			Input.action_release("kanca_at")
		i += 1
	Input.action_release("kanca_at")
	Input.action_release("move_right")
	sureler.sort()
	var top := 0.0
	for x in sureler:
		top += x
	var ort := top / float(sureler.size())
	var p99 := sureler[int(sureler.size() * 0.99)]
	print("FPS_OLCUM bolum=%d kare=%d ort_ms=%.2f p99_ms=%.2f fps=%.1f renderer=%s" % [
		no, sureler.size(), ort, p99, 1000.0 / ort,
		RenderingServer.get_video_adapter_name()])
	if gecis_ac and not gecis_sureler.is_empty():
		gecis_sureler.sort()
		var gt := 0.0
		for x in gecis_sureler:
			gt += x
		var gort := gt / float(gecis_sureler.size())
		print("FPS_GECIS kare=%d ort_ms=%.2f p99_ms=%.2f en_kotu_ms=%.2f fps=%.1f gecis_sayisi=%d" % [
			gecis_sureler.size(), gort, gecis_sureler[int(gecis_sureler.size() * 0.99)], gecis_sureler[-1], 1000.0 / gort, k])
	bolum.queue_free()
	quit(0)
