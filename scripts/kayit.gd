extends Node
## user://kayit.cfg - ilerleme, en iyi sureler ve ayarlar.
## Hayalet koslari ayri dosyalarda: user://hayalet_NN.dat

const YOL := "user://kayit.cfg"
const HAYALET_YOL := "user://hayalet_%02d.dat"

var _cfg := ConfigFile.new()
## Araclar (rota botu, GIF, ekran, olcum) gercek bolum sahnelerini kosuyor;
## bitise deginde Bolum oyuncunun kaydina rekor/hayalet/acilan bolum yazardi.
## v0.5'te GIF araci 1. bolumun rekorunu ve hayaletini ezince fark edildi.
## true iken bellek degisir, diske hicbir sey yazilmaz.
var salt_okunur := false

func _ready() -> void:
	_cfg.load(YOL)
	Tuslar.uygula()
	_pencere_uygula()   # Ses autoload'i henuz yok; ses duzeyini Ses kendi _ready'sinde okur

# --- Sureler / ilerleme -----------------------------------------------

func en_iyi(bolum: int) -> float:
	return float(_cfg.get_value("sureler", str(bolum), 0.0))

## Yeni rekorsa kaydeder ve true doner.
func sure_yaz(bolum: int, sure: float) -> bool:
	var eski := en_iyi(bolum)
	if eski > 0.0 and sure >= eski:
		return false
	_cfg.set_value("sureler", str(bolum), sure)
	_yaz()
	return true

## Ustalik zinciri: bolumde yere degmeden yapilan en uzun kanca dizisi.
func akis(bolum: int) -> int:
	return int(_cfg.get_value("akis", str(bolum), 0))

## Yeni rekorsa kaydeder ve true doner.
func akis_yaz(bolum: int, zincir: int) -> bool:
	if zincir <= akis(bolum):
		return false
	_cfg.set_value("akis", str(bolum), zincir)
	_yaz()
	return true

func acik_bolum() -> int:
	return int(_cfg.get_value("ilerleme", "acik", 1))

func bolum_ac(bolum: int) -> void:
	if bolum > acik_bolum():
		_cfg.set_value("ilerleme", "acik", bolum)
		_yaz()

func sifirla() -> void:
	var ayarlar: Dictionary = {}
	if _cfg.has_section("ayarlar"):
		for a in _cfg.get_section_keys("ayarlar"):
			ayarlar[a] = _cfg.get_value("ayarlar", a)
	_cfg.clear()
	for a: String in ayarlar:
		_cfg.set_value("ayarlar", a, ayarlar[a])
	_yaz()
	for no in range(1, 40):
		DirAccess.remove_absolute(HAYALET_YOL % no)

# --- Tus atamalari ----------------------------------------------------

## Eylem -> fiziksel tus kodu. Bos sozluk = varsayilan atamalar.
func tuslar() -> Dictionary:
	var d: Dictionary = {}
	if _cfg.has_section("tuslar"):
		for eylem in _cfg.get_section_keys("tuslar"):
			d[eylem] = int(_cfg.get_value("tuslar", eylem, 0))
	return d

func tus_yaz(eylem: String, kod: int) -> void:
	_cfg.set_value("tuslar", eylem, kod)
	_yaz()
	Tuslar.uygula()

func tuslari_sifirla() -> void:
	if _cfg.has_section("tuslar"):
		_cfg.erase_section("tuslar")
		_yaz()
	Tuslar.uygula()

# --- Ayarlar ----------------------------------------------------------

const VARSAYILAN := {
	"muzik_ses": 0.7,
	"efekt_ses": 0.8,
	"muzik_acik": true,
	"efekt_acik": true,
	"tam_ekran": false,
	"hayalet_kip": 1,            ## 0 kapali, 1 kendi en iyi kosun, 2 altin hayalet (bot)
	"sarsinti": true,
	"rota_ipucu": true,          ## altin madalyadan sonra rota noktalarini isaretle
	"dokunmatik": false,         ## tek parmak semasi (mobilde zaten acik)
	"nisan_hassasiyet": 0.5,     ## 0 = genis nisan yardimi, 1 = dar ve tam nisan
}

func ayar(ad: String) -> Variant:
	return _cfg.get_value("ayarlar", ad, VARSAYILAN[ad])

func ayar_yaz(ad: String, deger: Variant) -> void:
	_cfg.set_value("ayarlar", ad, deger)
	_yaz()
	_ayarlari_uygula()

func _ayarlari_uygula() -> void:
	_pencere_uygula()
	Ses.ses_duzeyi_guncelle()

func _pencere_uygula() -> void:
	if DisplayServer.get_name().begins_with("headless"):
		return
	var mod := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if bool(ayar("tam_ekran")) \
		else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mod:
		DisplayServer.window_set_mode(mod)

# --- Hayalet ----------------------------------------------------------

## Hayalet kaydi: {"aralik": sn, "ornekler": PackedVector2Array}.
## Aralik dosyaya YAZILIR - Hayalet.ARALIK degistiginde (v0.4'te 20 -> 10 Hz)
## eski kayitlar yari hizda oynamasin. Surumsuz eski dosya yok sayilir.
func hayalet_oku(bolum: int) -> Dictionary:
	var f := FileAccess.open(HAYALET_YOL % bolum, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = f.get_var()
	f.close()
	if v is Dictionary and (v as Dictionary).get("ornekler") is PackedVector2Array:
		return v
	return {}

func hayalet_yaz(bolum: int, ornekler: PackedVector2Array, aralik: float) -> void:
	if salt_okunur:
		return
	var f := FileAccess.open(HAYALET_YOL % bolum, FileAccess.WRITE)
	if f == null:
		push_warning("Hayalet yazilamadi: bolum %d" % bolum)
		return
	f.store_var({"aralik": aralik, "ornekler": ornekler})
	f.close()

# --- Gunluk meydan okuma ----------------------------------------------

## Gunluk kayitlar ayri bolumde: ana ilerlemeyi (sureler/akis/acik) bozmaz.
## Anahtar gunun tohumu, boylece dunun rekoru bugunku bolumle karismaz.
func gunluk_en_iyi(tohum: int) -> float:
	return float(_cfg.get_value("gunluk", str(tohum), 0.0))

## Yeni rekorsa kaydeder ve true doner.
func gunluk_yaz(tohum: int, sure: float) -> bool:
	var eski := gunluk_en_iyi(tohum)
	if eski > 0.0 and sure >= eski:
		return false
	_cfg.set_value("gunluk", str(tohum), sure)
	_yaz()
	return true

# --- Ic ---------------------------------------------------------------

func _yaz() -> void:
	if salt_okunur:
		return
	var hata := _cfg.save(YOL)
	if hata != OK:
		push_warning("Kayit yazilamadi: %d" % hata)
