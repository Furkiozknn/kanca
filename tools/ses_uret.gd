extends SceneTree
## rFXGen'in urettigi 7 ham on ayardan oyunun 12 efektini uretir.
##
##   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/ses_uret.gd
##
## Ham dosyalar (tools/sesler.md'deki komutlarla uretilir):  assets/audio/_ham/*.wav
## Cikti:                                                    assets/audio/*.wav
##
## Perde (pitch) ve kirpma DOSYAYA PISIRILIR, calma aninda degil. Sebep: Godot'un
## web disa aktarmasi varsayilan olarak Sample yolunu kullaniyor ve orada
## pitch_scale sessizce yok sayiliyor (bkz. README "Web ses tuzagi"). Pisirilmis
## perde her platformda ayni duyulur.

const HAM := "res://assets/audio/_ham/%s.wav"
const CIKTI := "res://assets/audio/%s.wav"
const ORNEKLEME := 22050

## ad -> [ham on ayar, perde, kazanc, azami saniye]
const RECETE := {
	"kanca_at":    ["laser",     1.45, 0.55, 0.22],
	"kanca_tak":   ["hit",       1.10, 0.85, 0.20],
	"kanca_birak": ["blip",      0.80, 0.50, 0.14],
	"zipla":       ["jump",      1.15, 0.65, 0.26],
	"olum":        ["explosion", 0.80, 0.95, 0.55],
	"bitis":       ["powerup",   1.00, 0.90, 0.70],
	"menu":        ["blip",      1.50, 0.40, 0.09],
	"kontrol":     ["coin",      1.25, 0.70, 0.32],
	"kirilma":     ["explosion", 1.75, 0.65, 0.24],
	"madalya":     ["coin",      0.78, 0.90, 0.50],
	"firla":       ["powerup",   1.70, 0.55, 0.20],
	"akis":        ["coin",      1.60, 0.45, 0.16],
}

func _initialize() -> void:
	for ad: String in RECETE:
		var r: Array = RECETE[ad]
		var ham := _wav_oku(HAM % String(r[0]))
		if ham.is_empty():
			printerr("ham dosya okunamadi: %s" % (HAM % String(r[0])))
			continue
		var islenmis := _isle(ham, float(r[1]), float(r[2]), float(r[3]))
		_wav_yaz(CIKTI % ad, islenmis)
		print("%-14s %-10s perde %.2f  %.2f sn  %d ornek" % [
			ad, String(r[0]), float(r[1]), float(islenmis.size()) / ORNEKLEME, islenmis.size()])
	print("bitti")
	quit()

# --- WAV ------------------------------------------------------------

## 16 bit mono PCM WAV -> [-1, 1] araliginda float dizi.
func _wav_oku(yol: String) -> PackedFloat32Array:
	var f := FileAccess.open(yol, FileAccess.READ)
	if f == null:
		return PackedFloat32Array()
	var bayt := f.get_buffer(f.get_length())
	f.close()
	# "data" yigininin yerini bul (rfxgen standart yaziyor ama sabit 44 varsaymayalim)
	var i := 12
	var veri_bas := -1
	var veri_boy := 0
	while i + 8 <= bayt.size():
		var etiket := bayt.slice(i, i + 4).get_string_from_ascii()
		var boy := bayt.decode_u32(i + 4)
		if etiket == "data":
			veri_bas = i + 8
			veri_boy = boy
			break
		i += 8 + boy + (boy % 2)
	if veri_bas < 0:
		return PackedFloat32Array()
	veri_boy = mini(veri_boy, bayt.size() - veri_bas)
	var cikti := PackedFloat32Array()
	cikti.resize(veri_boy / 2)
	for n in cikti.size():
		cikti[n] = float(bayt.decode_s16(veri_bas + n * 2)) / 32768.0
	return cikti

func _wav_yaz(yol: String, ornekler: PackedFloat32Array) -> void:
	var veri := PackedByteArray()
	veri.resize(ornekler.size() * 2)
	for n in ornekler.size():
		veri.encode_s16(n * 2, int(clampf(ornekler[n], -1.0, 1.0) * 32767.0))
	var akis := AudioStreamWAV.new()
	akis.format = AudioStreamWAV.FORMAT_16_BITS
	akis.mix_rate = ORNEKLEME
	akis.stereo = false
	akis.data = veri
	var hata := akis.save_to_wav(yol)
	if hata != OK:
		printerr("yazilamadi: %s (%d)" % [yol, hata])

# --- Isleme ---------------------------------------------------------

## Dogrusal ara deger ile perde kaydirma + kirpma + tikirti onleyen sonlandirma.
func _isle(ham: PackedFloat32Array, perde: float, kazanc: float, azami_sn: float) -> PackedFloat32Array:
	var azami := int(azami_sn * ORNEKLEME)
	var boy := mini(int(ham.size() / perde), azami)
	var cikti := PackedFloat32Array()
	cikti.resize(boy)
	var sonus := maxi(int(0.012 * ORNEKLEME), 1)   # son 12 ms yumusak kapanis
	for n in boy:
		var kaynak := float(n) * perde
		var a := int(kaynak)
		var t := kaynak - float(a)
		var s0 := ham[mini(a, ham.size() - 1)]
		var s1 := ham[mini(a + 1, ham.size() - 1)]
		var v := lerpf(s0, s1, t) * kazanc
		if n >= boy - sonus:
			v *= float(boy - n) / float(sonus)
		if n < 32:
			v *= float(n) / 32.0                    # basta da tikirti olmasin
		cikti[n] = v
	return cikti
