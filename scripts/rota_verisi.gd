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
##   "tahmin":  true ise bot bu bolumu bitiremedi; sure, botun bitirdigi
##              bolumlerde olculen rota hizindan (sn/px) cikarildi,
##   "madalya": [altin, gumus, bronz] (sn, ms hassasiyetinde),
##   "nokta":   rotanin kullandigi kanca noktalari (rota ipucu bunu isaretler),
## }

const VERI := {
	1: {"sure": 2.917, "ortanca": 2.917, "tahmin": false, "madalya": [3.646, 4.958, 6.708], "nokta": [Vector2(480, 128)]},
	2: {"sure": 5.367, "ortanca": 5.367, "tahmin": false, "madalya": [6.708, 9.123, 12.343], "nokta": [Vector2(416, 144), Vector2(608, 144), Vector2(960, 160)]},
	3: {"sure": 5.496, "ortanca": 5.496, "tahmin": true, "madalya": [6.870, 9.344, 12.642], "nokta": [Vector2(480, 96), Vector2(880, 112)]},
	4: {"sure": 3.917, "ortanca": 4.217, "tahmin": false, "madalya": [5.271, 7.168, 9.698], "nokta": [Vector2(384, 128), Vector2(624, 128), Vector2(1024, 80), Vector2(1424, 128)]},
	5: {"sure": 7.009, "ortanca": 7.009, "tahmin": true, "madalya": [8.761, 11.914, 16.120], "nokta": [Vector2(544, 96), Vector2(848, 64), Vector2(1168, 80), Vector2(1488, 112)]},
	6: {"sure": 8.733, "ortanca": 8.833, "tahmin": false, "madalya": [11.042, 15.017, 20.317], "nokta": [Vector2(400, 144), Vector2(656, 144), Vector2(976, 144), Vector2(1216, 144), Vector2(1552, 144)]},
	7: {"sure": 7.893, "ortanca": 7.893, "tahmin": true, "madalya": [9.867, 13.419, 18.155], "nokta": [Vector2(400, 144), Vector2(672, 144), Vector2(1040, 224), Vector2(1328, 200), Vector2(1664, 240)]},
	8: {"sure": 3.717, "ortanca": 3.783, "tahmin": false, "madalya": [4.729, 6.432, 8.702], "nokta": [Vector2(384, 144), Vector2(688, 144), Vector2(976, 144), Vector2(1280, 144), Vector2(1664, 72)]},
	9: {"sure": 8.734, "ortanca": 8.734, "tahmin": true, "madalya": [10.918, 14.848, 20.089], "nokta": [Vector2(400, 144), Vector2(816, 144), Vector2(1120, 144), Vector2(1312, 96), Vector2(1552, 144), Vector2(1856, 144)]},
	10: {"sure": 7.322, "ortanca": 7.322, "tahmin": true, "madalya": [9.153, 12.448, 16.841], "nokta": [Vector2(384, 192), Vector2(624, 160), Vector2(944, 192), Vector2(1080, 192), Vector2(1488, 192)]},
	11: {"sure": 9.351, "ortanca": 9.351, "tahmin": true, "madalya": [11.689, 15.896, 21.507], "nokta": [Vector2(368, 144), Vector2(768, 144), Vector2(1088, 144), Vector2(1488, 144), Vector2(1808, 144), Vector2(2208, 144)]},
	12: {"sure": 8.982, "ortanca": 8.982, "tahmin": true, "madalya": [11.228, 15.270, 20.659], "nokta": [Vector2(368, 144), Vector2(784, 144), Vector2(1056, 144), Vector2(1424, 96), Vector2(1840, 144), Vector2(2160, 144)]},
	13: {"sure": 9.409, "ortanca": 9.409, "tahmin": true, "madalya": [11.762, 15.996, 21.642], "nokta": [Vector2(496, 192), Vector2(800, 192), Vector2(1104, 176), Vector2(1408, 192), Vector2(1712, 144), Vector2(2000, 96), Vector2(2288, 144)]},
	14: {"sure": 9.960, "ortanca": 9.960, "tahmin": true, "madalya": [12.450, 16.932, 22.908], "nokta": [Vector2(384, 128), Vector2(640, 128), Vector2(912, 112), Vector2(1184, 112), Vector2(1488, 224), Vector2(1632, 224), Vector2(1776, 144), Vector2(2064, 128)]},
}

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

## Sure gercek bir bot kosusundan mi geldi, yoksa olculmus hizdan tahmin mi?
static func tahmin_mi(bolum_no: int) -> bool:
	return bool(_kayit(bolum_no).get("tahmin", false))
