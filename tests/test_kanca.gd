extends Node2D
## Cekirdek mekanik testi. Calistirma:
##   godot --headless --path . res://tests/test_kanca.tscn
## Cikis kodu = kalan test sayisi (0 = hepsi gecti).

const OYUNCU_SAHNE := preload("res://scenes/oyuncu.tscn")

const HALAT_TOLERANS := 1.5   ## px; konum duzeltmesinden sonra kabul edilen sapma
const KARE_SAYISI := 320      ## sarkac simulasyonunun uzunlugu

var _kalan := 0
var _toplam := 0

func _ready() -> void:
	_calistir()

func _calistir() -> void:
	await get_tree().process_frame
	print("=== Kanca cekirdek testleri ===")
	await _test_menzil()
	await _test_halat_kisiti()
	await _test_momentum()
	await _test_bolum_sahneleri()
	_test_gecilebilirlik()
	print("=== %d/%d gecti ===" % [_toplam - _kalan, _toplam])
	get_tree().quit(_kalan)

func _bildir(ad: String, tamam: bool, not_metni: String = "") -> void:
	_toplam += 1
	if tamam:
		print("  GECTI  %s" % ad)
	else:
		_kalan += 1
		printerr("  KALDI  %s  %s" % [ad, not_metni])

func _oyuncu_yap(yer: Vector2) -> Oyuncu:
	var o: Oyuncu = OYUNCU_SAHNE.instantiate()
	o.girdi_aktif = false
	add_child(o)
	o.global_position = yer
	return o

func _nokta_yap(yer: Vector2) -> KancaNoktasi:
	var n := KancaNoktasi.new()
	add_child(n)
	n.global_position = yer
	return n

# --- 1. Menzil --------------------------------------------------------

func _test_menzil() -> void:
	var o := _oyuncu_yap(Vector2.ZERO)
	o.set_physics_process(false)
	var uzak := _nokta_yap(Vector2(0.0, -(Ayarlar.KANCA_MENZIL + 60.0)))
	await get_tree().physics_frame

	_bildir("menzil disindaki noktaya kanca takilmaz",
		not o.kanca_at(Vector2.UP),
		"uzaklik=%.1f menzil=%.1f" % [Ayarlar.KANCA_MENZIL + 60.0, Ayarlar.KANCA_MENZIL])

	var yakin := _nokta_yap(Vector2(0.0, -(Ayarlar.KANCA_MENZIL - 40.0)))
	await get_tree().physics_frame
	var takildi := o.kanca_at(Vector2.UP)
	_bildir("menzil icindeki noktaya kanca takilir", takildi and o.kanca_nokta == yakin,
		"kanca_nokta=%s" % str(o.kanca_nokta))

	o.queue_free()
	uzak.queue_free()
	yakin.queue_free()
	await get_tree().physics_frame

# --- 2. Halat kisiti --------------------------------------------------

func _test_halat_kisiti() -> void:
	var capa := _nokta_yap(Vector2(0.0, -300.0))
	var o := _oyuncu_yap(Vector2(0.0, -150.0))
	await get_tree().physics_frame

	var takildi := o.kanca_at(Vector2.UP)
	var boy := o.halat_boyu
	o.velocity = Vector2(520.0, 0.0)   # sert bir savurma

	var en_kotu := 0.0
	for i in KARE_SAYISI:
		await get_tree().physics_frame
		if not o.kancali():
			break
		var sapma: float = o.global_position.distance_to(capa.global_position) - o.halat_boyu
		en_kotu = maxf(en_kotu, sapma)

	_bildir("takiliyken mesafe halat boyunu asmaz (%d kare)" % KARE_SAYISI,
		takildi and o.kancali() and en_kotu <= HALAT_TOLERANS,
		"halat=%.1f en_buyuk_sapma=%.3f" % [boy, en_kotu])

	o.queue_free()
	capa.queue_free()
	await get_tree().physics_frame

# --- 3. Momentum ------------------------------------------------------

func _test_momentum() -> void:
	var capa := _nokta_yap(Vector2(0.0, -300.0))
	var o := _oyuncu_yap(Vector2(0.0, -150.0))
	await get_tree().physics_frame
	o.kanca_at(Vector2.UP)
	o.velocity = Vector2(420.0, 0.0)

	# Sarkacin en hizlandigi ana kadar salla.
	var once := Vector2.ZERO
	for i in 40:
		await get_tree().physics_frame
		if absf(o.velocity.x) > absf(once.x):
			once = o.velocity
	var birakmadan_once := o.velocity
	o.kanca_birak()
	var sonra := o.velocity

	_bildir("birakinca yatay hiz sifirlanmaz",
		absf(sonra.x) >= absf(birakmadan_once.x) * 0.95 and signf(sonra.x) == signf(birakmadan_once.x),
		"once=%.1f sonra=%.1f" % [birakmadan_once.x, sonra.x])

	# Serbest ucusta da momentum duruyor mu (yercekimi disinda yatayda kayip yok).
	for i in 30:
		await get_tree().physics_frame
	_bildir("birakildiktan sonra yatay hiz korunur",
		absf(o.velocity.x) >= absf(sonra.x) * 0.9,
		"birakinca=%.1f 30 kare sonra=%.1f" % [sonra.x, o.velocity.x])

	o.queue_free()
	capa.queue_free()
	await get_tree().physics_frame

# --- 4. Bolum sahneleri -----------------------------------------------

func _test_bolum_sahneleri() -> void:
	_bildir("en az 8 bolum tanimli", Bolumler.sayi() >= 8, "sayi=%d" % Bolumler.sayi())
	for no in range(1, Bolumler.sayi() + 1):
		var yol := Bolumler.yol(no)
		if not ResourceLoader.exists(yol):
			_bildir("bolum %d sahnesi var" % no, false, yol)
			continue
		var sahne: PackedScene = load(yol)
		var bolum: Bolum = sahne.instantiate()
		add_child(bolum)
		for i in 3:
			await get_tree().physics_frame

		var veri := Bolumler.veri(no)
		var noktalar := 0
		for n in get_tree().get_nodes_in_group(KancaNoktasi.GRUP):
			if bolum.is_ancestor_of(n):
				noktalar += 1
		var oyuncu: Node = bolum.find_child("Oyuncu", true, false)
		var bitis: Node = bolum.find_child("Bitis", true, false)

		var tamam: bool = (bolum.bolum_no == no
			and oyuncu != null
			and bitis != null
			and noktalar >= 3
			and veri["basla"] != veri["bitis"])
		_bildir("bolum %d: baslangic + bitis + %d kanca noktasi" % [no, noktalar], tamam,
			"oyuncu=%s bitis=%s nokta=%d" % [str(oyuncu != null), str(bitis != null), noktalar])

		bolum.free()
		await get_tree().physics_frame

# --- 5. Gecilebilirlik ------------------------------------------------

## Her bosluk kanca zinciriyle asilabiliyor mu? Ledge'den menzil icindeki
## noktalara tutunulur, oradan zincirle ilerlenir, son nokta karsi kenara
## inecek kadar yakin olmali. Bolum verisi bozulursa bu test yakalar.
const ZINCIR_MENZILI := Ayarlar.KANCA_MENZIL + Ayarlar.KANCA_AZAMI_HALAT * 0.7
const INIS_MESAFESI := 300.0
const ZIPLA_YUKSEKLIGI := 45.0
const OYUNCU_YARI_BOY := 14.0

func _test_gecilebilirlik() -> void:
	for no in range(1, Bolumler.sayi() + 1):
		var veri := Bolumler.veri(no)
		var kanca: Array = veri["kanca"]
		var zeminler: Array[Rect2] = []
		for r: Rect2 in veri["zemin"]:
			if r.position.y >= 150.0:   # tavan bloklarini ele
				zeminler.append(r)
		zeminler.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)

		var kotu := ""
		for i in range(zeminler.size() - 1):
			var sol_r: Rect2 = zeminler[i]
			var sag_r: Rect2 = zeminler[i + 1]
			var gx0 := sol_r.end.x
			var gx1 := sag_r.position.x
			if gx1 <= gx0 + 1.0:
				continue
			var sol := Vector2(gx0, sol_r.position.y - OYUNCU_YARI_BOY - ZIPLA_YUKSEKLIGI)
			var sag := Vector2(gx1, sag_r.position.y - OYUNCU_YARI_BOY)

			var goruldu: Array[Vector2] = []
			var kuyruk: Array[Vector2] = []
			for k: Vector2 in kanca:
				if k.distance_to(sol) <= Ayarlar.KANCA_MENZIL:
					goruldu.append(k)
					kuyruk.append(k)
			while not kuyruk.is_empty():
				var k: Vector2 = kuyruk.pop_back()
				for m: Vector2 in kanca:
					if not goruldu.has(m) and k.distance_to(m) <= ZINCIR_MENZILI:
						goruldu.append(m)
						kuyruk.append(m)

			var indi := false
			for k: Vector2 in goruldu:
				if k.distance_to(sag) <= INIS_MESAFESI:
					indi = true
					break
			if not indi:
				kotu += " bosluk %d-%d;" % [int(gx0), int(gx1)]

		_bildir("bolum %d: tum bosluklar kanca zinciriyle asilabilir" % no, kotu == "", kotu)
