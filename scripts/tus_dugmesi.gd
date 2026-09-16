extends Button
class_name TusDugmesi
## Tek bir eylemin tus atamasi. Basilinca "bir tusa bas" kipine girer, sonraki
## klavye tusunu yakalar ve Kayit'a yazar. Esc atamayi degistirmeden cikar.

var eylem := ""

var _bekliyor := false

static func yap(eylem_adi: String) -> TusDugmesi:
	var d := TusDugmesi.new()
	d.eylem = eylem_adi
	d.custom_minimum_size = Vector2(104, 0)
	d.add_theme_font_size_override("font_size", 11)
	return d

func _ready() -> void:
	pressed.connect(_basla)
	_yaz()

func _basla() -> void:
	_bekliyor = true
	text = "bir tuşa bas…"
	Ses.cal("menu")

func _input(olay: InputEvent) -> void:
	if not _bekliyor or not (olay is InputEventKey):
		return
	var k := olay as InputEventKey
	if not k.pressed or k.echo:
		return
	_bekliyor = false
	get_viewport().set_input_as_handled()
	var kod := k.physical_keycode if k.physical_keycode != 0 else k.keycode
	if kod != KEY_ESCAPE:
		Kayit.tus_yaz(eylem, kod)
		Ses.cal("kontrol")
	_yaz()

func _yaz() -> void:
	text = Tuslar.tus_adi(eylem)
