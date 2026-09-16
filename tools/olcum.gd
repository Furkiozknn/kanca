extends Node2D
## Sallanma sabitlerini olcen bot. Insan testinin yerini tutmaz ama
## "hangi aralik makul" sorusunu sayiyla cevaplar.
##
##   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . --scene res://tools/olcum.tscn
##
## Dort tarama:
##   1. SALLANMA_IVMESI x SALLANMA_SONUMU  -> hedef hiza ulasma suresi
##   2. SALLANMA_SONUMU (girdisiz)         -> tus birakilinca kalan enerji
##   3. BIRAKMA_CARPANI                    -> birakma sonrasi ucus mesafesi
##   4. KANCA_MENZIL                       -> 14 bolumde zincir baglanabilirligi
##
## Bot "iyi oyuncu" taklidi yapar: her karede tegetsel hizin isaretine basar
## (sarkaci pompalamanin dogru yolu).

const OYUNCU_SAHNE := preload("res://scenes/oyuncu.tscn")
const HALAT := 140.0
const POMPA_KARE := 420          ## 7 saniye
const HEDEF_HIZ := 500.0         ## "hizli hissettiren" esik
const YUKSEK_HIZ := 800.0        ## hiz tavanina (900) yakin

var _oyuncu: Oyuncu
var _capa: KancaNoktasi

func _ready() -> void:
	_calistir()

func _calistir() -> void:
	await get_tree().process_frame
	print("=== Kanca sallanma olcumu ===")
	print("halat=%.0f px  pompa=%d kare  yercekimi=%.0f  azami_hiz=%.0f" % [
		HALAT, POMPA_KARE, Ayarlar.YERCEKIMI, Ayarlar.AZAMI_HIZ])

	await _tarama_sallanma()
	await _tarama_serbest()
	await _tarama_birakma()
	_tarama_menzil()

	print("=== olcum bitti ===")
	get_tree().quit(0)

func _kur() -> void:
	if _oyuncu != null:
		_oyuncu.free()
	if _capa != null:
		_capa.free()
	_capa = KancaNoktasi.yap(Vector2.ZERO, KancaNoktasi.TUR_SABIT)
	add_child(_capa)
	_oyuncu = OYUNCU_SAHNE.instantiate()
	_oyuncu.girdi_aktif = false
	add_child(_oyuncu)
	_oyuncu.global_position = Vector2(0.0, HALAT)
	_oyuncu.velocity = Vector2(30.0, 0.0)   # kucuk bir baslangic itisi

## Tegetsel hizin isaretine bas: sarkaci buyutmenin dogru yolu.
func _bot_bas() -> void:
	var fark := _oyuncu.global_position - _capa.global_position
	if fark.length() < 0.001:
		return
	var disa := fark.normalized()
	var teget := Vector2(-disa.y, disa.x)
	if teget.x < 0.0:
		teget = -teget
	var izdusum := _oyuncu.velocity.dot(teget)
	_oyuncu.bot_yon = signf(izdusum) if absf(izdusum) > 8.0 else 1.0

# --- 1. Pompalama -----------------------------------------------------

## NOT: bot mukemmel pompaladigi icin her ayarda hiz tavanina (AZAMI_HIZ) carpiyor.
## Ayirt eden olcu "tepe" degil, hedefe ULASMA SURESI. Sonumun etkisi burada
## neredeyse gorunmuyor - onu 2. tarama (serbest birakma) olcuyor.
func _tarama_sallanma() -> void:
	print("\n-- 1. SALLANMA_IVMESI x SALLANMA_SONUMU (pompalayan bot) --")
	print("%-8s %-8s %8s %8s %8s" % ["ivme", "sonum", "t(500)", "t(800)", "kararli"])
	for ivme: float in [800.0, 950.0, 1100.0, 1250.0, 1400.0]:
		for sonum: float in [0.02, 0.05, 0.10, 0.15]:
			var s := await _pompa_olc(ivme, sonum)
			print("%-8.0f %-8.2f %8s %8s %8.0f" % [
				ivme, sonum,
				"-" if s["t_hedef"] < 0.0 else "%.2f" % s["t_hedef"],
				"-" if s["t_yuksek"] < 0.0 else "%.2f" % s["t_yuksek"],
				s["kararli"]])

## Doner: HEDEF_HIZ ve YUKSEK_HIZ'e ulasma sureleri, son 60 karedeki ortalama hiz.
func _pompa_olc(ivme: float, sonum: float) -> Dictionary:
	Ayarlar.SALLANMA_IVMESI = ivme
	Ayarlar.SALLANMA_SONUMU = sonum
	_kur()
	await get_tree().physics_frame
	_oyuncu.kanca_at_hemen(Vector2.UP)

	var tepe := 0.0
	var t_hedef := -1.0
	var t_yuksek := -1.0
	var toplam := 0.0
	for i in POMPA_KARE:
		_bot_bas()
		await get_tree().physics_frame
		if not _oyuncu.kancali():
			break
		var h := _oyuncu.velocity.length()
		tepe = maxf(tepe, h)
		if t_hedef < 0.0 and h >= HEDEF_HIZ:
			t_hedef = float(i) / 60.0
		if t_yuksek < 0.0 and h >= YUKSEK_HIZ:
			t_yuksek = float(i) / 60.0
		if i >= POMPA_KARE - 60:
			toplam += h
	return {"tepe": tepe, "t_hedef": t_hedef, "t_yuksek": t_yuksek, "kararli": toplam / 60.0}

# --- 2. Serbest birakma (sonumun gercek etkisi) ------------------------

## Oyuncu tusu biraktiginda sallanma ne kadar yasiyor? Sonum tek basina
## burada goruluyor: pompalayan bot her ayarda tavana carpiyor, ama insan
## surekli basmaz. 4 saniye girdisiz salinimdan sonra kalan tepe hiz.
func _tarama_serbest() -> void:
	print("\n-- 2. SALLANMA_SONUMU: girdi birakildiktan sonra kalan enerji --")
	print("%-8s %10s %10s %10s" % ["sonum", "bas_hiz", "4sn_tepe", "oran"])
	Ayarlar.SALLANMA_IVMESI = 1250.0
	for sonum: float in [0.0, 0.02, 0.05, 0.10, 0.15, 0.25]:
		var s := await _serbest_olc(sonum)
		print("%-8.2f %10.0f %10.0f %9.0f%%" % [
			sonum, s["bas"], s["tepe"], 100.0 * s["tepe"] / maxf(s["bas"], 1.0)])

func _serbest_olc(sonum: float) -> Dictionary:
	Ayarlar.SALLANMA_SONUMU = sonum
	_kur()
	await get_tree().physics_frame
	_oyuncu.kanca_at_hemen(Vector2.UP)
	# HEDEF_HIZ'e kadar pompala, sonra tusu birak.
	for i in POMPA_KARE:
		_bot_bas()
		await get_tree().physics_frame
		if not _oyuncu.kancali() or _oyuncu.velocity.length() >= HEDEF_HIZ:
			break
	var bas := _oyuncu.velocity.length()
	_oyuncu.bot_yon = 0.0
	# 4 saniye girdisiz salin; tepe hiz SON salinimda olculur (hemen sonrasinda
	# degil), yoksa birakma anindaki hizi olcmus oluruz.
	var tepe := 0.0
	for i in 240:
		await get_tree().physics_frame
		if not _oyuncu.kancali():
			break
		if i >= 180:
			tepe = maxf(tepe, _oyuncu.velocity.length())
	return {"bas": bas, "tepe": tepe}

# --- 3. Birakma -------------------------------------------------------

func _tarama_birakma() -> void:
	print("\n-- 3. BIRAKMA_CARPANI (ivme=1250 sonum=0.05) --")
	print("%-8s %10s %10s %10s" % ["carpan", "birakma", "yatay_px", "sure"])
	Ayarlar.SALLANMA_IVMESI = 1250.0
	Ayarlar.SALLANMA_SONUMU = 0.05
	for carpan: float in [1.00, 1.05, 1.10, 1.15, 1.25]:
		var s := await _birakma_olc(carpan)
		print("%-8.2f %10.0f %10.0f %10.2f" % [carpan, s["hiz"], s["yatay"], s["sure"]])

## Sarkaci pompalar, yayin en dibinde (vy ~ 0, vx > 0) birakir,
## 200 px dusene kadar kat edilen yatay mesafeyi olcer.
func _birakma_olc(carpan: float) -> Dictionary:
	Ayarlar.BIRAKMA_CARPANI = carpan
	_kur()
	await get_tree().physics_frame
	_oyuncu.kanca_at_hemen(Vector2.UP)

	# Hiz tavanina (AZAMI_HIZ) kadar pompalarsak carpanin etkisi kirpilir ve
	# butun satirlar ayni cikar; onun yerine orta bir hizda birakiyoruz.
	for i in POMPA_KARE:
		_bot_bas()
		await get_tree().physics_frame
		if not _oyuncu.kancali() or _oyuncu.velocity.length() >= 420.0:
			break
	# En dipteki saga giden ani bekle.
	for i in 240:
		_bot_bas()
		await get_tree().physics_frame
		if _oyuncu.velocity.x > 0.0 and absf(_oyuncu.velocity.y) < 25.0:
			break
	_oyuncu.bot_yon = 0.0
	_oyuncu.kanca_birak()
	var hiz := _oyuncu.velocity.length()
	var bas := _oyuncu.global_position
	var kare := 0
	for i in 600:
		await get_tree().physics_frame
		kare = i + 1
		if _oyuncu.global_position.y > bas.y + 200.0:
			break
	return {
		"hiz": hiz,
		"yatay": absf(_oyuncu.global_position.x - bas.x),
		"sure": float(kare) / 60.0,
	}

# --- 4. Menzil --------------------------------------------------------

## Menzil sadece "erisebiliyor muyum" degil, "zincir ne kadar bol" sorusu.
## Ortalama komsu sayisi 2'nin altina inerse bolumler dar hissettirir,
## 6'nin ustune cikarsa nisan almak anlamsizlasir.
func _tarama_menzil() -> void:
	print("\n-- 4. KANCA_MENZIL (14 bolum) --")
	print("%-8s %12s %12s %10s" % ["menzil", "ort_komsu", "en_az_komsu", "kopuk"])
	for menzil: float in [180.0, 200.0, 220.0, 240.0, 260.0, 300.0]:
		var toplam := 0
		var adet := 0
		var en_az := 999
		var kopuk := 0
		for no in range(1, Bolumler.sayi() + 1):
			var noktalar := Bolumler.tum_kanca(no)
			for a: Vector2 in noktalar:
				var komsu := 0
				for b: Vector2 in noktalar:
					if a != b and a.distance_to(b) <= menzil:
						komsu += 1
				toplam += komsu
				adet += 1
				en_az = mini(en_az, komsu)
				if komsu == 0:
					kopuk += 1
		print("%-8.0f %12.2f %12d %10d" % [menzil, float(toplam) / float(adet), en_az, kopuk])
