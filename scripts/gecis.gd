extends CanvasLayer
## Sahne gecisi (autoload "Gecis"). Gunluk videolardaki gecis aileleri ekran-uzayi
## shader'i ile (assets/gecis.gdshader): iris, glitch, bloklar, itme, perde, flas,
## kararma, zoom. Ortme ~260 ms, acma ~200 ms (stil rehberi). Renkler temanin
## video akis paletinden (Tema.AKIS) sirayla doner; tur, temanin havuzundan
## art arda tekrarlanmadan secilir. Bant sirasinda ikinci cagri yok sayilir.
## Hareket azaltma (Ayarlar'da "Sade gecisler" ya da tarayicida
## prefers-reduced-motion) acikken gecis ANINDA: efekt yok, bekleme yok.
## Olumde sahne degismez: kisa bir tehlike rengi flasi (yanip_son).
## Duraklatma sirasinda da calisir (PROCESS_MODE_ALWAYS).

const ORTME := 0.26
const ACMA := 0.20
const FLAS := 0.30
const SHADER := preload("res://assets/gecis.gdshader")

var son_tur: StringName = &""        ## test/olcum icin: en son kullanilan aile
var acilis_yapildi := false          ## menu acilis iris'i yalniz ilk acilista
var _kaplama: ColorRect
var _mat: ShaderMaterial
var _flas: ColorRect
var _mesgul := false
var _ipucu: Label
var _dikey_kart: Panel
var _ipucu_sayac := 0.0
var _tween: Tween = null
var _sayac := 0                      ## renk akisi sirasi
var _sistem_azalt := false           ## tarayici "hareketi azalt" istiyor


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_kaplama = ColorRect.new()
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_kaplama.material = _mat
	_kaplama.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kaplama.visible = false
	add_child(_kaplama)
	_kaplama.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flas = ColorRect.new()
	_flas.color = Color(Tema.DIKEN, 0.0)
	_flas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flas)
	if OS.has_feature("web"):
		_sistem_azalt = bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	# Dikey telefon: oyun 16:9'a kilitli, yatay tutmak gerekir. Pencere dikeye
	# donunce 4 sn'lik bir ipucu cikar.
	_dikey_kart = Panel.new()
	_dikey_kart.theme_type_variation = &"Kagit"
	_dikey_kart.position = Vector2(40.0, 110.0)
	_dikey_kart.size = Vector2(560.0, 140.0)
	_dikey_kart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dikey_kart.visible = false
	add_child(_dikey_kart)
	_ipucu = Label.new()
	_ipucu.theme_type_variation = &"KartBaslik"
	_ipucu.add_theme_font_size_override("font_size", 24)
	_ipucu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ipucu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ipucu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ipucu.position = Vector2(20.0, 10.0)
	_ipucu.size = Vector2(520.0, 120.0)
	_ipucu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dikey_kart.add_child(_ipucu)
	get_tree().root.size_changed.connect(_boyut_degisti)
	_boyut_degisti.call_deferred()


func mesgul_mu() -> bool:
	return _mesgul


## Hareket azaltma: ayar aciksa ya da tarayici istiyorsa gecis anindadir.
func sade() -> bool:
	return bool(Kayit.ayar("gecis_sade")) or _sistem_azalt


## Temanin havuzundan sonraki gecis ailesi (video: gecisHavuz); bir oncekini tekrarlamaz.
func sec(tema: int) -> StringName:
	var havuz: Array = Tema.AKIS[clampi(tema, 0, Tema.AKIS.size() - 1)]["gecis"]
	return havuz[(havuz.find(son_tur) + 1) % havuz.size()]    # havuzu sirayla gezer: tekrar yok, hepsi kullanilir


## Ortme oncesi: shader'i bu gecisin tur ve renkleriyle kurar. Kaplama acma (ac)
## cagrilana kadar ayni renkte durur.
func _kur(tur: StringName, tema: int) -> void:
	if tur == &"":
		tur = sec(tema)
	son_tur = tur
	var a: Dictionary = Tema.AKIS[clampi(tema, 0, Tema.AKIS.size() - 1)]
	var r1: Color = Tema.akis_rengi(tema, _sayac)
	var r2: Color = Tema.akis_rengi(tema, _sayac + 2)
	if tur == &"flas":
		r1 = a["acik"]
	elif tur == &"kararma":
		r1 = a["koyu"]
	_sayac += 1
	_mat.set_shader_parameter("tur", maxi(Tema.GECIS_TURLERI.find(tur), 0))
	_mat.set_shader_parameter("renk", r1)
	_mat.set_shader_parameter("renk2", r2)
	_mat.set_shader_parameter("p", 0.0)


func _p_yaz(v: float) -> void:
	_mat.set_shader_parameter("p", v)
	_mat.set_shader_parameter("adim", floorf(Time.get_ticks_msec() / 33.0))


## Ekrani orter (await edilebilir). Sade kipte hicbir sey yapmaz ve bekletmez.
func kapat(tur: StringName = &"", tema: int = 0, sure: float = ORTME) -> void:
	if sade():
		return
	_kur(tur, tema)
	_kaplama.visible = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(_p_yaz, 0.0, 1.0, sure)
	await _tween.finished


## Ortuyu acar; bekletmek istemeyen cagiran await etmez (oyun akisi surer).
func ac(sure: float = ACMA, baslangic: float = 1.0) -> void:
	if not _kaplama.visible:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(_p_yaz, baslangic, 0.0, sure)
	await _tween.finished
	_kaplama.visible = false


## Kapali basla, ac: menu acilisi ve duraklatma perdesi gibi "icerik acilir" anlari.
func acilis(tur: StringName = &"iris", tema: int = 0, sure: float = ACMA + 0.1, baslangic: float = 1.0) -> void:
	if sade():
		return
	_kur(tur, tema)
	_kaplama.visible = true
	_p_yaz(baslangic)
	await ac(sure, baslangic)


## Yerinde gecis: ort, `degistir`i cagir (metin/sahne degisimi), ac.
func ara(tur: StringName, tema: int, degistir: Callable) -> void:
	if _mesgul:
		return
	_mesgul = true
	await kapat(tur, tema, ORTME * 0.7)
	degistir.call()
	if not sade():
		await get_tree().process_frame
		await get_tree().process_frame
	await ac(ACMA)
	_mesgul = false


## Sahneyi degistirir. Bant sirasinda ikinci cagri yok sayilir (cift tik).
func git(yol: String, tema: int = 0, tur: StringName = &"") -> void:
	if _mesgul:
		return
	_mesgul = true
	if sade():
		get_tree().change_scene_to_file(yol)
		_mesgul = false
		return
	await kapat(tur, tema)
	get_tree().change_scene_to_file(yol)
	await get_tree().process_frame
	await get_tree().process_frame
	await ac(ACMA)
	_mesgul = false


## Sahne degistirmeden kisa flas (olum, bolum basa alma). Girdiyi kilitlemez.
## Sade kipte flas yok (isik cakmasi).
func yanip_son() -> void:
	if sade():
		return
	_flas.color = Color(Tema.DIKEN, 0.34)
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_flas, "color:a", 0.0, FLAS)


## Pencere dikeyse (telefon) "yatay tut" ipucu; yataya donunce kaybolur.
func _boyut_degisti() -> void:
	var boyut := get_tree().root.size
	var dikey: bool = boyut.y > boyut.x
	_ipucu.text = tr("Cihazını yatay çevir")
	_dikey_kart.visible = dikey
	_ipucu_sayac = 4.0 if dikey else 0.0


func _process(delta: float) -> void:
	if _ipucu_sayac > 0.0:
		_ipucu_sayac -= delta
		if _ipucu_sayac <= 0.0:
			_dikey_kart.visible = false
