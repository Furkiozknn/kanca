extends Node2D
## Rota planlayici + otomatik oynayan bot. Madalya surelerini ve rota ipucunu uretir.
##
##   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --fixed-fps 60 --path . --scene res://tools/rota.tscn
##
## --fixed-fps 60 SART: headless'ta bile fizik kareleri GERCEK zamanda akiyor
## (60 Hz), yani 2700 karelik bir kosu 45 saniye surer ve 14 bolum x 5 kosu
## bir saati bulur. --fixed-fps zamani gercek saatten koparir, ayni kare
## sayisi saniyeler icinde biter; olculen sure zaten kare sayisindan geliyor.
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
const TUTMA_SINIRI := 2.5           ## uygun an gelmezse bu kadar sonra yine de birak
const HATA_PAYI := 1.5              ## en iyinin bu katindan kotu kosu = bot hatasi
const AYKIRI_KAT := 2.0             ## olcegin bu katindan yavas bolum = bot orada kotu oynadi

## Tepki gecikmesi araligi (sn): karar anindan eyleme.
const GECIKME_ALT := 0.05
const GECIKME_UST := 0.20

## Madalya carpanlari (gecikmeli koslarin ORTANCASI uzerinden).
##
## Bot hicbir kancayi kacirmiyor ve birakma anini hep tutturuyor; buna karsilik
## halat pompasini kullanmiyor ve rotayi degistirmiyor. Yani "iyi ama mukemmel
## olmayan" bir kosu. Altini bot suresine yapistirmak (x1,08) insana "makineyle
## esles" demek olurdu - Neon White'in gelistiricilerinin dustugu tuzak.
## Altin rotayi bilen bir oyuncuya dortte bir pay birakiyor.
const ALTIN_PAY := 1.25
const GUMUS_PAY := 1.70
const BRONZ_PAY := 2.30

## Tani kipi: yalniz ilk bolum, tek kosu, 30 karede bir iz. Calistirma:
##   ... --scene res://tools/rota.tscn -- --tani [bolum_no]
var _tani := false
var _tani_bolum := 1

var _sonuc: Dictionary = {}

func _ready() -> void:
	_calistir()

func _calistir() -> void:
	await get_tree().process_frame
	var kullanici := OS.get_cmdline_user_args()
	_tani = kullanici.has("--tani")
	for i in kullanici.size():
		if kullanici[i] == "--tani" and i + 1 < kullanici.size():
			_tani_bolum = int(kullanici[i + 1])
	print("=== Kanca rota + bot kosusu ===")
	print("bolum basina %d kosu, tepki gecikmesi %.2f-%.2f sn, azami %d kare" % [
		KOSU_SAYISI, GECIKME_ALT, GECIKME_UST, AZAMI_KARE])
	var bolumler := range(1, Bolumler.sayi() + 1)
	if _tani:
		bolumler = [_tani_bolum]
		print("TANI KIPI: yalniz bolum %d, tek kosu" % _tani_bolum)
	for no in bolumler:
		var rota := _plan(no)
		if _tani:
			print("  rota: %s" % str(rota))
		if rota.is_empty():
			printerr("bolum %d: rota bulunamadi" % no)
			continue
		var sureler: Array[float] = []
		for k in (1 if _tani else KOSU_SAYISI):
			var s := await _kos(no, rota, k)
			if s > 0.0:
				sureler.append(s)
		if sureler.is_empty():
			printerr("bolum %2d: bot bitiremedi (%d nokta)" % [no, rota.size()])
			continue
		sureler.sort()
		var en_iyi: float = sureler[0]
		# Tepki gecikmesi kosuyu birkac yuzde uzatir; kacirilan kanca ya da
		# olum kat kat uzatir. En iyinin HATA_PAYI katindan kotu kosular bot
		# hatasidir, olculmek istenen sey degil - ortancaya girmesinler.
		var temiz: Array[float] = []
		for t: float in sureler:
			if t <= en_iyi * HATA_PAYI:
				temiz.append(t)
		var ortanca: float = temiz[temiz.size() / 2]
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
	_tahmin_et()
	_yaz()
	print("=== rota bitti: %d/%d bolum ===" % [_sonuc.size(), Bolumler.sayi()])
	get_tree().quit(0 if _sonuc.size() == Bolumler.sayi() else 1)

## Botun bitiremedigi bolumler icin sure TAHMINI.
##
## Bot kosan bolumlerden "rota px'i basina saniye" olculur; bitiremedigi
## bolumun suresi kendi rota uzunlugundan cikarilir. Boylece esikler yine
## olculmus fizige dayanir (bolum uzunlugu / sabit hiz formulu degil), ama
## o bolumde gercekten kosulmus degildir - kayitta "tahmin": true ile isaretli.
func _tahmin_et() -> void:
	# Bolum basina sn/px oranlarinin ORTANCASI. Toplam/toplam kullanmak, botun
	# takildigi tek bir bolumun butun olcegi kaydirmasina yol aciyordu.
	var oranlar: Array[float] = []
	for no: int in _sonuc:
		var uz := _rota_uzunlugu(no, _sonuc[no]["nokta"])
		if uz > 1.0:
			oranlar.append(float(_sonuc[no]["ortanca"]) / uz)
	if oranlar.is_empty():
		printerr("tahmin yapilamadi: hicbir bolum bitirilemedi")
		return
	oranlar.sort()
	var sn_px: float = oranlar[oranlar.size() / 2]
	print("\ntahmin olcegi: %.5f sn/px (%d bolumun ortancasi, %.5f - %.5f)" % [
		sn_px, oranlar.size(), oranlar[0], oranlar[oranlar.size() - 1]])

	# Bitirdigi halde ortanca olcegin AYKIRI_KAT katindan yavas kalan bolumler:
	# bot orada gercekten kotu oynamis (kacirilan kanca, tekrar tekrar olum).
	# O sureyi altin esigi yapmak bolumu bedava altin haline getirir - onlar da
	# tahmine devrediliyor.
	for no: int in _sonuc.keys():
		var uz := _rota_uzunlugu(no, _sonuc[no]["nokta"])
		if uz > 1.0 and float(_sonuc[no]["ortanca"]) / uz > sn_px * AYKIRI_KAT:
			print("bolum %2d  ortanca %.3f olcegin %.1f kati - tahmine devrediliyor" % [
				no, float(_sonuc[no]["ortanca"]),
				(float(_sonuc[no]["ortanca"]) / uz) / sn_px])
			_sonuc.erase(no)

	for no in range(1, Bolumler.sayi() + 1):
		if _sonuc.has(no):
			continue
		var rota := _plan(no)
		if rota.is_empty():
			continue
		var sure: float = _rota_uzunlugu(no, rota) * sn_px
		_sonuc[no] = {
			"sure": snappedf(sure, 0.001),
			"ortanca": snappedf(sure, 0.001),
			"tahmin": true,
			"madalya": [
				snappedf(sure * ALTIN_PAY, 0.001),
				snappedf(sure * GUMUS_PAY, 0.001),
				snappedf(sure * BRONZ_PAY, 0.001),
			],
			"nokta": rota,
		}
		print("bolum %2d  %-16s TAHMIN  %.3f  altin %.3f  nokta %d" % [
			no, Bolumler.ad(no), sure, sure * ALTIN_PAY, rota.size()])

## Baslangic -> rota noktalari -> bitis toplam yatay yolu (px).
func _rota_uzunlugu(no: int, rota: Array) -> float:
	var d := Bolumler.veri(no)
	var yer: Vector2 = Vector2(d["basla"])
	var toplam := 0.0
	for p: Vector2 in rota:
		toplam += yer.distance_to(p)
		yer = p
	toplam += yer.distance_to(Vector2(d["bitis"]))
	return toplam

# --- 1. Plan ----------------------------------------------------------

## Oyuncunun uzerinde durabilecegi platformun ust yuzeyinden ornek noktalar.
## Kanca ilk atista baslangic noktasindan degil, platformda kosarken atiliyor -
## bu yuzden grafin kaynagi tek nokta degil, platformun tamami.
func _platform_ornekleri(p: Vector2, zeminler: Array[Rect2]) -> Array:
	var altimdaki := Rect2()
	var en_yakin := INF
	for r: Rect2 in zeminler:
		if p.x < r.position.x - 1.0 or p.x > r.end.x + 1.0:
			continue
		var bosluk := r.position.y - p.y
		if bosluk < -1.0 or bosluk >= en_yakin:
			continue
		en_yakin = bosluk
		altimdaki = r
	if en_yakin == INF:
		return [p - Vector2(0, OYUNCU_YARI_BOY + ZIPLA_YUKSEKLIGI)]
	var y := altimdaki.position.y - OYUNCU_YARI_BOY - ZIPLA_YUKSEKLIGI
	var ornekler: Array = []
	var x := altimdaki.position.x
	while x <= altimdaki.end.x:
		ornekler.append(Vector2(x, y))
		x += 16.0
	return ornekler

## Baslangictan bitise en dusuk maliyetli kanca zinciri. Bos dizi = bulunamadi.
func _plan(no: int) -> Array:
	var d := Bolumler.veri(no)
	var kanca := Bolumler.tum_kanca(no)
	var zeminler := Bolumler.zeminler(no)
	var basla: Vector2 = Vector2(d["basla"])
	var bitis: Vector2 = Vector2(d["bitis"])
	var bas_ornek := _platform_ornekleri(basla, zeminler)
	var son_ornek := _platform_ornekleri(bitis, zeminler)
	var zincir: float = Ayarlar.KANCA_MENZIL + Ayarlar.KANCA_AZAMI_HALAT * 0.7

	# Dijkstra: dugumler kanca noktalari. Kaynak = baslangic platformunun
	# uzerinden erisilen her nokta (maliyet = kosu mesafesi + kanca mesafesi).
	var maliyet: Array[float] = []
	var onceki: Array[int] = []
	maliyet.resize(kanca.size())
	onceki.resize(kanca.size())
	for i in kanca.size():
		maliyet[i] = INF
		onceki[i] = -1
		for s: Vector2 in bas_ornek:
			var uz := s.distance_to(kanca[i])
			if uz > Ayarlar.KANCA_MENZIL or not Bolumler.gorus_var(s, kanca[i], zeminler):
				continue
			maliyet[i] = minf(maliyet[i], absf(s.x - basla.x) + uz + HOP_BEDELI)
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

	# Hedef: bitis platformunun uzerine inilebilen son kanca noktasi
	# (bayraga degil platforma inilir, sonra kosulur).
	var son := -1
	var en_iyi := INF
	for i in kanca.size():
		if maliyet[i] == INF:
			continue
		for s: Vector2 in son_ornek:
			var uz := kanca[i].distance_to(s)
			if uz > INIS_MESAFESI:
				continue
			var toplam: float = maliyet[i] + uz + absf(bitis.x - s.x)
			if toplam < en_iyi:
				en_iyi = toplam
				son = i
	if son == -1:
		printerr("  bolum %d: %d noktanin hicbirinden bitis platformuna inilemiyor" % [
			no, kanca.size()])
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
	var onceki_pos: Vector2 = oyuncu.global_position
	while kare < AZAMI_KARE:
		await get_tree().physics_frame
		kare += 1
		# Bolum._dogur() olumden sonra girdi_aktif'i geri aciyor; bot o zaman
		# klavyeyi (bos) okumaya baslayip yerinde ziplamaya basliyor.
		oyuncu.girdi_aktif = false
		if bool(bolum.get("_bitti")):
			bitti = true
			break
		var dt := 1.0 / 60.0
		gecikme = maxf(gecikme - dt, 0.0)
		var hedef: Vector2 = rota[mini(hedef_i, rota.size() - 1)] if hedef_i < rota.size() \
			else Vector2(Bolumler.veri(no)["bitis"])
		var pos: Vector2 = oyuncu.global_position
		if _tani and kare % 30 == 0:
			print("    k=%4d pos=(%5.0f,%5.0f) v=(%5.0f,%5.0f) |v|=%3.0f kancali=%s hedef=%d/%d %s" % [
				kare, pos.x, pos.y, oyuncu.velocity.x, oyuncu.velocity.y,
				oyuncu.velocity.length(), str(oyuncu.kancali()), hedef_i, rota.size(),
				str(hedef)])

		# Olup kontrol noktasindan dogunca oyuncu geriye isiniyor; rota adimi
		# ileride kalirsa bot bir daha hicbir seye kanca atamiyor.
		if onceki_pos.distance_to(pos) > 200.0 and pos.x < onceki_pos.x:
			hedef_i = _rota_hizala(rota, pos)
			gecikme = rastgele.randf_range(GECIKME_ALT, GECIKME_UST)
		onceki_pos = pos

		if oyuncu.kancali():
			tutma += dt
			var capa: Vector2 = oyuncu.kanca_nokta.global_position
			var disa := (pos - capa).normalized()
			var teget := Vector2(-disa.y, disa.x)
			if teget.x < 0.0:
				teget = -teget
			var sonraki: Vector2 = rota[hedef_i + 1] if hedef_i + 1 < rota.size() \
				else Vector2(Bolumler.veri(no)["bitis"])
			var yon := (sonraki - pos).normalized()
			var hiz := oyuncu.velocity
			var yeterli: bool = hiz.length() >= Ayarlar.BIRAKMA_ESIGI
			# Pompala: tegetsel hizin isaretine bas (sarkaci buyutmenin dogru
			# yolu; tools/olcum.gd de ayni seyi yapiyor).
			oyuncu.bot_yon = signf(hiz.dot(teget))
			# Birakma: yeterince hizli, yon sonraki hedefe donuk, capayi gecmis
			# ve asagi dalmiyor. Denenen alternatifler daha kotu sonuc verdi:
			#   - hedefe dogru sabit girdi        -> 3/14 bolum
			#   - yalniz yukselirken birakma      -> 1/14 bolum
			#   - capa sarti olmadan              -> sarkac tam tur donuyor
			var uygun: bool = yeterli \
				and hiz.normalized().dot(yon) > 0.55 \
				and pos.x > capa.x - 8.0 \
				and hiz.y < 40.0
			# Zorunlu birakma: uygun an hic gelmezse takili kalma.
			if gecikme <= 0.0 and (uygun or tutma > TUTMA_SINIRI):
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

## Olumden sonra: oyuncunun onundeki ilk rota adimina don.
func _rota_hizala(rota: Array, pos: Vector2) -> int:
	for i in rota.size():
		if (rota[i] as Vector2).x >= pos.x - 40.0:
			return i
	return maxi(rota.size() - 1, 0)

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
		var tahmin: bool = bool(s.get("tahmin", false))
		satirlar.append("\t%d: {\"sure\": %.3f, \"ortanca\": %.3f, \"tahmin\": %s, \"madalya\": [%.3f, %.3f, %.3f], \"nokta\": [%s]}," % [
			no, s["sure"], s["ortanca"], "true" if tahmin else "false",
			m[0], m[1], m[2], ", ".join(noktalar)])

	var f := FileAccess.open(CIKTI, FileAccess.READ)
	if f == null:
		printerr("rota_verisi.gd okunamadi")
		return
	var metin := f.get_as_text()
	f.close()
	var bas := metin.find("const VERI := {")
	# Kapanis parantezi SATIR BASINDA olan "}" - satir ici sozluklerin "}"
	# karakterleri araya girmesin (ilk surumde dosyayi boyle bozdu).
	var son := metin.find("\n}", bas)
	if bas < 0 or son < 0:
		printerr("rota_verisi.gd icinde VERI bloku bulunamadi")
		return
	var yeni := "const VERI := {\n%s" % "\n".join(satirlar)
	metin = metin.substr(0, bas) + yeni + metin.substr(son)
	var y := FileAccess.open(CIKTI, FileAccess.WRITE)
	y.store_string(metin)
	y.close()
	print("yazildi: %s (%d bolum)" % [CIKTI, satirlar.size()])
