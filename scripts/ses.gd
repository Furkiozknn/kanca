extends Node
## Ses yonetimi. Otomatik yuklenen (autoload) tekil.
##
## Iki veri yolu: "Muzik" ve "Efekt". Ses duzeyi OYNATICIYA DEGIL VERI YOLUNA
## yazilir (AudioServer.set_bus_volume_db). Sebep: web disa aktarmasinda Sample
## yolunda volume_db yok sayiliyor, veri yolu duzeyi ise motor karistiricisinda
## uygulandigi icin her platformda calisiyor.
##
## Efektlerin perdesi dosyaya pisirilmistir (tools/ses_uret.gd), calarken
## pitch_scale kullanilmaz - ayni sebep.

const KLASOR := "res://assets/audio/%s.wav"
const EFEKTLER: PackedStringArray = [
	"kanca_at", "kanca_tak", "kanca_birak", "zipla", "olum",
	"bitis", "menu", "kontrol", "kirilma", "madalya",
]
const ES_ZAMANLI := 8

var _akislar: Dictionary = {}
var _oynaticilar: Array[AudioStreamPlayer] = []
var _sira := 0
var _muzik: AudioStreamPlayer
var _muzik_adi := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_veri_yollarini_kur()

	for ad in EFEKTLER:
		var yol := KLASOR % ad
		if ResourceLoader.exists(yol):
			_akislar[ad] = load(yol)
	for i in ES_ZAMANLI:
		var o := AudioStreamPlayer.new()
		o.bus = "Efekt"
		add_child(o)
		_oynaticilar.append(o)

	_muzik = AudioStreamPlayer.new()
	_muzik.bus = "Muzik"
	add_child(_muzik)
	_muzik.finished.connect(_muzik_bitti)

	ses_duzeyi_guncelle()

## Veri yollari kodla kurulur; ayri bir default_bus_layout.tres dosyasina gerek yok.
func _veri_yollarini_kur() -> void:
	for ad in ["Muzik", "Efekt"]:
		if AudioServer.get_bus_index(ad) == -1:
			var i := AudioServer.bus_count
			AudioServer.add_bus(i)
			AudioServer.set_bus_name(i, ad)
			AudioServer.set_bus_send(i, "Master")

# --- Calma ------------------------------------------------------------

func cal(ad: String) -> void:
	if not _akislar.has(ad) or not bool(Kayit.ayar("efekt_acik")):
		return
	var o := _oynaticilar[_sira]
	_sira = (_sira + 1) % _oynaticilar.size()
	o.stream = _akislar[ad]
	o.play()

## Dongulu muzik. Ayni parca zaten caliyorsa dokunmaz.
func muzik_cal(ad: String) -> void:
	if _muzik_adi == ad:
		return
	_muzik_adi = ad
	var yol := KLASOR % ad
	if not ResourceLoader.exists(yol):
		_muzik.stop()
		return
	_muzik.stream = load(yol)
	if bool(Kayit.ayar("muzik_acik")):
		_muzik.play()

func muzik_dur() -> void:
	_muzik_adi = ""
	_muzik.stop()

## Web'de dongu bayragi guvenilmez; parca bitince elle bastan baslatiyoruz.
func _muzik_bitti() -> void:
	if _muzik_adi != "" and bool(Kayit.ayar("muzik_acik")):
		_muzik.play()

# --- Ses duzeyi -------------------------------------------------------

func ses_duzeyi_guncelle() -> void:
	_yol_duzeyi("Muzik", float(Kayit.ayar("muzik_ses")), bool(Kayit.ayar("muzik_acik")))
	_yol_duzeyi("Efekt", float(Kayit.ayar("efekt_ses")), bool(Kayit.ayar("efekt_acik")))
	if _muzik != null:
		if bool(Kayit.ayar("muzik_acik")):
			if _muzik_adi != "" and not _muzik.playing:
				_muzik.play()
		else:
			_muzik.stop()

func _yol_duzeyi(ad: String, oran: float, acik: bool) -> void:
	var i := AudioServer.get_bus_index(ad)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, not acik or oran <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(clampf(oran, 0.0001, 1.0)))
