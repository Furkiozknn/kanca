extends Node2D
## Rota planlayici + otomatik oynayan bot. Madalya surelerini ve rota ipucunu uretir.
##
##   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . --scene res://tools/rota.tscn
##
## Iki asama:
##   1. PLAN  - kanca noktalarindan graf kurulur (menzil + gorus hatti), baslangictan
##              bitise en dusuk maliyetli zincir Dijkstra ile bulunur.
##   2. KOSU  - bot bu rotayi gercek fizikle oynar. Her kosuda karar anlarina
##              rastgele tepki gecikmesi eklenir (insan gecikmesi taklidi).
##
## Sure ADIM SAYISINDAN hesaplanir (kare/60), gercek zamandan degil: headless'ta
## process delta gercek zamana bagli, fizik karesi ise sabit. Boylece olculen sure
## oyunda gecen sureyle birebir ayni.
##
## Cikti: scripts/rota_verisi.gd (uretilmis dosya) + ekrana ozet tablo.

const CIKTI := "res://scripts/rota_verisi.gd"
const KOSU_SAYISI := 5              ## bolum basina deneme (farkli gecikme tohumlari)
const AZAMI_KARE := 2700            ## 45 saniye sim suresi; asilirsa basarisiz
const OYUNCU_YARI_BOY := 14.0
const ZIPLA_YUKSEKLIGI := 45.0
const INIS_MESAFESI := 300.0        ## son noktadan bitise inilebilecek mesafe
const HOP_BEDELI := 70.0            ## her kanca degisiminin plan maliyeti (px cinsinden)

## Tepki gecikmesi araligi (sn): karar anindan eyleme.
const GECIKME_ALT := 0.05
const GECIKME_UST := 0.20

## Madalya carpanlari: altin = en iyi kosu, gumus/bronz gecikmeli koslar uzerinden.
const ALTIN_PAY := 1.08
const GUMUS_PAY := 1.45
const BRONZ_PAY := 1.95

var _sonuc: Dictionary = {}

func _ready() -> void:
	_calistir()

func _calistir() -> void:
	await get_tree().process_frame
	print("=== Kanca rota + bot kosusu ===")
	print("bolum basina %d kosu, tepki gecikmesi %.2f-%.2f sn, azami %d kare" % [
		KOSU_SAYISI, GECIKME_ALT, GECIKME_UST, AZAMI_KARE])
	for no in range(1, Bolumler.sayi() + 1):
		var rota := _plan(no)
		if rota.is_empty():
			printerr("bolum %d: rota bulunamadi" % no)
			continue
		var sureler: Array[float] = []
		for k in KOSU_SAYISI:
			var s := await _kos(no, rota, k)
			if s > 0.0:
				sureler.append(s)
		if sureler.is_empty():
			printerr("bolum %2d: bot bitiremedi (%d nokta)" % [no, rota.size()])
			continue
		sureler.sort()
		var en_iyi: float = sureler[0]
		var ortanca: float = sureler[sureler.size() / 2]
		_sonuc[no] = {
			"sure": en_iyi,
			"ortanca": ortanca,
			"madalya": [
				snappedf(ortanca * ALTIN_PAY, 0.001),
				snappedf(ortanca * GUMUS_PAY, 0.001),
				snappedf(ortanca * BRONZ_PAY, 0.001),
			],
			"nokta": rota,
		}
		print("bolum %2d  %-16s kosu %d/%d  en iyi %.3f  ortanca %.3f  altin %.3f  nokta %d" % [
			no, Bolumler.ad(no), sureler.size(), KOSU_SAYISI, en_iyi, ortanca,
			ortanca * ALTIN_PAY, rota.size()])
	_yaz()
	print("=== rota bitti: %d/%d bolum ===" % [_sonuc.size(), Bolumler.sayi()])
	get_tree().quit(0 if _sonuc.size() == Bolumler.sayi() else 1)

# --- 1. Plan ----------------------------------------------------------

## Baslangictan bitise en dusuk maliyetli kanca zinciri. Bos dizi = bulunamadi.
func _plan(no: int) -> Array:
	var d := Bolumler.veri(no)
	var kanca := Bolumler.tum_kanca(no)
	var zeminler := Bolumler.zeminler(no)
	var basla: Vector2 = Vector2(d["basla"]) - Vector2(0, OYUNCU_YARI_BOY + ZIPLA_YUKSEKLIGI)
	var bitis: Vector2 = Vector2(d["bitis"]) - Vector2(0, OYUNCU_YARI_BOY)
	var zincir: float = Ayarlar.KANCA_MENZIL + Ayarlar.KANCA_AZAMI_HALAT * 0.7

	# Dijkstra: dugumler kanca noktalari, kaynak baslangic, hedef bitis.
	var maliyet: Array[float] = []
	var onceki: Array[int] = []
	maliyet.resize(kanca.size())
	onceki.resize(kanca.size())
	for i in kanca.size():
		maliyet[i] = INF
		onceki[i] = -1
		if basla.distance_to(kanca[i]) <= Ayarlar.KANCA_MENZIL \
				and Bolumler.gorus_var(basla, kanca[i], zeminler):
			maliyet[i] = basla.distance_to(kanca[i]) + HOP_BEDELI
	var islendi: Array[bool] = []
	islendi.resize(kanca.size())
	islendi.fill(false)
	while true:
		var en := -1
		for i in kanca.size():
			if not islendi[i] and maliyet[i] < INF and (en == -1 or maliyet[i] < maliyet[en]):
				en = i
		if en == -1:
			break
		islendi[en] = true
		for j in kanca.size():
			if islendi[j]:
				continue
			var uz := kanca[en].distance_to(kanca[j])
			if uz > zincir or not Bolumler.gorus_var(kanca[en], kanca[j], zeminler):
				continue
			var yeni := maliyet[en] + uz + HOP_BEDELI
			if yeni < maliyet[j]:
				maliyet[j] = yeni
				onceki[j] = en

	var son := -1
	var en_iyi := INF
	for i in kanca.size():
		if maliyet[i] == INF:
			continue
		var uz := kanca[i].distance_to(bitis)
		if uz > INIS_MESAFESI:
			continue
		if maliyet[i] + uz < en_iyi:
			en_iyi = maliyet[i] + uz
			son = i
	if son == -1:
		return []
	var yol: Array = []
	var i2 := son
	while i2 != -1:
		yol.push_front(kanca[i2])
		i2 = onceki[i2]
	return yol

# --- 2. Kosu ----------------------------------------------------------

## Bolumu rotayi izleyerek oynar. Donen deger: sure (sn) ya da 0 = bitiremedi.
func _kos(no: int, rota: Array, tohum: int) -> float:
	var rastgele := RandomNumberGenerator.new()
	rastgele.seed = hash("kanca-%d-%d" % [no, tohum])

	var bolum: Bolum = load(Bolumler.yol(no)).instantiate()
	add_child(bolum)
	for i in 4:
		await get_tree().physics_frame
	var oyuncu: Oyuncu = bolum.find_child("Oyuncu", true, false)
	oyuncu.girdi_aktif = false

	var hedef_i := 0
	var gecikme := 0.0
	var tutma := 0.0
	var kare := 0
	var bitti := false
	while kare < AZAMI_KARE:
		await get_tree().physics_frame
		kare += 1
		if bool(bolum.get("_bitti")):
			bitti = true
			break
		var dt := 1.0 / 60.0
		gecikme = maxf(gecikme - dt, 0.0)
		var hedef: Vector2 = rota[mini(hedef_i, rota.size() - 1)] if hedef_i < rota.size() \
			else Vector2(Bolumler.veri(no)["bitis"])
		var pos: Vector2 = oyuncu.global_position

		if oyuncu.kancali():
			tutma += dt
			var capa: Vector2 = oyuncu.kanca_nokta.global_position
			var disa := (pos - capa).normalized()
			var teget := Vector2(-disa.y, disa.x)
			if teget.x < 0.0:
				teget = -teget
			# Pompala: mevcut salinimi buyut.
			oyuncu.bot_yon = signf(oyuncu.velocity.dot(teget))
			var sonraki: Vector2 = rota[hedef_i + 1] if hedef_i + 1 < rota.size() \
				else Vector2(Bolumler.veri(no)["bitis"])
			var yon := (sonraki - pos).normalized()
			var hiz := oyuncu.velocity
			var uygun: bool = hiz.length() >= Ayarlar.BIRAKMA_ESIGI \
				and hiz.normalized().dot(yon) > 0.55 and pos.x > capa.x - 8.0
			if gecikme <= 0.0 and (uygun or tutma > 2.5):
				oyuncu.kanca_birak()
				oyuncu.bot_yon = 1.0
				hedef_i += 1
				tutma = 0.0
				gecikme = rastgele.randf_range(GECIKME_ALT, GECIKME_UST)
			continue

		tutma = 0.0
		oyuncu.bot_yon = signf(hedef.x - pos.x) if absf(hedef.x - pos.x) > 6.0 else 1.0
		if oyuncu.uculuyor() or gecikme > 0.0:
			continue
		# Hedefe kanca at; menzil disindaysa kosarak/ziplayarak yaklas.
		if pos.distance_to(hedef) <= Ayarlar.KANCA_MENZIL \
				and oyuncu.gorus_var(hedef):
			if oyuncu.kanca_at((hedef - pos).normalized()):
				gecikme = rastgele.randf_range(GECIKME_ALT, GECIKME_UST)
		elif oyuncu.is_on_floor():
			oyuncu.velocity.y = -Ayarlar.ZIPLA_GUCU

	bolum.free()
	await get_tree().physics_frame
	return float(kare) / 60.0 if bitti else 0.0

# --- 3. Yazma ---------------------------------------------------------

func _yaz() -> void:
	var satirlar := PackedStringArray()
	for no in range(1, Bolumler.sayi() + 1):
		if not _sonuc.has(no):
			continue
		var s: Dictionary = _sonuc[no]
		var noktalar := PackedStringArray()
		for p: Vector2 in s["nokta"]:
			noktalar.append("Vector2(%d, %d)" % [int(p.x), int(p.y)])
		var m: Array = s["madalya"]
		satirlar.append("\t%d: {\"sure\": %.3f, \"ortanca\": %.3f, \"madalya\": [%.3f, %.3f, %.3f], \"nokta\": [%s]}," % [
			no, s["sure"], s["ortanca"], m[0], m[1], m[2], ", ".join(noktalar)])

	var f := FileAccess.open(CIKTI, FileAccess.READ)
	if f == null:
		printerr("rota_verisi.gd okunamadi")
		return
	var metin := f.get_as_text()
	f.close()
	var bas := metin.find("const VERI := {")
	var son := metin.find("}", bas)
	if bas < 0 or son < 0:
		printerr("rota_verisi.gd icinde VERI bloku bulunamadi")
		return
	var yeni := "const VERI := {\n%s\n" % "\n".join(satirlar)
	metin = metin.substr(0, bas) + yeni + metin.substr(son)
	var y := FileAccess.open(CIKTI, FileAccess.WRITE)
	y.store_string(metin)
	y.close()
	print("yazildi: %s (%d bolum)" % [CIKTI, satirlar.size()])
