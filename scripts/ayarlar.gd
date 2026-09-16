extends Node
## Oyunun tum ayarlanabilir sabitleri. Oynanis hissi buradan degistirilir.

# --- Kosma / ziplama ---
const HIZ := 190.0
const IVME := 1500.0
const SURTUNME := 1400.0
const HAVA_KONTROLU := 0.45
const ZIPLA_GUCU := 330.0
const YERCEKIMI := 980.0
const KOJOT_SURESI := 0.12
const ZIPLA_TAMPON_SURESI := 0.12

# --- Kanca ---
const KANCA_MENZIL := 230.0          ## bu uzakligin otesine kanca atilamaz
const KANCA_ASGARI_HALAT := 28.0
const KANCA_AZAMI_HALAT := 260.0
const HALAT_DEGISIM_HIZI := 130.0    ## px/sn, yukari-asagi ile kisalt/uzat
const SALLANMA_IVMESI := 950.0       ## tegetsel girdi ivmesi (sallanmayi buyutur)
const SALLANMA_SONUMU := 0.15        ## saniye basina hiz kaybi orani (momentum korunsun diye dusuk)
const BIRAKMA_CARPANI := 1.08        ## birakinca kucuk firlama bonusu
const NISAN_ASGARI_HIZA := 0.2       ## nisan yonuyle bu kadar hizali noktalar aday
const AZAMI_HIZ := 900.0

# --- Olum / kamera ---
const OLUM_Y := 620.0                ## bu y'nin altina dusen olur
const KAMERA_YUMUSAKLIK := 6.0

# --- Renkler (yer tutucu gorsel) ---
const RENK_ARKAPLAN := Color(0.07, 0.08, 0.13)
const RENK_ZEMIN := Color(0.29, 0.34, 0.45)
const RENK_ZEMIN_UST := Color(0.42, 0.52, 0.62)
const RENK_DIKEN := Color(0.85, 0.24, 0.30)
const RENK_BITIS := Color(0.32, 0.86, 0.45)
const RENK_HALAT := Color(0.95, 0.85, 0.45)
const RENK_NOKTA := Color(0.50, 0.56, 0.72)
const RENK_NOKTA_VURGU := Color(1.0, 1.0, 1.0)
const RENK_NOKTA_BAGLI := Color(1.0, 0.82, 0.25)
