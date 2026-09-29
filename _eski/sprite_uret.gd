extends SceneTree
## Tum pixel art varliklarini kodla uretir (GUI araci yok, Pillow yok).
## Calistirma:
##   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/sprite_uret.gd
##
## Cikti:
##   assets/sprites/*.png          - oyunun kullandigi sprite'lar
##   docs/sprite_onizleme.png      - hepsi 4x buyutulmus tek sayfa (gozle kontrol icin)
##
## Renkler yalniz scripts/palet.gd icinden gelir. Uretim deterministik (sabit tohum),
## yani her calistirmada birebir ayni PNG cikar.

const CIKTI := "res://assets/sprites/"
const TOHUM := 20260916

var _rng := RandomNumberGenerator.new()

func _initialize() -> void:
	_rng.seed = TOHUM
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CIKTI))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/"))

	var uretilen: Array = []
	uretilen.append(["oyuncu", _oyuncu()])
	uretilen.append(["karo", _karo_seti()])
	uretilen.append(["kanca_noktasi", _kanca_noktalari()])
	uretilen.append(["diken", _diken()])
	uretilen.append(["bayrak", _bayrak()])
	uretilen.append(["kontrol", _kontrol()])
	uretilen.append(["logo", _logo()])
	uretilen.append(["madalya", _madalya()])
	uretilen.append(["parcacik", _parcacik()])
	uretilen.append(["ruzgar", _ruzgar()])
	uretilen.append(["arka_gok", _arka_gok()])
	uretilen.append(["arka_bulut", _arka_bulut()])
	uretilen.append(["arka_uzak", _arka_ada(320, 180, 3, Palet.GOK_ORTA, Palet.GOK_UST, 0.55)])
	# Yakin katman koyu siluet: onde durur, oynanis geometrisiyle karismaz.
	uretilen.append(["arka_yakin", _arka_ada(320, 180, 2, Palet.GOK_DIP, Palet.KAYA_KOYU, 1.0)])

	for c: Array in uretilen:
		var im: Image = c[1]
		var yol: String = CIKTI + String(c[0]) + ".png"
		var hata: int = im.save_png(yol)
		if hata != OK:
			printerr("yazilamadi: %s (%d)" % [yol, hata])
		else:
			print("%-16s %dx%d" % [c[0], im.get_width(), im.get_height()])

	_onizleme(uretilen)
	print("bitti")
	quit()

# =====================================================================
# Cizim yardimcilari
# =====================================================================

func _bos(g: int, y: int) -> Image:
	var i := Image.create(g, y, false, Image.FORMAT_RGBA8)
	i.fill(Color(0, 0, 0, 0))
	return i

func _nokta(img: Image, x: int, y: int, renk: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, renk)

## x ekseninde sarmalar - yatay dosenebilir arka planlar icin.
func _nokta_sarmal(img: Image, x: int, y: int, renk: Color) -> void:
	if y < 0 or y >= img.get_height():
		return
	img.set_pixel(posmod(x, img.get_width()), y, renk)

func _kutu(img: Image, x: int, y: int, g: int, h: int, renk: Color) -> void:
	for j in h:
		for i in g:
			_nokta(img, x + i, y + j, renk)

func _elips(img: Image, cx: float, cy: float, rx: float, ry: float, renk: Color, sarmal := false) -> void:
	for j in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for i in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (i - cx) / maxf(rx, 0.001)
			var dy := (j - cy) / maxf(ry, 0.001)
			if dx * dx + dy * dy <= 1.0:
				if sarmal:
					_nokta_sarmal(img, i, j, renk)
				else:
					_nokta(img, i, j, renk)

func _halka(img: Image, cx: float, cy: float, r: float, kalinlik: float, renk: Color) -> void:
	var ic := r - kalinlik
	for j in range(int(cy - r) - 1, int(cy + r) + 2):
		for i in range(int(cx - r) - 1, int(cx + r) + 2):
			var d := Vector2(i - cx, j - cy).length()
			if d <= r and d >= ic:
				_nokta(img, i, j, renk)

## ASCII haritayi Image'e cevirir. Her satir esit uzunlukta olmali.
func _harita(satirlar: Array, renkler: Dictionary) -> Image:
	var g: int = String(satirlar[0]).length()
	var img := _bos(g, satirlar.size())
	for y in satirlar.size():
		var s := String(satirlar[y])
		assert(s.length() == g, "satir %d uzunlugu %d, beklenen %d" % [y, s.length(), g])
		for x in g:
			var ch := s[x]
			if renkler.has(ch):
				img.set_pixel(x, y, renkler[ch])
	return img

func _yatay_birlestir(parcalar: Array) -> Image:
	var g := 0
	var h := 0
	for p: Image in parcalar:
		g += p.get_width()
		h = maxi(h, p.get_height())
	var img := _bos(g, h)
	var x := 0
	for p: Image in parcalar:
		img.blit_rect(p, Rect2i(Vector2i.ZERO, p.get_size()), Vector2i(x, 0))
		x += p.get_width()
	return img

func _kaydir(satirlar: Array, ilk: int, son: int, dx: int) -> Array:
	var yeni: Array = satirlar.duplicate()
	for y in range(ilk, son + 1):
		var s := String(yeni[y])
		if dx > 0:
			yeni[y] = ".".repeat(dx) + s.substr(0, s.length() - dx)
		elif dx < 0:
			yeni[y] = s.substr(-dx) + ".".repeat(-dx)
	return yeni

func _aynala(satirlar: Array) -> Array:
	var yeni: Array = []
	for s: String in satirlar:
		yeni.append(s.reverse())
	return yeni

# =====================================================================
# Oyuncu - 16x24, 10 kare
# =====================================================================

const UST_DUR := [
	"................",
	"................",
	"................",
	"....kkkkkk......",
	"...kssssssk.....",
	"..kssssssssk....",
	"..kstttttttk....",
	"..ksttettetk....",
	"..kttttttttk....",
	"...kttttttk.....",
	"...kaaaaaak.....",
	"..kaaaaaaaak....",
	"..kggggggggk....",
	".akgggGGgggk....",
	"..kggggggggk....",
	".tkGGGGGGGGkt...",
	"..kppppppppk....",
	"..kppppppppk....",
]

const UST_ASILI := [
	"................",
	"................",
	"................",
	"....kkkkkk......",
	"...kssssssk.....",
	"..kssssssssk....",
	"..kstttttttk....",
	"..ksttettetk....",
	"..kttttttttk....",
	".t.kttttttk..t..",
	".gkkaaaaaakkg...",
	".gkaaaaaaaakg...",
	"..kggggggggk....",
	"..kgggGGgggk....",
	"..kggggggggk....",
	"..kGGGGGGGGk....",
	"..kppppppppk....",
	"..kppppppppk....",
]

const BACAK_DUR := [
	"..kpppk.kpppk...",
	"..kpppk.kpppk...",
	"..kPPPk.kPPPk...",
	"..kbbbk.kbbbk...",
	"..kbbbk.kbbbk...",
	"..kkkkk.kkkkk...",
]

const BACAK_KOS1 := [
	"...kppppk.......",
	"..kppp..kppk....",
	"..kpp....kppk...",
	".kbbk.....kbbk..",
	".kbbk......kbk..",
	".kkkk......kkk..",
]

const BACAK_KOS2 := [
	"..kppppppk......",
	"..kpppppk.......",
	"..kppk.kppk.....",
	"..kbbk.kbbk.....",
	"..kbbk..kbk.....",
	"..kkkk..kkk.....",
]

const BACAK_TUCK := [
	"................",
	"..kppppppk......",
	".kppk.kppk......",
	".kbbk.kbbk......",
	".kkk...kkk......",
	"................",
]

const BACAK_ACIK := [
	"..kppk.kppk.....",
	".kppk...kppk....",
	".kpk.....kpk....",
	".kbk.....kbk....",
	"kbbk.....kbbk...",
	"kkkk.....kkkk...",
]

const BACAK_SALLAN := [
	"..kppppk........",
	"..kpppppk.......",
	"...kppppk.......",
	"....kbbbk.......",
	"....kbbbk.......",
	"....kkkkk.......",
]

func _oyuncu_renkleri() -> Dictionary:
	return {
		"k": Palet.CIZGI, "t": Palet.TEN, "e": Palet.CIZGI, "s": Palet.SAC,
		"g": Palet.CEKET, "G": Palet.CEKET_K, "a": Palet.ATKI,
		"p": Palet.PANTOLON, "P": Palet.PANTOLON_K, "b": Palet.BOT,
	}

func _kare(ust: Array, bacak: Array) -> Image:
	return _harita(ust + bacak, _oyuncu_renkleri())

func _oyuncu() -> Image:
	var ust_kos := _kaydir(UST_DUR, 3, 9, 1)
	ust_kos[13] = "aakgggGGgggk...."
	var ust_dur_2 := UST_DUR.duplicate()
	ust_dur_2.remove_at(17)
	ust_dur_2.insert(0, "................")   # bir piksel asagi - nefes alma
	var ust_asili_2 := _kaydir(UST_ASILI, 3, 9, 1)

	return _yatay_birlestir([
		_kare(UST_DUR, BACAK_DUR),                       # 0 bekle
		_kare(ust_dur_2, BACAK_DUR),                     # 1 bekle
		_kare(ust_kos, BACAK_KOS1),                      # 2 kos
		_kare(ust_kos, BACAK_KOS2),                      # 3 kos
		_kare(ust_kos, _aynala(BACAK_KOS1)),             # 4 kos
		_kare(ust_kos, _aynala(BACAK_KOS2)),             # 5 kos
		_kare(UST_ASILI, BACAK_TUCK),                    # 6 zipla
		_kare(UST_ASILI, BACAK_ACIK),                    # 7 dus
		_kare(UST_ASILI, BACAK_SALLAN),                  # 8 sallan
		_kare(ust_asili_2, BACAK_SALLAN),                # 9 sallan
	])

# =====================================================================
# Karo seti - 16x16, 4 sutun x 3 satir
# =====================================================================

const KARO := 16

## sol/sag/ust/alt: o kenar aciksa (disarisi bosluk) kenar isleme uygulanir.
func _tek_karo(sol: bool, sag: bool, ust: bool, alt: bool) -> Image:
	var img := _bos(KARO, KARO)
	_kutu(img, 0, 0, KARO, KARO, Palet.KAYA_ORTA)

	# Dokular: deterministik benek ve catlak
	for i in 26:
		var x := _rng.randi_range(1, KARO - 2)
		var y := _rng.randi_range(2, KARO - 2)
		_nokta(img, x, y, Palet.KAYA_KOYU if _rng.randf() < 0.6 else Palet.KAYA_ACIK)

	if ust:
		# Yosun kapagi + parlak kenar cizgisi
		_kutu(img, 0, 0, KARO, 1, Palet.YOSUN_ACIK)
		_kutu(img, 0, 1, KARO, 2, Palet.YOSUN)
		_kutu(img, 0, 3, KARO, 1, Palet.YOSUN_KOYU)
		for x in KARO:
			if (x + 1) % 4 == 0:
				_nokta(img, x, 3, Palet.YOSUN)
				_nokta(img, x, 4, Palet.YOSUN_KOYU)
	else:
		_kutu(img, 0, 0, KARO, 1, Palet.KAYA_ACIK)

	if alt:
		_kutu(img, 0, KARO - 2, KARO, 2, Palet.KAYA_KOYU)
		for x in KARO:
			if x % 5 == 2:
				_nokta(img, x, KARO - 3, Palet.KAYA_KOYU)
	if sol:
		_kutu(img, 0, 0, 1, KARO, Palet.KAYA_KOYU)
		_kutu(img, 1, 4 if ust else 1, 1, KARO - (5 if ust else 2), Palet.KAYA_ACIK)
	if sag:
		_kutu(img, KARO - 1, 0, 1, KARO, Palet.KAYA_KOYU)
		_kutu(img, KARO - 2, 4 if ust else 1, 1, KARO - (5 if ust else 2), Palet.KAYA_KOYU)
	return img

func _karo_seti() -> Image:
	var img := _bos(KARO * 4, KARO * 3)
	var satirlar := [[true, false], [false, false], [false, true]]   # [ust, alt]
	var sutunlar := [[true, false], [false, false], [false, true], [true, true]]  # [sol, sag]
	for sy in 3:
		for sx in 4:
			var k := _tek_karo(sutunlar[sx][0], sutunlar[sx][1], satirlar[sy][0], satirlar[sy][1])
			img.blit_rect(k, Rect2i(Vector2i.ZERO, k.get_size()), Vector2i(sx * KARO, sy * KARO))
	return img

# =====================================================================
# Kanca noktalari - 16x16 x3 (sabit / hareketli / kirilgan)
# =====================================================================

## Kanca noktasi oyunun tek etkilesim noktasi - uzaktan net secilmeli.
## Ucan kucuk kaya + altinda kalin, parlak demir halka.
func _tek_nokta(halka_renk: Color, catlak: bool) -> Image:
	var img := _bos(16, 16)
	# Ucan kaya parcasi (ustte)
	_elips(img, 8.0, 3.0, 6.0, 3.2, Palet.CIZGI)
	_elips(img, 8.0, 2.8, 5.0, 2.4, Palet.KAYA_ACIK)
	_elips(img, 7.5, 2.0, 3.4, 1.2, Palet.KAYA_KENAR)
	if catlak:
		for y in range(0, 6):
			_nokta(img, 8 + (y % 2), y, Palet.CIZGI)
	# Askı
	_kutu(img, 7, 4, 2, 3, Palet.CIZGI)
	_nokta(img, 7, 4, halka_renk)
	# Kalin halka: disi koyu konturlu, ici parlak
	_halka(img, 8.0, 10.5, 5.4, 2.6, Palet.CIZGI)
	_halka(img, 8.0, 10.5, 4.6, 1.8, halka_renk)
	_nokta(img, 5, 9, Palet.NOKTA_VURGU)
	_nokta(img, 5, 10, Palet.NOKTA_VURGU)
	return img

func _kanca_noktalari() -> Image:
	return _yatay_birlestir([
		_tek_nokta(Palet.NOKTA, false),
		_tek_nokta(Palet.RUZGAR, false),
		_tek_nokta(Palet.NOKTA_KIRIK, true),
	])

# =====================================================================
# Diken - 16x16 (yukari bakan; tavan icin flip_v)
# =====================================================================

## Karonun TAMAMINI doldurur (8 degil 16 px). Iki sebep:
##   1. Carpisma alani veri tablosunda 16 px; 8 px cizmek gorunmeyen bir
##      oldurme bandi birakiyordu.
##   2. Azami hizda (900 px/sn) oyuncu karede 15 px gidiyor; 8 px'lik bant
##      tunellemeye acik.
func _diken() -> Image:
	var img := _bos(16, 16)
	const UC := 12   ## sivri kisim, kalani taban bandi
	for d in 2:
		var x0 := d * 8
		for y in 16:
			if y >= UC:
				for x in 8:
					var t: Color = Palet.CIZGI if (x == 0 or y == 15) else Palet.TEHLIKE
					_nokta(img, x0 + x, y, t)
				continue
			var yari := clampi(int(float(y) * 4.0 / float(UC)) + 1, 1, 4)
			for x in range(4 - yari, 4 + yari):
				var renk: Color = Palet.TEHLIKE_ACIK if x < 4 else Palet.TEHLIKE
				if x == 4 - yari or x == 4 + yari - 1:
					renk = Palet.CIZGI
				_nokta(img, x0 + x, y, renk)
		_nokta(img, x0 + 3, 0, Palet.NOKTA_VURGU)
	return img

# =====================================================================
# Bitis bayragi 16x32, kontrol noktasi 16x24 x2
# =====================================================================

func _bayrak() -> Image:
	var img := _bos(16, 32)
	_kutu(img, 3, 0, 1, 32, Palet.CIZGI)
	_kutu(img, 4, 0, 2, 32, Palet.KAYA_KENAR)
	_kutu(img, 6, 0, 1, 32, Palet.CIZGI)
	for y in range(2, 15):
		var g := 9 - absi(y - 8)
		_kutu(img, 7, y, g, 1, Palet.BITIS if (y + 1) % 4 != 0 else Palet.YOSUN)
		_nokta(img, 7 + g, y, Palet.CIZGI)
	_kutu(img, 1, 29, 6, 3, Palet.KAYA_ORTA)
	_kutu(img, 1, 29, 6, 1, Palet.KAYA_ACIK)
	return img

func _tek_kontrol(aktif: bool) -> Image:
	var img := _bos(16, 24)
	var ana: Color = Palet.NOKTA_BAGLI if aktif else Palet.NOKTA
	_kutu(img, 7, 4, 1, 20, Palet.CIZGI)
	_kutu(img, 8, 4, 1, 20, ana)
	_halka(img, 8.0, 5.0, 4.6, 1.4, Palet.CIZGI)
	_halka(img, 8.0, 5.0, 3.4, 1.8, ana)
	if aktif:
		_elips(img, 8.0, 5.0, 1.6, 1.6, Palet.NOKTA_VURGU)
	_kutu(img, 4, 22, 8, 2, Palet.KAYA_ORTA)
	_kutu(img, 4, 22, 8, 1, Palet.KAYA_ACIK)
	return img

func _kontrol() -> Image:
	return _yatay_birlestir([_tek_kontrol(false), _tek_kontrol(true)])

# =====================================================================
# Logo "KANCA" - 7x9 harfler, 2x buyutulup koyu kontur cekilir
# =====================================================================

const HARFLER := {
	"K": ["XX...XX", "XX..XX.", "XX.XX..", "XXXX...", "XXX....", "XXXX...", "XX.XX..", "XX..XX.", "XX...XX"],
	"A": ["..XXX..", ".XX.XX.", "XX...XX", "XX...XX", "XXXXXXX", "XX...XX", "XX...XX", "XX...XX", "XX...XX"],
	"N": ["XX...XX", "XXX..XX", "XXXX.XX", "XX.XXXX", "XX..XXX", "XX...XX", "XX...XX", "XX...XX", "XX...XX"],
	"C": ["..XXXX.", ".XX..XX", "XX.....", "XX.....", "XX.....", "XX.....", "XX.....", ".XX..XX", "..XXXX."],
}

func _logo() -> Image:
	const YAZI := "KANCA"
	const OLCEK := 2
	const ARA := 4
	var harf_g := 7 * OLCEK
	var harf_y := 9 * OLCEK
	var g := YAZI.length() * harf_g + (YAZI.length() - 1) * ARA + 2
	var img := _bos(g, harf_y + 3)

	# Once dolgu, sonra kontur: konturu dolgunun komsu piksellerine ciziyoruz.
	var dolu: Array[Vector2i] = []
	for i in YAZI.length():
		var desen: Array = HARFLER[YAZI[i]]
		var x0 := 1 + i * (harf_g + ARA)
		for y in desen.size():
			var s := String(desen[y])
			for x in s.length():
				if s[x] != "X":
					continue
				for oy in OLCEK:
					for ox in OLCEK:
						dolu.append(Vector2i(x0 + x * OLCEK + ox, 1 + y * OLCEK + oy))
	for p: Vector2i in dolu:
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				_nokta(img, p.x + dx, p.y + dy, Palet.CIZGI)
	for p: Vector2i in dolu:
		# Ustten alta hafif degrade: altin -> bronz
		var t := float(p.y) / float(harf_y)
		_nokta(img, p.x, p.y, Palet.ALTIN.lerp(Palet.BRONZ, t * 0.55))
	return img

# =====================================================================
# Madalya 12x12 x3, parcacik, ruzgar cizgisi
# =====================================================================

func _tek_madalya(renk: Color) -> Image:
	var img := _bos(12, 12)
	_kutu(img, 3, 0, 2, 3, Palet.ATKI)
	_kutu(img, 7, 0, 2, 3, Palet.ATKI)
	_elips(img, 5.5, 7.0, 4.6, 4.6, Palet.CIZGI)
	_elips(img, 5.5, 7.0, 3.6, 3.6, renk)
	_elips(img, 4.5, 5.8, 1.4, 1.2, Palet.NOKTA_VURGU)
	return img

func _madalya() -> Image:
	return _yatay_birlestir([
		_tek_madalya(Palet.ALTIN), _tek_madalya(Palet.GUMUS), _tek_madalya(Palet.BRONZ),
	])

func _parcacik() -> Image:
	var img := _bos(4, 4)
	_kutu(img, 0, 0, 4, 4, Color(1, 1, 1, 1))
	_nokta(img, 0, 0, Color(1, 1, 1, 0.5))
	_nokta(img, 3, 0, Color(1, 1, 1, 0.5))
	_nokta(img, 0, 3, Color(1, 1, 1, 0.5))
	_nokta(img, 3, 3, Color(1, 1, 1, 0.5))
	return img

func _ruzgar() -> Image:
	var img := _bos(16, 3)
	for x in 16:
		var a := 1.0 - absf(x - 7.5) / 8.0
		_nokta(img, x, 1, Color(1, 1, 1, a))
		if x > 3 and x < 12:
			_nokta(img, x, 0, Color(1, 1, 1, a * 0.4))
	return img

# =====================================================================
# Arka plan katmanlari (yatay dosenebilir)
# =====================================================================

func _arka_gok() -> Image:
	var img := _bos(8, 180)
	for y in 180:
		var t := float(y) / 179.0
		var renk: Color = Palet.GOK_UST.lerp(Palet.GOK_ORTA, minf(t * 1.6, 1.0))
		if t > 0.62:
			renk = Palet.GOK_ORTA.lerp(Palet.GOK_DIP, (t - 0.62) / 0.38)
		_kutu(img, 0, y, 8, 1, renk)
	return img

func _arka_bulut() -> Image:
	var img := _bos(256, 96)
	var r := RandomNumberGenerator.new()
	r.seed = TOHUM + 7
	for i in 9:
		var cx := r.randf_range(0.0, 256.0)
		var cy := r.randf_range(20.0, 72.0)
		var olcek := r.randf_range(0.7, 1.5)
		for j in 5:
			var ox := cx + (j - 2) * 11.0 * olcek
			var oy := cy - absf(j - 2) * 2.0 * olcek
			_elips(img, ox, oy + 2.0, 14.0 * olcek, 6.0 * olcek, Palet.BULUT_KOYU, true)
		for j in 4:
			var ox := cx + (j - 1.5) * 10.0 * olcek
			_elips(img, ox, cy - 1.0, 11.0 * olcek, 4.5 * olcek, Palet.BULUT_ACIK, true)
	return img

## Ucan kaya adalari: ustu yosunlu elips, altinda asagi incelen konik kuyruk.
func _arka_ada(g: int, h: int, adet: int, koyu: Color, acik: Color, doygunluk: float) -> Image:
	var img := _bos(g, h)
	var r := RandomNumberGenerator.new()
	r.seed = TOHUM + adet * 13
	for i in adet:
		var cx := (float(i) + 0.5) * float(g) / float(adet) + r.randf_range(-30.0, 30.0)
		var cy := r.randf_range(58.0, 116.0)
		var rx := r.randf_range(38.0, 62.0)
		var ry := r.randf_range(9.0, 15.0)
		var derinlik := ry * r.randf_range(3.0, 5.0)
		var adim := int(derinlik)
		for j in adim:
			var t := float(j) / float(adim)
			var yari := rx * (1.0 - t) * (1.0 - t * 0.4)
			_elips(img, cx, cy + j, maxf(yari, 1.0), 1.2, koyu, true)
		_elips(img, cx, cy, rx, ry, koyu, true)
		_elips(img, cx, cy - ry * 0.35, rx * 0.92, ry * 0.6, acik, true)
		# Ust kenar cizgisi arka planin KENDI renginden - yesil yosun YOK.
		# Oynanis zemininin yesil kapagi tek basina "buraya basilir" demeli;
		# arka plan adalari yosunlu olunca oyuncu hangisinin platform oldugunu
		# ayirt edemiyor (ilk ekran goruntusunde yakalandi).
		var kenar: Color = acik.lerp(Palet.BULUT_KOYU, 0.35 * doygunluk)
		for x in range(int(cx - rx), int(cx + rx) + 1):
			var dx := (x - cx) / rx
			var yy := cy - ry * sqrt(maxf(0.0, 1.0 - dx * dx))
			_nokta_sarmal(img, x, int(yy), kenar)
	return img

# =====================================================================
# Onizleme sayfasi
# =====================================================================

func _onizleme(uretilen: Array) -> void:
	var olcek := 4
	var kenar := 8
	var g := 0
	var h := kenar
	var satir_y: Array = []
	for c: Array in uretilen:
		var im: Image = c[1]
		satir_y.append(h)
		g = maxi(g, im.get_width() * olcek + kenar * 2)
		h += im.get_height() * olcek + kenar
	var sayfa := Image.create(g, h, false, Image.FORMAT_RGBA8)
	sayfa.fill(Color(0.12, 0.10, 0.16, 1.0))
	for i in uretilen.size():
		var im: Image = (uretilen[i][1] as Image).duplicate()
		im.resize(im.get_width() * olcek, im.get_height() * olcek, Image.INTERPOLATE_NEAREST)
		im.convert(Image.FORMAT_RGBA8)
		sayfa.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(kenar, satir_y[i]))
	sayfa.save_png("res://docs/sprite_onizleme.png")
	print("onizleme: res://docs/sprite_onizleme.png")
