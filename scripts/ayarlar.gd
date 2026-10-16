extends Node
## Oyunun tum ayarlanabilir sabitleri. Oynanis hissi buradan degistirilir.
##
## NOT: Sallanma dortlusu (SALLANMA_IVMESI, SALLANMA_SONUMU, BIRAKMA_CARPANI,
## KANCA_MENZIL) bilerek `const` degil `var` - tools/olcum.gd bunlari tarayarak
## olcum yapiyor. Degerlerin nasil secildigi README'de "Sallanma sabitleri" basliginda.

# --- Kosma / ziplama ---
const HIZ := 190.0
const IVME := 1500.0
const SURTUNME := 1400.0
const HAVA_KONTROLU := 0.45
const ZIPLA_GUCU := 330.0
const YERCEKIMI := 980.0
const KOJOT_SURESI := 0.12
const ZIPLA_TAMPON_SURESI := 0.12

# --- Kanca (olcumle ayarlanan dortlu) ---
var SALLANMA_IVMESI := 1250.0        ## tegetsel girdi ivmesi (sallanmayi buyutur)
var SALLANMA_SONUMU := 0.10          ## saniye basina hiz kaybi orani (v0.3: sert kisit kacagi kapatti)
var BIRAKMA_CARPANI := 1.10          ## birakinca kucuk firlama bonusu
var KANCA_MENZIL := 240.0            ## bu uzakligin otesine kanca atilamaz

# --- Kanca (sabitler) ---
const KANCA_ASGARI_HALAT := 28.0
const KANCA_AZAMI_HALAT := 260.0
const HALAT_DEGISIM_HIZI := 140.0    ## px/sn, yukari-asagi ile kisalt/uzat
const KANCA_UCUS_SURESI := 0.055     ## halat bu surede ucup takilir (his icin; fizik hemen baslar)
const NISAN_ASGARI_HIZA := 0.2       ## nisan yonuyle bu kadar hizali noktalar aday
const AZAMI_HIZ := 900.0

# --- Hedefleme puanlamasi (v0.3) ---
## puan = hiza*NISAN_PUAN_HIZA - uzaklik/menzil + hiz_uyumu*NISAN_PUAN_HIZ
const NISAN_PUAN_HIZA := 3.0         ## nisan yonuyle hizanin agirligi
const NISAN_PUAN_HIZ := 1.0          ## mevcut hiz yonune uyumun agirligi
const NISAN_HIZ_ESIGI := 120.0       ## bu hizin altinda hiz yonu puana girmez
const KANCA_TAMPON_SURESI := 0.12    ## basis saklanir: bu surede hedef belirirse takilir
const KANCA_KOJOT_SURESI := 0.12     ## hedef kaybolduktan sonra bu kadar hala tutulabilir
const KANCA_KOJOT_PAYI := 1.2        ## kojot penceresinde menzil bu oranda genisler

# --- Sallanma his ayarlari (v0.3) ---
var SALLANMA_YERCEKIMI := 1.3        ## sallanirken yercekimi bu carpanla uygulanir (olcumle)
const POMPA_VERIMI := 0.55           ## halat kisaltmanin aci momentumu kazancindan alinan pay
const BIRAKMA_ESIGI := 380.0         ## bu hizin ustunde birakma bonusu (altinda duz birakma)

# --- Kamera (ileri bakan) ---
const KAMERA_ILERI := 0.22           ## ofset = hiz * bu
const KAMERA_ILERI_AZAMI := 84.0     ## ofsetin px siniri
const KAMERA_ILERI_YUMUSAKLIK := 3.0
const KAMERA_UZAKLASMA := 0.09       ## yuksek hizda goruntu bu oranda genisler
const KAMERA_UZAKLASMA_ESIGI := 320.0

# --- Bolum ogeleri ---
const HAREKETLI_HIZ := 46.0          ## hareketli kanca noktasinin px/sn hizi
const KIRILGAN_UYARI := 0.45         ## kirilgan nokta birakildiktan sonra bu kadar yanip soner
const RUZGAR_IVME := 700.0           ## itici alanin px/sn^2 ivmesi
const RUZGAR_AZAMI := 420.0          ## ruzgarin o eksende verebilecegi azami hiz

# --- Olum / kamera ---
const OLUM_Y := 620.0                ## bu y'nin altina dusen olur
const KAMERA_YUMUSAKLIK := 6.0
const SARSINTI_SONUMU := 9.0         ## sarsinti genligi saniyede bu carpanla soner
const SARSINTI_HIZ := 34.0           ## sarsinti titresim frekansi

# --- Assist mode (Celeste-style game speed + Geometry Dash-style practice points) ---
## Selectable game speeds; the setting "yardim_hiz" stores the index. Index 0 is
## normal speed. Any run that used a speed below 100% or practice points at any
## moment is "assisted": it never writes a best time, medal, chain record, ghost
## or daily result (Bolum._yardimli). The next level still unlocks, so assist
## players can progress through the game.
const YARDIM_HIZLARI := [1.0, 0.9, 0.8, 0.7, 0.6, 0.5]
const PRATIK_BEKLEME := 0.35         ## s standing on the ground before a practice point is set
const PRATIK_ASGARI_ARALIK := 48.0   ## px; a new practice point must be this far from the last spawn

## Game speed chosen in assist mode (1.0 = normal).
func yardim_hizi() -> float:
	var i := clampi(int(Kayit.ayar("yardim_hiz")), 0, YARDIM_HIZLARI.size() - 1)
	return float(YARDIM_HIZLARI[i])

## True when any assist option is on (slower game speed or practice points).
func yardim_acik() -> bool:
	return yardim_hizi() < 1.0 or bool(Kayit.ayar("pratik"))

# --- Girdi semasi ---

## Testlerin ezmesi icin: -1 otomatik, 0 zorla kapali, 1 zorla acik.
var dokunmatik_zorla := -1

## Tus adi eki tek yerden: masaustunde "Geri  (Esc)", dokunmatikte sadece
## "Geri". Telefonda klavye yok - "(R)" yazan bir dugme yalan soyluyor.
## Tuslu her etiket bu yardimcidan gecer; testi tum ekranlari tariyor.
func kisayol(metin: String, tus: String) -> String:
	if dokunmatik_mi():
		return metin
	return "%s  (%s)" % [metin, tus]

## Tek parmak semasi acik mi. TEK KAYNAK - oyuncu girdisi, menu yardimi,
## bolum ipuclari ve HUD bunu okur.
##
## Telefon tarayicisinda OS.has_feature("mobile") FALSE doner (web disa
## aktarimi "web" + "web_android"/"web_ios" bildirir). Sadece "mobile"a
## bakmak telefonda semayi hic acmiyordu - v0.3.1 yonetici bulgusu.
## is_touchscreen_available() yalniz web'de sayilir: masaustu dokunmatik
## ekranda fare de vardir, semayi zorla degistirmek orada geriye gidis olur.
func dokunmatik_mi() -> bool:
	if dokunmatik_zorla >= 0:
		return dokunmatik_zorla == 1
	if bool(Kayit.ayar("dokunmatik")):
		return true
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	return OS.has_feature("web") and DisplayServer.is_touchscreen_available()
