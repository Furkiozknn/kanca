extends Node
## user://kayit.cfg uzerinden ilerleme ve en iyi sureler.

const YOL := "user://kayit.cfg"

var _cfg := ConfigFile.new()

func _ready() -> void:
	_cfg.load(YOL)

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
	_cfg.clear()
	_yaz()

func _yaz() -> void:
	var hata := _cfg.save(YOL)
	if hata != OK:
		push_warning("Kayit yazilamadi: %d" % hata)
