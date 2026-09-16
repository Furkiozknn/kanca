extends Node
## user://kayit.cfg - ilerleme, en iyi sureler ve ayarlar.
## Hayalet koslari ayri dosyalarda: user://hayalet_NN.dat

const YOL := "user://kayit.cfg"
const HAYALET_YOL := "user://hayalet_%02d.dat"

var _cfg := ConfigFile.new()

func _ready() -> void:
	_cfg.load(YOL)
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

# --- Ayarlar ----------------------------------------------------------

const VARSAYILAN := {
	"muzik_ses": 0.7,
	"efekt_ses": 0.8,
	"muzik_acik": true,
	"efekt_acik": true,
	"tam_ekran": false,
	"hayalet": true,
	"sarsinti": true,
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

## Hayalet kaydi: sabit araliklarla alinmis konum ornekleri.
func hayalet_oku(bolum: int) -> PackedVector2Array:
	var f := FileAccess.open(HAYALET_YOL % bolum, FileAccess.READ)
	if f == null:
		return PackedVector2Array()
	var v: Variant = f.get_var()
	f.close()
	return v if v is PackedVector2Array else PackedVector2Array()

func hayalet_yaz(bolum: int, ornekler: PackedVector2Array) -> void:
	var f := FileAccess.open(HAYALET_YOL % bolum, FileAccess.WRITE)
	if f == null:
		push_warning("Hayalet yazilamadi: bolum %d" % bolum)
		return
	f.store_var(ornekler)
	f.close()

# --- Ic ---------------------------------------------------------------

func _yaz() -> void:
	var hata := _cfg.save(YOL)
	if hata != OK:
		push_warning("Kayit yazilamadi: %d" % hata)
