extends SceneTree
## Olcum araci: bir bolum sahnesini gercek render ile calistirir, kare suresini olcer.
##   godot --path . -s res://tools/fps.gd -- <bolum_no> <kare_sayisi>
## Vsync kapali, 90 kare isinma. Sag tus basili tutulur, kanca_at 0,7 sn'de bir
## basilip birakilir (halat, parcacik, sarsinti ve iz calissin). Sonuc: ortalama
## ms, %99 ms, FPS. Kayit dosyasina dokunmaz (Kayit.salt_okunur).

func _initialize() -> void:
	var arg := OS.get_cmdline_user_args()
	var no := int(arg[0]) if arg.size() > 0 else 10
	var kare_n := int(arg[1]) if arg.size() > 1 else 600
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.get_node("Kayit").salt_okunur = true
	var bolum: Node = load("res://scenes/bolumler/bolum_%02d.tscn" % no).instantiate()
	root.add_child(bolum)
	_kos(bolum, no, kare_n)


func _kos(bolum: Node, no: int, kare_n: int) -> void:
	var sureler: Array[float] = []
	var son := Time.get_ticks_usec()
	var i := 0
	Input.action_press("move_right")
	while i < kare_n + 90:
		await process_frame
		var s := Time.get_ticks_usec()
		if i >= 90:
			sureler.append(float(s - son) / 1000.0)
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
	bolum.queue_free()
	quit(0)
