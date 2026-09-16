extends RefCounted
class_name Tuslar
## Tus atama. Varsayilan atamalar project.godot'ta duruyor; oyuncunun degistirdigi
## tuslar user://kayit.cfg icinde "tuslar" bolumunde saklanir ve acilista
## InputMap'e yazilir (Kayit._ready -> Tuslar.uygula).
##
## Ozel atama SADECE klavye olaylarini degistirir: fare ve gamepad atamalari
## project.godot'taki haliyle kalir (kanca_at hem sol tikla hem atanan tusla calisir).

## eylem -> ayarlar ekraninda gorunen ad. Sira ekrandaki sira.
const EYLEMLER := {
	"move_left": "Sol / geri sallan",
	"move_right": "Sağ / ileri sallan",
	"zipla": "Zıpla",
	"kanca_at": "Kanca at",
	"halat_kisalt": "Halatı kısalt",
	"halat_uzat": "Halatı uzat",
	"yeniden": "Bölümü yeniden başlat",
	"duraklat": "Duraklat",
}

static var _varsayilan: Dictionary = {}

## project.godot'taki atamalari bir kez yedekler (uzerine yazmadan once).
static func _yedekle() -> void:
	if not _varsayilan.is_empty():
		return
	for eylem: String in EYLEMLER:
		if InputMap.has_action(eylem):
			_varsayilan[eylem] = InputMap.action_get_events(eylem).duplicate()

## Kayittaki ozel atamalari InputMap'e uygular.
static func uygula() -> void:
	_yedekle()
	var ozel := Kayit.tuslar()
	for eylem: String in EYLEMLER:
		if not _varsayilan.has(eylem):
			continue
		var kod := int(ozel.get(eylem, 0))
		InputMap.action_erase_events(eylem)
		for olay: InputEvent in _varsayilan[eylem]:
			# Ozel atama varsa varsayilan KLAVYE tuslari duser; fare/gamepad kalir.
			if kod != 0 and olay is InputEventKey:
				continue
			InputMap.action_add_event(eylem, olay)
		if kod != 0:
			var k := InputEventKey.new()
			k.physical_keycode = kod
			InputMap.action_add_event(eylem, k)

## Eylemin su anki klavye tusunun okunabilir adi ("A", "Boşluk", ...).
static func tus_adi(eylem: String) -> String:
	if not InputMap.has_action(eylem):
		return "—"
	for olay: InputEvent in InputMap.action_get_events(eylem):
		if olay is InputEventKey:
			var k := olay as InputEventKey
			var kod := k.physical_keycode if k.physical_keycode != 0 else k.keycode
			return OS.get_keycode_string(kod)
	for olay: InputEvent in InputMap.action_get_events(eylem):
		if olay is InputEventMouseButton:
			return "Fare %d" % (olay as InputEventMouseButton).button_index
	return "—"
