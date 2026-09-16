extends RefCounted
class_name Gunluk
## Gunluk meydan okuma: tarihten tohumlanan bir bolum + kucuk bir degistirici.
##
## Ana ilerlemeden TAMAMEN ayri: kendi kayit yuvasi (Kayit.gunluk_yaz), bolum
## acmaz, en iyi sureyi yazmaz, hayalet kaydetmez. Amac gunde bir kez ayni
## kosulda yarisilan kisa bir kosu - her oyuncu ayni bolumu ayni degistiriciyle
## oynar cunku tohum tarihten geliyor.
##
## Degistiriciler bilerek IKI tane: ikisi de 14 bolumun hepsinde anlamli.
## (Kontrol noktasi kaldirmak gibi bir degistirici ilk 10 bolumde hicbir sey
## yapmazdi - bolumlerin cogunda kontrol noktasi yok.)

## Bolum bu kiple mi acildi. Gecis.git yalniz sahne yolu tasiyor; menu bunu
## kurar, Bolum._ready okur, menuye donuste temizlenir.
static var aktif := false

## Testler icin: >0 ise tarih yerine bu tohum kullanilir.
static var tohum_zorla := 0

const KISA_HALAT := 150.0            ## "Kısa halat" degistiricisinde azami halat
const RUZGAR_ORANI := 0.30           ## sabit ruzgarin RUZGAR_IVME icindeki payi
const RUZGAR_YONU := Vector2(-0.9, -0.44)   ## geriye ve yukari iten yan ruzgar

const DEGISTIRICILER := [
	{"ad": "Kısa halat", "aciklama": "Halat en çok %d px" % int(KISA_HALAT)},
	{"ad": "Yan rüzgâr", "aciklama": "Sürekli geri iten rüzgâr"},
]

## Gunun tohumu: yyyymmdd. Ayni gun her oyuncuda ayni bolum ve degistirici.
static func tohum() -> int:
	if tohum_zorla > 0:
		return tohum_zorla
	var t := Time.get_date_dict_from_system()
	return int(t["year"]) * 10000 + int(t["month"]) * 100 + int(t["day"])

## Tohumdan tureyen iki sayi. hash() kullaniliyor: ardisik gunlerin (tohum
## yalniz 1 artiyor) ayni bolume dusmemesi icin karistirmak gerek.
static func bolum_no() -> int:
	return 1 + absi(hash("kanca-gunluk-%d" % tohum())) % Bolumler.sayi()

static func degistirici_no() -> int:
	return absi(hash("kanca-degistirici-%d" % tohum())) % DEGISTIRICILER.size()

static func degistirici() -> Dictionary:
	return DEGISTIRICILER[degistirici_no()]

## "14. Final — Kısa halat"
static func baslik() -> String:
	return "%d. %s — %s" % [bolum_no(), Bolumler.ad(bolum_no()), String(degistirici()["ad"])]

## Degistiriciyi oyuncuya uygular. Ayarlar'daki global sabitlere DOKUNMAZ:
## oradan degistirmek normal bolumlere de sizardi (Ayarlar autoload, sahne
## degisiminde sifirlanmiyor).
static func uygula(oyuncu: Oyuncu) -> void:
	match degistirici_no():
		0:
			oyuncu.azami_halat = KISA_HALAT
		1:
			oyuncu.sabit_ruzgar = RUZGAR_YONU.normalized() * RUZGAR_ORANI
