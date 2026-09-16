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
var SALLANMA_SONUMU := 0.05          ## saniye basina hiz kaybi orani
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

# --- Renkler: tek kaynak scripts/palet.gd ---
const RENK_ARKAPLAN := Palet.GOK_DIP
const RENK_HALAT := Palet.HALAT
const RENK_NOKTA := Palet.NOKTA
const RENK_NOKTA_VURGU := Palet.NOKTA_VURGU
const RENK_NOKTA_BAGLI := Palet.NOKTA_BAGLI
const RENK_METIN := Palet.METIN
const RENK_METIN_SOLUK := Palet.METIN_SOLUK
