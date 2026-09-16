extends RefCounted
class_name Bolumler
## Tum bolum verisi. Bolum sahneleri (scenes/bolumler/bolum_NN.tscn) sadece
## bolum_no tasir; geometriyi bolum.gd bu tablodan uretir. Elle yazilmis
## sabit veri oldugu icin uretim her calistirmada birebir ayni.
##
## zemin/tavan : Rect2(x, y, genislik, yukseklik) - kati blok
## diken       : Rect2(...) - degince oldurur
## kanca       : Vector2 - kanca atilabilen nokta
## kisayol     : iyi bir sallanisla atlanabilen bolum aciklamasi (README icin)

const VERI := [
	{
		"ad": "İlk Tutuş",
		"ipucu": "Fare ile nişan al, SOL TIK basılı tut: kanca takılır. Bırakınca kopar.",
		"basla": Vector2(60, 250),
		"bitis": Vector2(1150, 268),
		"zemin": [Rect2(0, 300, 420, 60), Rect2(700, 300, 520, 60)],
		"diken": [],
		"kanca": [Vector2(470, 130), Vector2(560, 115), Vector2(650, 130), Vector2(560, 55)],
		"kisayol": "Ustteki yuksek nokta (560,55) tek sallanista tum boslugu gecirir.",
	},
	{
		"ad": "Halat Boyu",
		"ipucu": "W/S halatı kısaltır-uzatır. Kısa halat daha hızlı döndürür.",
		"basla": Vector2(60, 250),
		"bitis": Vector2(1530, 268),
		"zemin": [Rect2(0, 300, 360, 60), Rect2(620, 300, 280, 60), Rect2(1160, 300, 440, 60)],
		"diken": [],
		"kanca": [Vector2(410, 140), Vector2(510, 90), Vector2(610, 140), Vector2(950, 150), Vector2(1050, 80), Vector2(1150, 150)],
		"kisayol": "(510,90) ve (1050,80) noktalarinda halati kisaltip savurursan orta platforma hic inmeden gecersin.",
	},
	{
		"ad": "Diken Tarlası",
		"ipucu": "Kırmızı dikene değme. Sallanarak üstünden geç.",
		"basla": Vector2(60, 250),
		"bitis": Vector2(1540, 268),
		"zemin": [Rect2(0, 300, 300, 60), Rect2(300, 300, 400, 60), Rect2(760, 300, 300, 60), Rect2(1120, 300, 480, 60)],
		"diken": [Rect2(320, 284, 360, 16)],
		"kanca": [Vector2(360, 130), Vector2(480, 100), Vector2(600, 130), Vector2(720, 120), Vector2(880, 110), Vector2(1010, 130), Vector2(1140, 110)],
		"kisayol": "(480,100) uzerinden tek uzun salinimla diken tarlasinin tamami atlanir.",
	},
	{
		"ad": "Uçurum",
		"ipucu": "",
		"basla": Vector2(60, 250),
		"bitis": Vector2(2030, 268),
		"zemin": [Rect2(0, 300, 320, 60), Rect2(620, 300, 220, 60), Rect2(1140, 300, 260, 60), Rect2(1700, 300, 400, 60)],
		"diken": [Rect2(1260, 284, 80, 16)],
		"kanca": [Vector2(380, 120), Vector2(500, 80), Vector2(620, 120), Vector2(900, 140), Vector2(1020, 80), Vector2(1140, 130), Vector2(1420, 120), Vector2(1560, 80), Vector2(1700, 130)],
		"kisayol": "(500,80)-(1020,80) zincirinde hic yere basmadan iki ucurum birden gecilir.",
	},
	{
		"ad": "Yukarı",
		"ipucu": "",
		"basla": Vector2(60, 250),
		"bitis": Vector2(1980, 208),
		"zemin": [Rect2(0, 300, 360, 60), Rect2(560, 240, 200, 40), Rect2(900, 180, 200, 40), Rect2(1280, 240, 220, 40), Rect2(1600, 240, 420, 60)],
		"diken": [Rect2(1760, 224, 100, 16)],
		"kanca": [Vector2(420, 140), Vector2(540, 90), Vector2(700, 90), Vector2(840, 60), Vector2(1000, 60), Vector2(1160, 80), Vector2(1320, 90), Vector2(1480, 110), Vector2(1620, 120), Vector2(1800, 90)],
		"kisayol": "(840,60)-(1000,60) ust hatti platformlara hic degmeden basa kadar tasir.",
	},
	{
		"ad": "Dar Geçit",
		"ipucu": "Tavan alçaldığında halatı kısalt.",
		"basla": Vector2(60, 250),
		"bitis": Vector2(2240, 268),
		"zemin": [Rect2(0, 300, 340, 60), Rect2(700, 300, 300, 60), Rect2(1340, 300, 260, 60), Rect2(1900, 300, 380, 60), Rect2(1000, 0, 340, 150), Rect2(1600, 0, 300, 170)],
		"diken": [Rect2(1440, 284, 100, 16)],
		"kanca": [Vector2(400, 140), Vector2(520, 100), Vector2(660, 140), Vector2(1040, 220), Vector2(1180, 215), Vector2(1320, 200), Vector2(1660, 240), Vector2(1820, 230), Vector2(1960, 120)],
		"kisayol": "Dar gecitte halati asgariye indirip (1180,215) etrafinda tam tur atarsan cikista cok yuksek hiz kazanirsin.",
	},
	{
		"ad": "Hız",
		"ipucu": "",
		"basla": Vector2(60, 250),
		"bitis": Vector2(2640, 268),
		"zemin": [Rect2(0, 300, 300, 60), Rect2(840, 300, 180, 60), Rect2(1560, 300, 180, 60), Rect2(2280, 300, 420, 60)],
		"diken": [Rect2(920, 284, 60, 16), Rect2(1640, 284, 60, 16)],
		"kanca": [Vector2(360, 140), Vector2(480, 70), Vector2(620, 70), Vector2(760, 140), Vector2(1080, 140), Vector2(1200, 60), Vector2(1340, 60), Vector2(1480, 140), Vector2(1800, 140), Vector2(1920, 60), Vector2(2060, 60), Vector2(2200, 140)],
		"kisayol": "Ust sira (y=60) hic yere inmeden bitise kadar gider; ara adalar tamamen atlanabilir.",
	},
	{
		"ad": "Final",
		"ipucu": "",
		"basla": Vector2(60, 250),
		"bitis": Vector2(2740, 268),
		"zemin": [Rect2(0, 300, 320, 60), Rect2(660, 260, 200, 40), Rect2(1200, 300, 240, 60), Rect2(1780, 220, 200, 40), Rect2(2300, 300, 500, 60), Rect2(1440, 0, 260, 160)],
		"diken": [Rect2(1240, 284, 100, 16), Rect2(2380, 284, 120, 16)],
		"kanca": [Vector2(380, 130), Vector2(500, 80), Vector2(640, 120), Vector2(900, 110), Vector2(1040, 60), Vector2(1180, 120), Vector2(1480, 230), Vector2(1620, 230), Vector2(1760, 140), Vector2(2040, 120), Vector2(2160, 60), Vector2(2300, 120)],
		"kisayol": "(1040,60) noktasindan uzun salinimla dikenli platform ve tavan blogunun altindaki gecit tek hamlede asilir.",
	},
]

static func sayi() -> int:
	return VERI.size()

static func veri(bolum_no: int) -> Dictionary:
	return VERI[clampi(bolum_no, 1, VERI.size()) - 1]

static func ad(bolum_no: int) -> String:
	return String(veri(bolum_no)["ad"])

## Bolum sahnesinin yolu.
static func yol(bolum_no: int) -> String:
	return "res://scenes/bolumler/bolum_%02d.tscn" % bolum_no
