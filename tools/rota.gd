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
##
## `--denetle`: DOSYA YAZMAZ, yazilmis olani SINAR. Esikler uretilmis dosyada
## duruyor ve 115 dogrulamanin ilgili kismi onlari o dosyaya karsi siniyor --
## yani dosyayi kendisine karsi. Bir bolumun kanca noktalari ya da zemini
## degisirse dosya eski kalir, testler yine yesil yanar, ve yayimlanan altin
## esigi artik botun bile yetisemedigi bir sure olabilir. Denetim botu yeniden
## kosturup iki seyi soruyor: her bolum hala bitiyor mu, ve yayimlanan altin
## esigi botun BUGUNKU ortancasindan buyuk mu. Tutmazsa cikis kodu 1.

const CIKTI := "res://scripts/rota_verisi.gd"
const KOSU_SAYISI := 5              ## bolum basina deneme (farkli gecikme tohumlari)
const AZAMI_KARE := 2700            ## 45 saniye sim suresi; asilirsa basarisiz
const OYUNCU_YARI_BOY := 14.0
const ZIPLA_YUKSEKLIGI := 45.0
const INIS_MESAFESI := 300.0        ## son noktadan bitise inilebilecek mesafe (ust sinir)
## Son suzulusun kurtarmasi yok; alcak bir kancadan uzun suzulus fizikte
## tutmuyor. Izin verilen mesafe kancanin platform ustundeki yuksekligiyle
## buyur: 100 + 1,5 * yukseklik (en cok INIS_MESAFESI). Bolum 7'de (1664,240)
## platformdan 64 px yukarida, 240 px uzakta: bot her kosuda oraya dusuyordu.
const INIS_TABAN := 100.0
const INIS_YUKSEKLIK_KATI := 1.5
const BAYRAK_YARI_BOY := 28.0       ## bitis alani 24x56 (Bolum._bayrak_yap)
const INIS_PAYI := 40.0             ## bayragin bu kadar onune inis = kosarak girer
const INIS_KENAR_PAYI := 12.0       ## platformun on kenarina pay (yari genislik + tahmin payi)
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

## --- v0.5: hareketli noktada bekleme + hiz freni -------------------------
## Bot planlanan (statik) noktaya nisan aliyordu; hareketli nokta planda orta
## noktasiyla durur ama gercekte +-64 px salinir. Nokta uzaktayken "menzil
## disi" sayilip platformdan atlaniyor ve bosluga dusuluyordu (bolum 6).
## Simdi hedef canli dugumun O ANKI konumu; salinimin bir ucu menzile
## giriyorsa bot platform kenarinda BEKLER (en cok BEKLEME_SINIRI sn).
const BEKLEME_SINIRI := 6.0         ## hareketli noktayi bu kadar bekle, sonra yine de atla
const KENAR_PAYI := 26.0            ## platform kenarina bu kadar kala beklerken dur
## Yuksek hizda bot savruluyordu: bolum 2'de bitis platformunu asiyor, bolum
## 7'de dar gecitte tavana/zemine surtuyordu. Insanin yaptigi iki fren:
## salinima TERS basmak ve halati UZATMAK. Uzatmak bu oyunda gercekten
## yavaslatir - halat yeniden gerildiginde sert kisit kalan radyal hizi
## siliyor (Oyuncu._halat_kisiti). Fren, birakmaya uygun anda calismaz.
## Genel hiz freni OLCUMDE ZARARLI cikti ve kapatildi (esik = azami hiz,
## hicbir zaman asilmaz). 720 ile 14 bolumun ortalamasi %34 yavasladi
## (olcek 0,00279 -> 0,00373); 840 ile bile 900 px/sn'de giden bot dipte
## ters basip birakis hizini kaybediyor, sonraki platforma 6 px kisa dusuyordu
## (bolum 6: 1786/1792, bolum 8: 714/720, 1306/1312 - tani izleri). Fren
## artik yalniz bitise INILEMEYECEK KADAR HIZLI yaklasirken calisir.
const FREN_HIZI := 900.0            ## = Ayarlar.AZAMI_HIZ (autoload sabiti const ifadesinde kullanilamaz)

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
var _denetle := false              ## yazilmis esikleri yeniden olcup sinar, dosya yazmaz
var _tani_bolum := 1

var _sonuc: Dictionary = {}
## Isleneni bolumde sarkacin dibinin girmemesi gereken dikdortgenler (_guvenli_boy).
var _tehlike: Array[Rect2] = []
## Bitis bayraginin uzerinde durdugu platform (_inise_uygun).
var _bitis_platformu := Rect2()
var _bitis_x := 0.0
var _bitis_y := 0.0
## Yalniz OLDUREN dikenler (_diken_altta: frende halat uzatma yasagi).
var _diken: Array[Rect2] = []
## Islenen bolumun karolanmis zeminleri (_kenarda: beklerken ucuruma kosmamak).
var _zeminler: Array[Rect2] = []

func _ready() -> void:
	_calistir()

func _calistir() -> void:
	# Bot gercek bolumleri bitiriyor: Bolum bitise deginde rekor, hayalet ve
	# acilan bolumu OYUNCUNUN kaydina yazardi (v0.3'ten beri). Artik yazmaz.
	Kayit.salt_okunur = true
	await get_tree().process_frame
	var kullanici := OS.get_cmdline_user_args()
	_tani = kullanici.has("--tani")
	_denetle = kullanici.has("--denetle")
	if _denetle:
		print("DENETIM KIPI: dosya yazilmaz, yazilmis esikler yeniden olculup sinanir")
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
				# Kosu basina tek satir: rapor "hangi kosu neden yavas" diyebilsin.
				print("  bolum %2d kosu %d: %s  olum %d  takildi adim %d" % [
					no, k, ("%.3f" % s) if s > 0.0 else "BITMEDI",
					int(sonuc["olum"]), int(sonuc["takildi"])])
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
	if _denetle:
		var kod := _denetle_et()
		print("=== denetim bitti: %d/%d bolum kosuldu ===" % [_sonuc.size(), Bolumler.sayi()])
		get_tree().quit(kod)
		return
	_tahmin_et()
	_yaz()
	print("=== rota bitti: %d/%d bolum ===" % [_sonuc.size(), Bolumler.sayi()])
	get_tree().quit(0 if _sonuc.size() == Bolumler.sayi() else 1)


## Yayimlanan esikleri BUGUNKU kosuya karsi sinar. Donus: cikis kodu.
##
## `_tahmin_et` ve `_yaz` cagrilmaz: bu kip olcer ve soyler, duzeltmez.
## Duzeltme, botu normal kipte kosturup uretilen dosyayi commit etmektir.
func _denetle_et() -> int:
	var hata := 0
	print("\n--- denetim: yayimlanan esik vs bugunku kosu ---")
	print("%-3s %-18s %8s %8s %8s  %s" % ["no", "bolum", "altin", "bugun", "pay", "durum"])
	for no in range(1, Bolumler.sayi() + 1):
		var ad := Bolumler.ad(no)
		var m := RotaVerisi.madalya(no)
		var altin: float = float(m[0]) if m.size() == 3 else 0.0
		if not _sonuc.has(no):
			hata += 1
			print("%-3d %-18s %8.2f %8s %8s  BITIREMEDI" % [no, ad, altin, "-", "-"])
			continue
		var bugun: float = float(_sonuc[no]["ortanca"])
		var durum := "ok"
		if altin <= 0.0:
			durum = "ESIK YOK"
			hata += 1
		elif bugun > altin:
			durum = "ALTIN ULASILAMAZ"
			hata += 1
		elif RotaVerisi.tahmin_mi(no):
			durum = "ok (esik tahmin)"
		print("%-3d %-18s %8.2f %8.2f %8.2f  %s" % [no, ad, altin, bugun, altin - bugun, durum])
	if hata == 0:
		print("\ndenetim temiz: %d bolumun hepsi bitiyor, her altin esigi botun bugunku ortancasini kaldiriyor." % Bolumler.sayi())
		return 0
	print("\nDENETIM BASARISIZ: %d bulgu." % hata)
	print("Esikler scripts/rota_verisi.gd icinde ve elle duzeltilmez: botu")
	print("normal kipte kosturup uretilen dosyayi commit et.")
	return 1

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
	# Devredilen bolumun OLCULEN ortancasi atilmiyor: tahmin ondan hizli
	# olabilir (zaten amaci o -- bot orada kotu oynamisti), ama altin esigi
	# ondan hizli OLAMAZ. Olursa, bolumu oynayan tek sey olan botun bile
	# yetisemedigi bir altin yayimlamis oluruz. 5. bolumde tam bu olmustu:
	# olculen ortanca 11,10 sn, yayimlanan altin 7,55 sn.
	var gozlenen := {}
	for no: int in _sonuc.keys():
		var uz := _rota_uzunlugu(no, _sonuc[no]["nokta"])
		if uz > 1.0 and float(_sonuc[no]["ortanca"]) / uz > sn_px * AYKIRI_KAT:
			print("bolum %2d  ortanca %.3f olcegin %.1f kati - tahmine devrediliyor" % [
				no, float(_sonuc[no]["ortanca"]),
				(float(_sonuc[no]["ortanca"]) / uz) / sn_px])
			gozlenen[no] = float(_sonuc[no]["ortanca"])
			_sonuc.erase(no)

	for no in range(1, Bolumler.sayi() + 1):
		if _sonuc.has(no):
			continue
		var rota := _plan(no)
		if rota.is_empty():
			continue
		var sure: float = _rota_uzunlugu(no, rota) * sn_px
		# Altin tabani: gozlenen ortancadan hizli bir altin yayimlanmaz.
		if gozlenen.has(no) and sure * ALTIN_PAY < float(gozlenen[no]):
			var eski := sure
			sure = float(gozlenen[no]) / ALTIN_PAY
			print("bolum %2d  tahmin %.3f -> %.3f (altin %.3f, gozlenen ortanca %.3f'in altina inemez)" % [
				no, eski, sure, sure * ALTIN_PAY, float(gozlenen[no])])
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
			var yukseklik: float = s.y + OYUNCU_YARI_BOY + ZIPLA_YUKSEKLIGI - kanca[i].y
			if uz > minf(INIS_MESAFESI, INIS_TABAN + INIS_YUKSEKLIK_KATI * yukseklik):
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
	_diken = []
	_zeminler = Bolumler.zeminler(no)
	for r: Rect2 in Bolumler.veri(no)["diken"]:
		_tehlike.append(Bolumler.karola(r))
		_diken.append(Bolumler.karola(r))
	for r: Rect2 in _zeminler:
		_tehlike.append(r)
	# Bitis platformu: bayragin x'ini iceren, hemen altindaki zemin.
	var bitis: Vector2 = Vector2(Bolumler.veri(no)["bitis"])
	_bitis_x = bitis.x
	_bitis_y = bitis.y
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
##
## v0.5 tani kipi (bolum 2) iki eksik gosterdi: (1) hiz, birakma bonusu
## (x1,10) UYGULANMADAN veriliyordu - ucus %10 uzun cikiyordu; cagiran
## artik bonuslu hizi veriyor. (2) Inisten sonra durma mesafesi yoktu: bot
## bayragin otesine 487 px/sn ile inip kenardan asagi kosuyordu. Durma
## mesafesi (v^2 / 2a) da platforma sigmali.
## Donen deger: INIS_UYGUN, INIS_KISA (platforma yetismez, daha uzun
## salinim gerek - FRENLEME) ya da INIS_UZUN (asar, frenle).
enum { INIS_UYGUN, INIS_KISA, INIS_UZUN }

func _inise_uygun(pos: Vector2, hiz: Vector2, esik := 28.0) -> bool:
	return _inis(pos, hiz, esik) == INIS_UYGUN

func _inis(pos: Vector2, hiz: Vector2, esik := 28.0) -> int:
	if _bitis_platformu.size == Vector2.ZERO:
		return INIS_UYGUN
	var dy: float = _bitis_platformu.position.y - OYUNCU_YARI_BOY - pos.y
	if dy <= 0.0:
		return INIS_UYGUN               # zaten platform hizasinda ya da altinda
	var g: float = Ayarlar.YERCEKIMI
	var t: float = (-hiz.y + sqrt(maxf(hiz.y * hiz.y + 2.0 * g * dy, 0.0))) / g
	# Ucus bayragin alanindan (24x56) geciyorsa bolum HAVADA biter, inis yeri
	# onemsiz. v0.4 botunun hizli ve alcak birakislari boyle bitiyordu; durma
	# mesafesini her inise ekleyen ilk surum bunu yasaklayip botu 5, 8 ve 9.
	# bolumde 2,5 sn'lik "zorunlu birak - ayni noktaya tutun" dongusune soktu.
	if hiz.x > 1.0:
		var tb: float = (_bitis_x - pos.x) / hiz.x
		if tb >= 0.0 and tb <= t:
			var yb: float = pos.y + hiz.y * tb + 0.5 * g * tb * tb
			if absf(yb - _bitis_y) <= BAYRAK_YARI_BOY + OYUNCU_YARI_BOY:
				return INIS_UYGUN
	var inis: float = pos.x + hiz.x * t
	# Platforma yetismiyorsa (bosluga iner) birakma - ama FRENLEME de: daha
	# uzun salinim lazim. Bu alt sinir yoktu; bot 6. bolumde bosluga (1700),
	# 9. bolumde ruzgar cukuruna birakip 16 sn suruklenmisti (4. deneme).
	if inis < _bitis_platformu.position.x + INIS_KENAR_PAYI:
		return INIS_KISA
	# Bayragin ONUNE inen bot kosarak bayraga girer; tahmin payi INIS_PAYI.
	if inis <= _bitis_x - INIS_PAYI:
		return INIS_UYGUN
	# Otesine inince durup geri donmesi gerekir: durma mesafesi (v^2/2a) da
	# platforma sigmali. Bolum 2'de bot 487 px/sn ile kenardan asagi kosuyordu.
	inis += hiz.x * hiz.x / (2.0 * Ayarlar.IVME)
	return INIS_UYGUN if inis < _bitis_platformu.end.x - esik else INIS_UZUN

## Birakinca oyuncunun gercekten alacagi hiz (Oyuncu.kanca_birak ile ayni).
func _birakma_hizi(hiz: Vector2) -> Vector2:
	if hiz.length() >= Ayarlar.BIRAKMA_ESIGI:
		return (hiz * Ayarlar.BIRAKMA_CARPANI).limit_length(Ayarlar.AZAMI_HIZ)
	return hiz

## Planlanan rota noktasina karsilik gelen CANLI kanca dugumu (yoksa null).
## Hareketli nokta plana orta noktasiyla girer (Bolumler.tum_kanca).
func _dugum_bul(bolum: Node, p: Vector2) -> Node2D:
	for n in bolum.get_tree().get_nodes_in_group(KancaNoktasi.GRUP):
		var k := n as KancaNoktasi
		if k == null:
			continue
		var yer: Vector2 = (k.a + k.b) * 0.5 if k.tur == KancaNoktasi.TUR_HAREKETLI \
			else k.global_position
		if yer.distance_to(p) < 1.5:
			return k
	return null

## Hareketli hedef salinimin bir ucunda menzile giriyorsa beklemeye deger:
## nokta bize gelecek, atlamaya gerek yok.
func _beklemeye_deger(n: Variant, pos: Vector2) -> bool:
	# Tipsiz parametre: olumden sonra bolum noktalari yeniden kurar, eski
	# dugum serbest birakilmis olur - tipli parametre orada SCRIPT ERROR verip
	# botu (ve quit'i) oldurdu, Godot sonsuza kadar bos dondu (v0.5 tuzagi).
	if not is_instance_valid(n):
		return false
	var k := n as KancaNoktasi
	if k == null or k.tur != KancaNoktasi.TUR_HAREKETLI:
		return false
	return minf(pos.distance_to(k.a), pos.distance_to(k.b)) <= Ayarlar.KANCA_MENZIL * 0.95

## Ayaklarin altindaki platformun SAG kenarina KENAR_PAYI kadar yakin mi.
## Beklerken kosmaya devam etmek botu ucuruma dusurur.
func _kenarda(pos: Vector2) -> bool:
	for r: Rect2 in _zeminler:
		if pos.x < r.position.x or pos.x > r.end.x:
			continue
		var bosluk := r.position.y - pos.y
		if bosluk < -4.0 or bosluk > OYUNCU_YARI_BOY + 4.0:
			continue
		return pos.x > r.end.x - KENAR_PAYI
	return false

## Capanin altinda (azami halat bandinda) olduren diken var mi. Frende halat
## uzatmak boyle bir capada YASAK: guvenli boy hesabi yay dibini capanin tam
## altina koyar, sert kisit yuksek hizda daha asagi sarkitabiliyor - diken
## tarlali 3, 4, 5 ve 10. bolumde olum patlamisti (v0.5 2. ve 3. deneme).
func _diken_altta(capa: Vector2) -> bool:
	for r: Rect2 in _diken:
		if r.position.y <= capa.y:
			continue
		if capa.x < r.position.x - Ayarlar.KANCA_AZAMI_HALAT \
				or capa.x > r.end.x + Ayarlar.KANCA_AZAMI_HALAT:
			continue
		return true
	return false

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
	# Rota noktalarinin canli dugumleri (v0.5): hedef artik plandaki statik
	# nokta degil, dugumun o anki konumu - hareketli nokta boyle izlenir.
	var dugumler: Array[Node2D] = []
	for p: Vector2 in rota:
		dugumler.append(_dugum_bul(bolum, p))

	var hedef_i := 0
	var bekleme := 0.0                 # hareketli noktayi platformda bekleme suresi
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
		var hedef_dugum: Node2D = null
		if hedef_i < dugumler.size():
			# Olumden sonra Bolum noktalari yeniden kurar: eski dugum serbest
			# birakilmistir, ayni plan noktasi icin yenisi bulunur.
			if not is_instance_valid(dugumler[hedef_i]):
				dugumler[hedef_i] = _dugum_bul(bolum, rota[hedef_i])
			hedef_dugum = dugumler[hedef_i]
		if hedef_dugum != null:
			hedef = hedef_dugum.global_position
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
			# Birakma: yeterince hizli, yon sonraki hedefe donuk, capayi gecmis
			# ve asagi dalmiyor. Denenen alternatifler daha kotu sonuc verdi:
			#   - hedefe dogru sabit girdi        -> 3/14 bolum
			#   - yalniz yukselirken birakma      -> 1/14 bolum
			#   - capa sarti olmadan              -> sarkac tam tur donuyor
			# Son adimda esik alti hizla birakmayi da denedik (3. deneme): bot
			# bitise erken ve yavas birakip kosuyor, 2. ve 6. bolum 1,5-3 sn
			# uzuyordu. Hizli ve alcak birakis bayrak alanindan gecip havada
			# bitiriyor (_inise_uygun) - esik sarti her adimda kaliyor.
			var son_adim: bool = hedef_i >= rota.size()
			# Son adimda yon sarti gevsek (saga gitsin yeter): bayraga (uzak,
			# asagi) dogru 0,55 hizasi YUKSELEN birakisi reddediyor, bot yay
			# dibinden asla platforma yetisemiyor ve 5. bolumde 11 sn asili
			# kaliyordu (5. deneme). Inis tahmini zaten ucusu denetliyor.
			var yon_uygun: bool = hiz.x > 0.0 if son_adim else hiz.normalized().dot(yon) > 0.55
			var uygun: bool = yeterli \
				and yon_uygun \
				and pos.x > capa.x - 8.0 \
				and hiz.y < 40.0
			# Son hedef bitis ise: platformu asacak ya da ona YETISMEYECEK bir
			# birakis uygun degil.
			var inis: int = INIS_UYGUN if not son_adim else _inis(pos, _birakma_hizi(hiz))
			if uygun and inis != INIS_UYGUN:
				uygun = false
			# HIZ FRENI (v0.5): birakilamiyorsa ve bitise bu hizla inilemeyecek
			# kadar HIZLIYSA - salinima ters bas, halati uzat. Kisa kalacaksa
			# frenlemek ters etki: daha cok salinim gerek, pompa devam.
			var frenle: bool = not uygun and (hiz.length() > FREN_HIZI \
				or (yeterli and inis == INIS_UZUN))
			# Pompala: tegetsel hizin isaretine bas (sarkaci buyutmenin dogru
			# yolu; tools/olcum.gd de ayni seyi yapiyor). Frende tersi.
			oyuncu.bot_yon = -signf(hiz.dot(teget)) if frenle else signf(hiz.dot(teget))
			# Halat pompasi (v0.4). Once GUVENLIK: yay dibi dikenin/zeminin
			# ustunde kalsin - bolum 3'te bot tam da bu yuzden oluyordu.
			# Sonra HIZ: dipte kisalt (aci momentumu korunur), uclarda uzat.
			var guvenli := _guvenli_boy(capa)
			var adim := POMPA_HIZI * dt
			if oyuncu.halat_boyu > guvenli:
				# ANINDA guvenli boya: 7,5 px/kare ile kisaltan surum, 900 px/sn ile
				# alcaktan tutunan botu platformun yan duvarina carptiriyordu
				# (bolum 8, y=310'da 168 px halat, guvenli 138 - tani izi).
				oyuncu.halat_degistir(-(oyuncu.halat_boyu - guvenli))
			elif frenle:
				# Uzatma yalniz altta olduren diken yoksa (_diken_altta).
				if not _diken_altta(capa):
					oyuncu.halat_degistir(minf(adim * 2.0, maxf(guvenli - oyuncu.halat_boyu, 0.0)))
			elif hiz.length() >= POMPA_HEDEF_HIZ:
				pass                        # yeterince hizli: pompalamayi birak
			elif disa.y > DIP_ESIGI:
				oyuncu.halat_degistir(-minf(adim, oyuncu.halat_boyu - Ayarlar.KANCA_ASGARI_HALAT))
			else:
				oyuncu.halat_degistir(minf(adim, guvenli - oyuncu.halat_boyu))
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
				bekleme = 0.0
				gecikme = rastgele.randf_range(GECIKME_ALT, GECIKME_UST)
		elif oyuncu.is_on_floor():
			# HAREKETLI NOKTADA BEKLEME (v0.5): nokta salinimla menzile
			# girecekse platformdan atlama; kenara kadar yuru, orada dur.
			if bekleme < BEKLEME_SINIRI and _beklemeye_deger(hedef_dugum, pos):
				bekleme += dt
				if _kenarda(pos):
					oyuncu.bot_yon = 0.0
				continue
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
			# Nisan once hedefe dogru. Son hedef (bayrak) asagidaysa ve o yonde
			# aday yoksa ileri-yukari denenir: bolum 6'da bot son platforma
			# dusuyordu, bayraga nisan alinca ustteki hareketli nokta aday
			# degildi. Bu yedek YALNIZ son hedefte: ara hedeflerde de
			# ileri-yukari nisan alan ilk surum, nokta sirasinin ustunden ucan
			# botu aday bulamaz birakti - 3, 8, 10, 13. bolumde olum patladi.
			var ara := oyuncu.en_iyi_nokta((hedef - pos).normalized())
			if ara == null and son_hedef:
				ara = oyuncu.en_iyi_nokta(Vector2(0.85, -0.53).normalized())
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
		"olum": olumler.size(),
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
