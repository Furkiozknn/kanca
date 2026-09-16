extends RefCounted
class_name Bolumler
## Tum bolum verisi. Bolum sahneleri (scenes/bolumler/bolum_NN.tscn) sadece
## bolum_no tasir; geometriyi bolum.gd bu tablodan uretir. Elle yazilmis sabit
## veri oldugu icin uretim her calistirmada birebir ayni.
##
## Butun koordinatlar 16 px karo izgarasinda. Zeminler TileMapLayer'a dosenir;
## veri tablosu yine de tek gercek kaynak (bir boslugu daraltmak tek sayi).
##
## Alanlar
##   zemin       : Array[Rect2]  kati blok (y >= 150 olanlar zemin, digerleri tavan)
##   diken       : Array[Rect2]  yukari bakan diken, degince olum
##   tavan_diken : Array[Rect2]  asagi bakan diken, degince olum
##   kanca       : Array[Vector2]           sabit kanca noktasi
##   kanca_h     : Array[{a, b}]            iki uc arasinda gidip gelen nokta
##   kanca_k     : Array[Vector2]           kirilgan: bir kez tutulur
##   ruzgar      : Array[{alan: Rect2, yon: Vector2}]  itici alan
##   kontrol     : Array[Vector2]           kontrol noktasi (olunce buradan devam)
##   madalya     : [altin, gumus, bronz] saniye - YEDEK deger; uretilmis rota
##                 verisi (scripts/rota_verisi.gd) varsa o kullanilir
##   kisayol     : iyi bir sallanisla atlanabilen kisim (README icin)

const KARO := 16

const VERI := [
	{
		"ad": "İlk Tutuş",
		"ipucu": "Fare ile nişan al, SOL TIK basılı tut: kanca takılır. Bırakınca kopar.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(1152, 272),
		"zemin": [Rect2(0, 304, 432, 64), Rect2(704, 304, 528, 64)],
		"kanca": [Vector2(480, 128), Vector2(560, 112), Vector2(656, 128), Vector2(560, 48)],
		"madalya": [5.5, 7.5, 10.0],
		"kisayol": "Ustteki yuksek nokta (560,48) tek sallanista tum boslugu gecirir.",
	},
	{
		"ad": "Halat Boyu",
		"ipucu": "W/S halatı kısaltır-uzatır. Kısa halat daha hızlı döndürür.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(1536, 272),
		"zemin": [Rect2(0, 304, 368, 64), Rect2(624, 304, 288, 64), Rect2(1168, 304, 448, 64)],
		"kanca": [Vector2(416, 144), Vector2(512, 96), Vector2(608, 144),
			Vector2(960, 160), Vector2(1056, 80), Vector2(1152, 160)],
		"madalya": [6.5, 9.0, 12.0],
		"kisayol": "(512,96) ve (1056,80) noktalarinda halati kisaltip savurursan orta platforma hic inmeden gecersin.",
	},
	{
		"ad": "Diken Tarlası",
		"ipucu": "Kırmızı dikene değme. Sallanarak üstünden geç.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(1552, 272),
		"zemin": [Rect2(0, 304, 304, 64), Rect2(304, 304, 400, 64),
			Rect2(768, 304, 304, 64), Rect2(1120, 304, 480, 64)],
		"diken": [Rect2(320, 288, 352, 16)],
		"kanca": [Vector2(368, 128), Vector2(480, 96), Vector2(592, 128), Vector2(720, 112),
			Vector2(880, 112), Vector2(1024, 128), Vector2(1136, 112)],
		"madalya": [6.5, 9.0, 12.0],
		"kisayol": "(480,96) uzerinden tek uzun salinimla diken tarlasinin tamami atlanir.",
	},
	{
		"ad": "Uçurum",
		"ipucu": "",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2032, 272),
		"zemin": [Rect2(0, 304, 320, 64), Rect2(624, 304, 224, 64),
			Rect2(1136, 304, 256, 64), Rect2(1696, 304, 400, 64)],
		"diken": [Rect2(1264, 288, 80, 16)],
		"kanca": [Vector2(384, 128), Vector2(496, 80), Vector2(624, 128), Vector2(896, 144),
			Vector2(1024, 80), Vector2(1136, 128), Vector2(1424, 128), Vector2(1568, 80),
			Vector2(1696, 128)],
		"madalya": [8.5, 11.5, 15.0],
		"kisayol": "(496,80)-(1024,80) zincirinde hic yere basmadan iki ucurum birden gecilir.",
	},
	{
		"ad": "Yukarı",
		"ipucu": "",
		"basla": Vector2(64, 256),
		"bitis": Vector2(1968, 272),
		"zemin": [Rect2(0, 304, 368, 64), Rect2(560, 240, 208, 48), Rect2(896, 176, 208, 48),
			Rect2(1280, 240, 224, 48), Rect2(1600, 304, 416, 64)],
		"diken": [Rect2(1760, 288, 96, 16)],
		"kanca": [Vector2(416, 144), Vector2(544, 96), Vector2(704, 96), Vector2(848, 64),
			Vector2(1008, 64), Vector2(1168, 80), Vector2(1328, 96), Vector2(1488, 112),
			Vector2(1616, 128), Vector2(1808, 96)],
		"madalya": [8.5, 11.5, 15.0],
		"kisayol": "(848,64)-(1008,64) ust hatti platformlara hic degmeden basa kadar tasir.",
	},
	{
		"ad": "Sallanan Kayalar",
		"ipucu": "Camgöbeği halkalar yerinde durmaz. Zamanlamayı yakala.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2128, 272),
		"zemin": [Rect2(0, 304, 352, 64), Rect2(688, 304, 240, 64),
			Rect2(1248, 304, 240, 64), Rect2(1792, 304, 400, 64)],
		"kanca": [Vector2(400, 144), Vector2(656, 144), Vector2(976, 144), Vector2(1216, 144),
			Vector2(1552, 144), Vector2(1760, 144)],
		"kanca_h": [
			{"a": Vector2(480, 96), "b": Vector2(608, 96)},
			{"a": Vector2(1040, 80), "b": Vector2(1168, 80)},
			{"a": Vector2(1616, 112), "b": Vector2(1712, 64)},
		],
		"madalya": [9.0, 12.0, 16.0],
		"kisayol": "Hareketli nokta sana dogru gelirken tutarsan salinim bedava buyur.",
	},
	{
		"ad": "Dar Geçit",
		"ipucu": "Tavan alçaldığında halatı kısalt.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2240, 272),
		"zemin": [Rect2(0, 304, 352, 64), Rect2(704, 304, 304, 64), Rect2(1344, 304, 256, 64),
			Rect2(1904, 304, 384, 64), Rect2(1008, 0, 336, 160), Rect2(1600, 0, 304, 176)],
		"diken": [Rect2(1440, 288, 96, 16)],
		"kanca": [Vector2(400, 144), Vector2(528, 96), Vector2(672, 144), Vector2(1040, 224),
			Vector2(1184, 216), Vector2(1328, 200), Vector2(1664, 240), Vector2(1824, 232),
			Vector2(1968, 128)],
		"madalya": [9.5, 13.0, 17.0],
		"kisayol": "Dar gecitte halati asgariye indirip (1184,216) etrafinda tam tur atarsan cikista cok yuksek hiz kazanirsin.",
	},
	{
		"ad": "Tek Kullanımlık",
		"ipucu": "Mor halkalar bir kez tutulur; bıraktığın an kırılır. Duraklama.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2224, 272),
		"zemin": [Rect2(0, 304, 336, 64), Rect2(720, 304, 208, 64),
			Rect2(1312, 304, 208, 64), Rect2(1904, 304, 384, 64)],
		"kanca": [Vector2(384, 144), Vector2(688, 144), Vector2(976, 144), Vector2(1280, 144),
			Vector2(1568, 144), Vector2(1872, 144)],
		"kanca_k": [Vector2(480, 80), Vector2(592, 80), Vector2(1088, 64), Vector2(1200, 96),
			Vector2(1664, 72), Vector2(1776, 104)],
		"madalya": [9.5, 13.0, 17.0],
		"kisayol": "Kirilgan noktalari hic kullanmadan, alttaki sabit hattan da gecilebilir - ama cok daha yavas.",
	},
	{
		"ad": "Rüzgâr",
		"ipucu": "Mavi akıntı seni taşır. Halatı bırakıp akıntıya gir.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2464, 272),
		"zemin": [Rect2(0, 304, 352, 64), Rect2(848, 304, 224, 64),
			Rect2(1584, 304, 224, 64), Rect2(2128, 304, 400, 64)],
		"kanca": [Vector2(400, 144), Vector2(544, 112), Vector2(688, 64), Vector2(816, 144),
			Vector2(1120, 144), Vector2(1312, 96), Vector2(1440, 64), Vector2(1552, 144),
			Vector2(1856, 144), Vector2(1984, 64), Vector2(2096, 144)],
		"ruzgar": [
			{"alan": Rect2(608, 96, 208, 208), "yon": Vector2(1.0, -0.35)},
			{"alan": Rect2(1360, 64, 192, 240), "yon": Vector2(1.0, -0.5)},
			{"alan": Rect2(1904, 112, 192, 192), "yon": Vector2(0.0, -1.0)},
		],
		"madalya": [10.0, 13.5, 18.0],
		"kisayol": "Ilk akintiya yatay girersen kanca atmadan karsi kenara kadar tasinirsin.",
	},
	{
		"ad": "Dikenli Tavan",
		"ipucu": "Tavandaki dikenler de öldürür. Halatı kısa tut, alçaktan geç.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2096, 272),
		"zemin": [Rect2(0, 304, 336, 64), Rect2(688, 304, 224, 64), Rect2(1232, 304, 224, 64),
			Rect2(1776, 304, 384, 64), Rect2(400, 0, 208, 128), Rect2(960, 0, 240, 144),
			Rect2(1504, 0, 240, 128)],
		"tavan_diken": [Rect2(400, 128, 208, 16), Rect2(960, 144, 240, 16), Rect2(1504, 128, 240, 16)],
		"kanca": [Vector2(384, 192), Vector2(496, 176), Vector2(624, 160), Vector2(944, 192),
			Vector2(1080, 192), Vector2(1216, 176), Vector2(1488, 192), Vector2(1624, 176),
			Vector2(1760, 160)],
		"madalya": [9.0, 12.0, 16.0],
		"kisayol": "Alcak noktalarda halati 28 px'e indirip yatay savurmak tavana degmeden en hizli yol.",
	},
	{
		"ad": "Hız",
		"ipucu": "",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2640, 272),
		"zemin": [Rect2(0, 304, 304, 64), Rect2(848, 304, 176, 64),
			Rect2(1568, 304, 176, 64), Rect2(2288, 304, 416, 64)],
		"diken": [Rect2(944, 288, 64, 16), Rect2(1664, 288, 64, 16)],
		"kanca": [Vector2(368, 144), Vector2(480, 64), Vector2(624, 64), Vector2(768, 144),
			Vector2(1088, 144), Vector2(1200, 64), Vector2(1344, 64), Vector2(1488, 144),
			Vector2(1808, 144), Vector2(1920, 64), Vector2(2064, 64), Vector2(2208, 144)],
		"kontrol": [Vector2(880, 272), Vector2(1600, 272)],
		"madalya": [10.5, 14.0, 19.0],
		"kisayol": "Ust sira (y=64) hic yere inmeden bitise kadar gider; ara adalar tamamen atlanabilir.",
	},
	{
		"ad": "Kırık Sarkaç",
		"ipucu": "Hareketli ve kırılgan noktalar bir arada. Zinciri önceden planla.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2528, 272),
		"zemin": [Rect2(0, 304, 320, 64), Rect2(816, 304, 192, 64),
			Rect2(1552, 304, 192, 64), Rect2(2192, 304, 400, 64)],
		"kanca": [Vector2(368, 144), Vector2(784, 144), Vector2(1056, 144), Vector2(1520, 144),
			Vector2(1840, 144), Vector2(2160, 144)],
		"kanca_h": [
			{"a": Vector2(464, 96), "b": Vector2(592, 64)},
			{"a": Vector2(1152, 80), "b": Vector2(1312, 112)},
			{"a": Vector2(1936, 96), "b": Vector2(2064, 64)},
		],
		"kanca_k": [Vector2(688, 96), Vector2(1424, 96), Vector2(2096, 120)],
		"kontrol": [Vector2(880, 272)],
		"madalya": [10.5, 14.0, 19.0],
		"kisayol": "Hareketli nokta ucta duraklarken tutup kirilgana gecersen tek zincirde bosluk biter.",
	},
	{
		"ad": "Fırtına",
		"ipucu": "Rüzgâr yukarı iter, tavan diken dolu. Akıntıda halatı uzatma.",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2656, 272),
		"zemin": [Rect2(0, 304, 320, 64), Rect2(880, 304, 192, 64), Rect2(1632, 304, 192, 64),
			Rect2(2320, 304, 400, 64), Rect2(480, 0, 256, 144), Rect2(1216, 0, 272, 144)],
		"diken": [Rect2(1712, 288, 64, 16)],
		"tavan_diken": [Rect2(480, 144, 256, 16), Rect2(1216, 144, 272, 16)],
		"kanca": [Vector2(368, 192), Vector2(496, 192), Vector2(640, 192), Vector2(800, 192),
			Vector2(960, 144), Vector2(1104, 176), Vector2(1264, 192), Vector2(1408, 192),
			Vector2(1568, 192), Vector2(1712, 144), Vector2(1856, 144), Vector2(2000, 96),
			Vector2(2160, 112), Vector2(2288, 144)],
		"ruzgar": [
			{"alan": Rect2(736, 160, 144, 144), "yon": Vector2(1.0, -0.6)},
			{"alan": Rect2(1488, 160, 144, 144), "yon": Vector2(1.0, -0.6)},
			{"alan": Rect2(1968, 128, 160, 176), "yon": Vector2(0.4, -1.0)},
		],
		"kontrol": [Vector2(944, 272), Vector2(1664, 272)],
		"madalya": [11.0, 15.0, 20.0],
		"kisayol": "Tavan dikenlerinin altindaki akintiya alcaktan girip halati birakirsan tek hamlede karsiya gecersin.",
	},
	{
		"ad": "Final",
		"ipucu": "",
		"basla": Vector2(64, 256),
		"bitis": Vector2(2768, 272),
		"zemin": [Rect2(0, 304, 320, 64), Rect2(672, 256, 208, 48), Rect2(1216, 304, 240, 64),
			Rect2(1792, 224, 208, 48), Rect2(2320, 304, 512, 64), Rect2(1456, 0, 272, 160)],
		"diken": [Rect2(1248, 288, 96, 16), Rect2(2400, 288, 112, 16)],
		"tavan_diken": [Rect2(1456, 160, 272, 16)],
		"kanca": [Vector2(384, 128), Vector2(512, 80), Vector2(640, 128), Vector2(912, 112),
			Vector2(1056, 64), Vector2(1184, 112), Vector2(1488, 224), Vector2(1632, 224),
			Vector2(1776, 144), Vector2(2064, 128), Vector2(2192, 64), Vector2(2320, 128)],
		"kanca_h": [{"a": Vector2(1856, 96), "b": Vector2(1984, 64)}],
		"kanca_k": [Vector2(752, 64), Vector2(2256, 96)],
		"ruzgar": [{"alan": Rect2(880, 144, 240, 160), "yon": Vector2(1.0, -0.5)}],
		"kontrol": [Vector2(768, 224), Vector2(1888, 192)],
		"madalya": [11.5, 15.5, 21.0],
		"kisayol": "(1056,64) noktasindan uzun salinimla ruzgar ve dikenli platform tek hamlede asilir.",
	},
]

const BOS := {
	"ipucu": "", "zemin": [], "diken": [], "tavan_diken": [],
	"kanca": [], "kanca_h": [], "kanca_k": [], "ruzgar": [], "kontrol": [],
	"madalya": [10.0, 14.0, 20.0], "kisayol": "",
}

static func sayi() -> int:
	return VERI.size()

## Eksik alanlari bos degerle doldurulmus bolum verisi.
static func veri(bolum_no: int) -> Dictionary:
	var d: Dictionary = VERI[clampi(bolum_no, 1, VERI.size()) - 1].duplicate(true)
	for anahtar: String in BOS:
		if not d.has(anahtar):
			d[anahtar] = BOS[anahtar]
	d["madalya"] = madalya_esikleri(bolum_no)
	return d

## Madalya esikleri. Bot kosusundan uretilmis deger varsa o kazanir; yoksa
## tablodaki yedek deger. Boylece esikler tek yerden gelir.
static func madalya_esikleri(bolum_no: int) -> Array:
	var uretilmis := RotaVerisi.madalya(bolum_no)
	if uretilmis.size() == 3:
		return uretilmis
	var d: Dictionary = VERI[clampi(bolum_no, 1, VERI.size()) - 1]
	return d.get("madalya", BOS["madalya"])

static func ad(bolum_no: int) -> String:
	return String(VERI[clampi(bolum_no, 1, VERI.size()) - 1]["ad"])

## Bolum sahnesinin yolu.
static func yol(bolum_no: int) -> String:
	return "res://scenes/bolumler/bolum_%02d.tscn" % bolum_no

## Dikdortgeni karo izgarasina oturtur. Carpisma, gorsel ve testler hep bunu
## kullanir - veri ile oynanan dunya arasinda fark kalmaz.
static func karola(r: Rect2) -> Rect2:
	var x0 := floorf(r.position.x / KARO) * KARO
	var y0 := floorf(r.position.y / KARO) * KARO
	var x1 := ceilf(r.end.x / KARO) * KARO
	var y1 := ceilf(r.end.y / KARO) * KARO
	return Rect2(x0, y0, x1 - x0, y1 - y0)

## Bolumun karolanmis zemin dikdortgenleri.
static func zeminler(bolum_no: int) -> Array[Rect2]:
	var cikti: Array[Rect2] = []
	for r: Rect2 in veri(bolum_no)["zemin"]:
		cikti.append(karola(r))
	return cikti

## Gorus hatti: iki nokta arasinda kati zemin var mi (statik surum).
## Oyun icinde Oyuncu.gorus_var fizik isini ile ayni kontrolu yapiyor; bu surum
## testlerin ve rota planlayicisinin sahne kurmadan ayni cevabi almasi icin.
static func gorus_var(a: Vector2, b: Vector2, zeminler: Array[Rect2]) -> bool:
	for r: Rect2 in zeminler:
		if kesisiyor(r, a, b):
			return false
	return true

## Dogru parcasi - dikdortgen kesisimi (slab yontemi).
static func kesisiyor(r: Rect2, a: Vector2, b: Vector2) -> bool:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	for eksen in 2:
		var yon: float = d.x if eksen == 0 else d.y
		var bas: float = a.x if eksen == 0 else a.y
		var alt: float = r.position.x if eksen == 0 else r.position.y
		var ust: float = r.end.x if eksen == 0 else r.end.y
		if absf(yon) < 0.00001:
			if bas < alt or bas > ust:
				return false
			continue
		var ta := (alt - bas) / yon
		var tb := (ust - bas) / yon
		if ta > tb:
			var gecici := ta
			ta = tb
			tb = gecici
		t0 = maxf(t0, ta)
		t1 = minf(t1, tb)
		if t0 > t1:
			return false
	return true

## Tutunulabilir tum kanca noktalari (hareketli olanlar orta noktasiyla).
## Gecilebilirlik testi ve bolum kurulumu ayni listeyi gorur.
static func tum_kanca(bolum_no: int) -> Array[Vector2]:
	var d := veri(bolum_no)
	var cikti: Array[Vector2] = []
	for p: Vector2 in d["kanca"]:
		cikti.append(p)
	for h: Dictionary in d["kanca_h"]:
		cikti.append((Vector2(h["a"]) + Vector2(h["b"])) * 0.5)
	for p: Vector2 in d["kanca_k"]:
		cikti.append(p)
	return cikti

## Madalya: 0 altin, 1 gumus, 2 bronz, 3 madalya yok.
static func madalya(bolum_no: int, sure: float) -> int:
	if sure <= 0.0:
		return 3
	var m: Array = madalya_esikleri(bolum_no)
	for i in 3:
		if sure <= float(m[i]):
			return i
	return 3

const MADALYA_ADI: PackedStringArray = ["Altın", "Gümüş", "Bronz", "—"]
