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
## En iyinin bu katindan kotu kosu = bot hatasi, olculmek istenen sey degil.
## v0.3'te 1,5 idi: o botun kosu farki neredeyse tamamen tepki gecikmesindendi.
## v0.4 botu pompaliyor ve ucarken ara noktaya tutunuyor - farkin buyuk kismi
## artik gecikme degil, kotu giden bir ucus ya da olum. Dar filtre esigi yine
## "rotanin verdigi sure"ye yaklastiriyor.
const HATA_PAYI := 1.25
const AYKIRI_KAT := 2.0             ## olcegin bu katindan yavas bolum = bot orada kotu oynadi

## --- v0.4: halat pompasi -------------------------------------------------
## Tani kipi bolum 3'te sunu gosterdi: bot (480,96) noktasina 200 px halatla
## tutunuyor, sarkacin dip noktasi y=296'ya iniyor ve oradaki diken tarlasi
## (y=288) onu olduruyor. Cozum halati kisaltmak - yani oyunun zaten sundugu
## pompa. Bot artik iki sebeple halat boyu degistiriyor:
##   1. GUVENLIK: yay dibi tehlikenin (diken / zemin) uzerinde kalsin.
##   2. HIZ: yay dibinde kisalt (aci momentumu korunur -> tegetsel hiz artar),
##      uclarda guvenli sinira kadar uzat. Worms ninja halati pompasi.
const POMPA_HIZI := 150.0           ## px/sn, botun halat boyu degistirme hizi
const GUVENLI_PAY := 22.0           ## yay dibi tehlikenin bu kadar uzerinde kalsin
const DIP_ESIGI := 0.72             ## capadan asagi birim vektorun y'si bunu asinca "yay dibi"
## Pompa YETERINCE hiz olunca kesilir. Sinirsiz pompalayan ilk surum AZAMI_HIZ'a
## (900) dayaniyor, capa etrafinda tam tur atiyor ve bolum 2'de bitis platformunu
## asip ucurumdan asagi uculuyordu. Insan da ihtiyaci kadar pompalar.
const POMPA_HEDEF_HIZ := 520.0      ## bu hizin ustunde yalniz guvenlik icin kisaltilir

## --- v0.4: rota arama ----------------------------------------------------
## Bot bir rotayi hic bitiremezse rota sucludur, bot degil. En cok oldugu
## dugume ceza yazilip Dijkstra yeniden kosuluyor: ayni graf, farkli yol.
const AZAMI_ROTA_DENEMESI := 4
const DUGUM_CEZASI := 420.0         ## basarisiz dugume eklenen plan maliyeti (px)

## --- v0.4: altin hayalet -------------------------------------------------
## Botun en iyi kosusu 10 Hz ornekle kaydedilir; oyun bunu "altin hayalet"
## olarak oynatir (scripts/hayalet.gd ara degerle 60 Hz'e cikarir).
const IZ_ARALIK_KARE := 6           ## 60 / 6 = 10 Hz

## Tepki gecikmesi araligi (sn): karar anindan eyleme.
const GECIKME_ALT := 0.05
const GECIKME_UST := 0.20

## Madalya carpanlari (gecikmeli koslarin ORTANCASI uzerinden).
##
## Gerekce v0.3'tekiyle AYNI: esik, botun suresi degil, botun suresinin
## uzerine insan payi eklenmis hali. Degisen sey botun kendisi.
##
## v0.3'te bot pompa kullanmiyor, rotayi degistirmiyor ve dusende kendini
## kurtaramiyordu - yani iyi bir oyuncunun kullandigi mekaniklerin bir kismini
## hic kullanmiyordu. O eksiklik payin bir bolumunu zaten kendiliginden
## veriyordu ve x1,25 yetiyordu.
##
## v0.4 botu pompaliyor, basarisiz rotayi degistiriyor ve ucarken ara noktaya
## tutunuyor; sureler bolumune gore %20-50 dustu. Ayni x1,25 artik "hicbir
## pompayi kacirmayan makineyle esles" demek olurdu - v0.3 raporunun Neon
## White uyarisinin ta kendisi. Bu yuzden pay BUYUTULDU: esikler kabaca v0.3
## seviyesinde kaldi, ama artik tahmin degil olculmus kosudan geliyorlar.
const ALTIN_PAY := 1.45
const GUMUS_PAY := 1.95
const BRONZ_PAY := 2.60

## Tani kipi: yalniz ilk bolum, tek kosu, 30 karede bir iz. Calistirma:
##   ... --scene res://tools/rota.tscn -- --tani [bolum_no]
var _tani := false
var _tani_bolum := 1

var _sonuc: Dictionary = {}
## Isleneni bolumde sarkacin dibinin girmemesi gereken dikdortgenler (_guvenli_boy).
var _tehlike: Array[Rect2] = []
## Bitis bayraginin uzerinde durdugu platform (_inise_uygun).
var _bitis_platformu := Rect2()

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
		_tehlikeleri_topla(no)
		var ceza: Dictionary = {}          # kanca nokta indeksi -> ek plan maliyeti
		var rota: Array = []
		var sureler: Array[float] = []
		var iz := PackedVector2Array()
		for deneme in (1 if _tani else AZAMI_ROTA_DENEMESI):
			var yeni_rota := _plan(no, ceza)
			if _tani:
				print("  rota: %s" % str(yeni_rota))
			if yeni_rota.is_empty():
				break
			if deneme > 0 and _ayni_rota(rota, yeni_rota):
				break                      # ceza yol degistirmedi: baska secenek yok
			rota = yeni_rota
			var takilmalar: Array[int] = []
			for k in (1 if _tani else KOSU_SAYISI):
				var sonuc := await _kos(no, rota, k)
				var s: float = sonuc["sure"]
				if s > 0.0:
					sureler.append(s)
					if iz.is_empty() or s <= sureler.min():
						iz = sonuc["iz"]
				else:
					takilmalar.append(int(sonuc["takildi"]))
			if not sureler.is_empty():
				break
			# Hicbir kosu bitmedi: en cok takilinan rota adimini cezalandir.
			var adim := _en_sik(takilmalar)
			var dugum := _dugum_indeksi(no, rota, adim)
			if dugum < 0:
				break
			ceza[dugum] = float(ceza.get(dugum, 0.0)) + DUGUM_CEZASI
			print("bolum %2d  rota denemesi %d basarisiz (adim %d, nokta %s) - yeniden planlaniyor" % [
				no, deneme + 1, adim, str(rota[mini(adim, rota.size() - 1)])])
		if sureler.is_empty():
			printerr("bolum %2d: bot bitiremedi (%d nokta, %d rota denendi)" % [
				no, rota.size(), ceza.size() + 1])
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
			"iz": iz,
		}
		print("bolum %2d  %-16s kosu %d/%d  en iyi %.3f  ortanca %.3f  altin %.3f  nokta %d" % [
			no, Bolumler.ad(no), sureler.size(), KOSU_SAYISI, en_iyi, ortanca,
			ortanca * ALTIN_PAY, rota.size()])
	if _tani:
		# Tani kipi tek bolum kosar; dosyayi yazmak kalan 13 bolumu silerdi.
		print("=== tani bitti (dosya YAZILMADI) ===")
		get_tree().quit(0)
		return
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

## Iki rota ayni mi (ceza yol degistirdi mi?).
func _ayni_rota(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if (a[i] as Vector2).distance_to(b[i]) > 1.0:
			return false
	return true

## Dizideki en sik tekrar eden deger (bos dizide 0).
func _en_sik(degerler: Array[int]) -> int:
	var sayim: Dictionary = {}
	var en := 0
	var en_adet := 0
	for d: int in degerler:
		sayim[d] = int(sayim.get(d, 0)) + 1
		if int(sayim[d]) > en_adet:
			en_adet = int(sayim[d])
			en = d
	return en

## Rotanin adim'inci noktasinin Bolumler.tum_kanca icindeki indeksi (-1 = yok).
func _dugum_indeksi(no: int, rota: Array, adim: int) -> int:
	if rota.is_empty():
		return -1
	var p: Vector2 = rota[clampi(adim, 0, rota.size() - 1)]
	var kanca := Bolumler.tum_kanca(no)
	for i in kanca.size():
		if kanca[i].distance_to(p) < 1.5:
			return i
	return -1

## Baslangictan bitise en dusuk maliyetli kanca zinciri. Bos dizi = bulunamadi.
## ceza: nokta indeksi -> ek maliyet. Bot bir noktada takilip kaldiysa oraya
## ceza yazilir ve ayni graf farkli bir yol uretir.
func _plan(no: int, ceza: Dictionary = {}) -> Array:
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
			maliyet[i] = minf(maliyet[i],
				absf(s.x - basla.x) + uz + HOP_BEDELI + float(ceza.get(i, 0.0)))
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
			var yeni: float = maliyet[en] + uz + HOP_BEDELI + float(ceza.get(j, 0.0))
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

## O bolumde sarkacin dip noktasinin girmemesi gereken dikdortgenler:
## diken (olduren) ve zemin (hizi kesen). Tavan bloklari elenir - yay dibi
## capanin ustune inmez.
func _tehlikeleri_topla(no: int) -> void:
	_tehlike = []
	for r: Rect2 in Bolumler.veri(no)["diken"]:
		_tehlike.append(Bolumler.karola(r))
	for r: Rect2 in Bolumler.zeminler(no):
		_tehlike.append(r)
	# Bitis platformu: bayragin x'ini iceren, hemen altindaki zemin.
	var bitis: Vector2 = Vector2(Bolumler.veri(no)["bitis"])
	_bitis_platformu = Rect2()
	var en_yakin := INF
	for r: Rect2 in Bolumler.zeminler(no):
		if bitis.x < r.position.x or bitis.x > r.end.x:
			continue
		var bosluk := r.position.y - bitis.y
		if bosluk >= 0.0 and bosluk < en_yakin:
			en_yakin = bosluk
			_bitis_platformu = r

## Bu hizla simdi birakilsa bitis platformunun UZERINE mi duser?
##
## Bolum 2'de bot yayin tepesinden 900 px/sn ile birakiyor, platformu asip
## ucurumdan iniyordu. Sarkacin dibinde birakmak ayni hizda cok daha kisa bir
## ucus demek - insan da oyle yapar. Balistik: dy = 0.5*g*t^2 + vy*t.
func _inise_uygun(pos: Vector2, hiz: Vector2, esik := 28.0) -> bool:
	if _bitis_platformu.size == Vector2.ZERO:
		return true
	var dy: float = _bitis_platformu.position.y - OYUNCU_YARI_BOY - pos.y
	if dy <= 0.0:
		return true                     # zaten platform hizasinda ya da altinda
	var g: float = Ayarlar.YERCEKIMI
	var t: float = (-hiz.y + sqrt(maxf(hiz.y * hiz.y + 2.0 * g * dy, 0.0))) / g
	return pos.x + hiz.x * t < _bitis_platformu.end.x - esik

## Capadan asagi guvenle sarkilabilecek en uzun halat.
func _guvenli_boy(capa: Vector2) -> float:
	var boy: float = Ayarlar.KANCA_AZAMI_HALAT
	for r: Rect2 in _tehlike:
		if r.position.y <= capa.y:
			continue
		# Yay capa etrafinda azami halat yaricapinda; o bant disindaki tehlike onemsiz.
		if capa.x < r.position.x - Ayarlar.KANCA_AZAMI_HALAT \
				or capa.x > r.end.x + Ayarlar.KANCA_AZAMI_HALAT:
			continue
		boy = minf(boy, r.position.y - capa.y - GUVENLI_PAY)
	return clampf(boy, Ayarlar.KANCA_ASGARI_HALAT, Ayarlar.KANCA_AZAMI_HALAT)

## Bolumu rotayi izleyerek oynar.
## Donen deger: {"sure": sn (0 = bitiremedi), "takildi": rota adimi, "iz": 10 Hz ornekler}
func _kos(no: int, rota: Array, tohum: int) -> Dictionary:
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
	var iz := PackedVector2Array()
	var olumler: Array[int] = []       # hangi rota adiminda olundu (rota aramasi icin)
	var kurtarma_mi := false           # su anki kanca rota adimi mi, ara kurtarma mi
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
		if kare % IZ_ARALIK_KARE == 0:
			iz.append(pos.round())
		if _tani and kare % 30 == 0:
			print("    k=%4d pos=(%5.0f,%5.0f) v=(%5.0f,%5.0f) |v|=%3.0f kancali=%s hedef=%d/%d %s" % [
				kare, pos.x, pos.y, oyuncu.velocity.x, oyuncu.velocity.y,
				oyuncu.velocity.length(), str(oyuncu.kancali()), hedef_i, rota.size(),
				str(hedef)])

		# Olup kontrol noktasindan dogunca oyuncu geriye isiniyor; rota adimi
		# ileride kalirsa bot bir daha hicbir seye kanca atamiyor.
		if onceki_pos.distance_to(pos) > 200.0 and pos.x < onceki_pos.x:
			olumler.append(hedef_i)
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
			# Kurtarma kancasindayken hedef degismedi: hala ayni rota adimina gidiyoruz.
			var sonraki: Vector2 = hedef
			if not kurtarma_mi:
				sonraki = rota[hedef_i + 1] if hedef_i + 1 < rota.size() \
					else Vector2(Bolumler.veri(no)["bitis"])
			var yon := (sonraki - pos).normalized()
			var hiz := oyuncu.velocity
			var yeterli: bool = hiz.length() >= Ayarlar.BIRAKMA_ESIGI
			# Pompala: tegetsel hizin isaretine bas (sarkaci buyutmenin dogru
			# yolu; tools/olcum.gd de ayni seyi yapiyor).
			oyuncu.bot_yon = signf(hiz.dot(teget))
			# Halat pompasi (v0.4). Once GUVENLIK: yay dibi dikenin/zeminin
			# ustunde kalsin - bolum 3'te bot tam da bu yuzden oluyordu.
			# Sonra HIZ: dipte kisalt (aci momentumu korunur), uclarda uzat.
			var guvenli := _guvenli_boy(capa)
			var adim := POMPA_HIZI * dt
			if oyuncu.halat_boyu > guvenli:
				oyuncu.halat_degistir(-minf(adim * 3.0, oyuncu.halat_boyu - guvenli))
			elif hiz.length() >= POMPA_HEDEF_HIZ:
				pass                        # yeterince hizli: pompalamayi birak
			elif disa.y > DIP_ESIGI:
				oyuncu.halat_degistir(-minf(adim, oyuncu.halat_boyu - Ayarlar.KANCA_ASGARI_HALAT))
			else:
				oyuncu.halat_degistir(minf(adim, guvenli - oyuncu.halat_boyu))
			# Birakma: yeterince hizli, yon sonraki hedefe donuk, capayi gecmis
			# ve asagi dalmiyor. Denenen alternatifler daha kotu sonuc verdi:
			#   - hedefe dogru sabit girdi        -> 3/14 bolum
			#   - yalniz yukselirken birakma      -> 1/14 bolum
			#   - capa sarti olmadan              -> sarkac tam tur donuyor
			var uygun: bool = yeterli \
				and hiz.normalized().dot(yon) > 0.55 \
				and pos.x > capa.x - 8.0 \
				and hiz.y < 40.0
			# Son hedef bitis ise: platformu asacak bir birakis uygun degil.
			if uygun and hedef_i >= rota.size() and not _inise_uygun(pos, hiz):
				uygun = false
			# Zorunlu birakma: uygun an hic gelmezse takili kalma.
			if gecikme <= 0.0 and (uygun or tutma > TUTMA_SINIRI):
				oyuncu.kanca_birak()
				oyuncu.bot_yon = 1.0
				if not kurtarma_mi:
					hedef_i += 1
				kurtarma_mi = false
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
				kurtarma_mi = false
				gecikme = rastgele.randf_range(GECIKME_ALT, GECIKME_UST)
		elif oyuncu.is_on_floor():
			oyuncu.velocity.y = -Ayarlar.ZIPLA_GUCU
		elif oyuncu.velocity.y > 0.0:
			# KURTARMA KANCASI (v0.4): rota adimi henuz menzilde degil ve bot
			# dusuyor. Oyuncunun yaptigi sey: ileri nisan al, yolda ne varsa
			# yakala. Rotayi degistirmez - ayni adima ara bir noktadan gider.
			# Bolum 3'te bot tam burada oluyordu: (480,96)'dan birakip 400 px
			# uzaktaki (880,112)'ye ulasamadan diken tarlasina dusuyordu.
			# Bitise ucarken BITISTEN OTEDEKI noktaya tutunmak yasak: bolum 9'da
			# bot son bosluga dusuyor, bolum 2'de bitis platformunu asip
			# ucurumdan iniyordu. Gerideki noktaya tutunmak ise kurtarir.
			var son_hedef: bool = hedef_i >= rota.size()
			var ara := oyuncu.en_iyi_nokta((hedef - pos).normalized())
			if ara != null and ara.global_position.x > pos.x - 24.0 \
					and (not son_hedef or ara.global_position.x < hedef.x - 32.0) \
					and oyuncu.kanca_at((ara.global_position - pos).normalized()):
				kurtarma_mi = true
				gecikme = rastgele.randf_range(GECIKME_ALT, GECIKME_UST)

	bolum.free()
	await get_tree().physics_frame
	# takildi: bitiremediyse en cok olunen rota adimi (yoksa ulasilan adim).
	return {
		"sure": float(kare) / 60.0 if bitti else 0.0,
		"takildi": _en_sik(olumler) if not olumler.is_empty() else hedef_i,
		"iz": iz,
	}

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
		# Altin hayaletin izi 10 Hz; tam sayiya yuvarlanmis, satir sonunda.
		# DUZ DIZI olarak yaziliyor: PackedVector2Array([...]) sabit ifade
		# sayilmiyor, const blogunu parse edilemez hale getiriyor (v0.4 tuzagi).
		# RotaVerisi.iz() okurken donusturuyor.
		var iz := PackedStringArray()
		for p: Vector2 in s.get("iz", PackedVector2Array()):
			iz.append("Vector2(%d, %d)" % [int(p.x), int(p.y)])
		satirlar.append("\t%d: {\"sure\": %.3f, \"ortanca\": %.3f, \"tahmin\": %s, \"madalya\": [%.3f, %.3f, %.3f], \"nokta\": [%s], \"iz\": [%s]}," % [
			no, s["sure"], s["ortanca"], "true" if tahmin else "false",
			m[0], m[1], m[2], ", ".join(noktalar), ", ".join(iz)])

	# Basarisiz bir kosu var olan veriyi SILMESIN: bos sonucla yazmak,
	# bir parse hatasi yuzunden RotaVerisi cokunce butun dosyayi bosaltiyordu.
	if satirlar.is_empty():
		printerr("hicbir bolum uretilemedi - %s DOKUNULMADI" % CIKTI)
		return
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
