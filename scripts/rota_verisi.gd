extends RefCounted
class_name RotaVerisi
## URETILMIS DOSYA — elle duzenleme. Yazan: tools/rota.gd
##
##   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . --scene res://tools/rota.tscn
##
## Bot her bolumu gercek fizikle, planlanan rotayi izleyerek kosuyor. Her kosuda
## karar anlarina rastgele tepki gecikmesi ekleniyor (insan gecikmesi taklidi);
## madalya esikleri bu kosularin en iyisinden ve ortancasindan ms hassasiyetinde
## hesaplaniyor. Ayrintilar: README "Madalya sureleri".
##
## Alanlar: bolum_no -> {
##   "sure":    botun en iyi kosusu (sn),
##   "ortanca": gecikmeli kosularin ortancasi (sn),
##   "madalya": [altin, gumus, bronz] (sn, ms hassasiyetinde),
##   "nokta":   rotanin kullandigi kanca noktalari (rota ipucu bunu isaretler),
## }

const VERI := {}

static func _kayit(bolum_no: int) -> Dictionary:
	return VERI.get(bolum_no, {})

## Madalya esikleri; uretilmemisse bos dizi (Bolumler tablodaki degeri kullanir).
static func madalya(bolum_no: int) -> Array:
	return _kayit(bolum_no).get("madalya", [])

## Rotanin kullandigi kanca noktalari; uretilmemisse bos dizi.
static func nokta(bolum_no: int) -> Array:
	return _kayit(bolum_no).get("nokta", [])

## Botun en iyi kosu suresi (sn); uretilmemisse 0.
static func sure(bolum_no: int) -> float:
	return float(_kayit(bolum_no).get("sure", 0.0))
