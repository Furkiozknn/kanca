extends CharacterBody2D
class_name Oyuncu
## Kanca oyuncusu: kos-zipla (kojot suresi + zipla tamponu) ve halat kisitli sarkac.
##
## Sarkac fizigi (kanca takiliyken, her karede):
##   1. yercekimi (SALLANMA_YERCEKIMI carpanli) + ruzgar uygulanir
##   2. girdi tegetsel ivme olarak eklenir (sallanmayi buyutur)
##   3. halat kisalirsa aci momentumu korunur -> tegetsel hiz artar (pompa)
##   4. halat gergiyse disari dogru hiz bileseni silinir -> halat uzamaz
##   5. move_and_slide
##   6. konum halat cemberine geri cekilir VE kalan radyal hiz silinir (sert kisit)
## Birakinca hiza dokunulmaz; yalniz esik ustu hizda BIRAKMA_CARPANI bonusu var.
##
## Kanca ANINDA takilmaz: KANCA_UCUS_SURESI kadar halat ucar, sonra tutunur.
## Cok kisa (~3 kare) ama atisin bir agirligi olsun diye gercek bir gecikme.
##
## Hedefleme (v0.3): aday nokta puanlanir - nisan hizasi, uzaklik ve mevcut hiz
## yonune uyum. Arada duvar varsa (intersect_ray) aday sayilmaz. Basis 0,12 sn
## tamponlanir, kaybolan hedef 0,12 sn daha tutulabilir (kojot-kanca).

signal kanca_takildi(yer: Vector2)
signal kanca_koptu(hiz: Vector2, bonus: bool)
signal zipladi()
signal yere_indi(dusus_hizi: float)

## Testler, olcum botu ve ara sahneler icin girdiyi kapatir.
var girdi_aktif := true
## girdi_aktif kapaliyken yon girdisi buradan gelir (tools/olcum.gd, testler, bot).
var bot_yon := 0.0

var kanca_nokta: Node2D = null
var halat_boyu := 0.0
## Icinde bulunulan itici alanlarin toplami (bolum.gd doldurur).
var ruzgar := Vector2.ZERO

## Kameranin uygulamasi icin (bolum.gd okur): ileri bakis ofseti ve yakinlik.
var kamera_ileri := Vector2.ZERO
var kamera_yakinlik := 1.0

var _kojot := 0.0
var _tampon := 0.0
var _bakis := 1.0
var _nisan := Vector2.RIGHT
var _aday: Node2D = null
var _fare_yasi := 99.0
var _ucus := 0.0
var _ucus_hedef: Node2D = null
var _havadaydi := false
var _esnek := Vector2.ONE
var _iz_noktalar: PackedVector2Array = PackedVector2Array()

var _kanca_tampon := 0.0          ## basis saklandi, hedef bekleniyor
var _kojot_aday: Node2D = null    ## son gecerli aday (kaybolduktan sonra kisa sure tutulur)
var _kojot_aday_yasi := 99.0

var _dokunmatik := false          ## tek parmak semasi acik mi
var _dokunma_var := false
var _dokunma_yer := Vector2.ZERO  ## dunya koordinatinda son dokunma noktasi
var _dokunma_basti := false       ## bu karede dokunma basildi (karar fizikte verilir)
var _halat_dokunma := 0.0         ## bu karede dikey kaydirmadan gelen halat degisimi (px)

@onready var _gorsel: AnimatedSprite2D = $Gorsel
@onready var _halat: Line2D = $Halat
@onready var _iz: Line2D = $Iz

func _ready() -> void:
	_halat.top_level = true
	_halat.visible = false
	_iz.top_level = true
	_iz.visible = false

func _unhandled_input(olay: InputEvent) -> void:
	if olay is InputEventMouseMotion:
		_fare_yasi = 0.0
		return
	if not _dokunmatik or not girdi_aktif:
		return
	if olay is InputEventScreenTouch:
		var d := olay as InputEventScreenTouch
		_dokunma_yer = _ekrandan_dunyaya(d.position)
		if d.pressed:
			_dokunma_var = true
			# Karar fizik karesinde verilir: hedef arama isin testi yapiyor,
			# onu girdi geri cagirmasinda calistirmak hataya yol aciyor.
			_dokunma_basti = true
		else:
			_dokunma_var = false
			kanca_birak()
	elif olay is InputEventScreenDrag:
		var s := olay as InputEventScreenDrag
		_dokunma_yer = _ekrandan_dunyaya(s.position)
		# Basiliyken dikey kaydirma halati kisaltir/uzatir.
		if kancali():
			_halat_dokunma += s.relative.y

func _ekrandan_dunyaya(ekran: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * ekran

# --- Nisan -------------------------------------------------------------

## Nisan hassasiyeti 0 = genis yardim konisi, 1 = dar ve tam nisan.
func _nisan_hassasiyet() -> float:
	return clampf(float(Kayit.ayar("nisan_hassasiyet")), 0.0, 1.0)

## Nisan yonu: dokunmatikte parmak, sonra gamepad sag cubugu, sonra fare,
## hicbiri yoksa bakis yonu + yukari.
func nisan_yonu() -> Vector2:
	if _dokunmatik and _dokunma_var:
		var d := _dokunma_yer - global_position
		if d.length() > 1.0:
			return d.normalized()
	var cubuk := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if cubuk.length() > lerpf(0.5, 0.25, _nisan_hassasiyet()):
		return cubuk.normalized()
	if _fare_yasi < 2.0:
		var fare := get_global_mouse_position() - global_position
		if fare.length() > 1.0:
			return fare.normalized()
	return Vector2(_bakis, -0.75).normalized()

## Hedef ile arada kati zemin var mi (kanca duvarin arkasina takilmasin).
func gorus_var(hedef: Vector2) -> bool:
	var dunya := get_world_2d()
	if dunya == null:
		return true
	var sorgu := PhysicsRayQueryParameters2D.create(global_position, hedef, 1)
	sorgu.exclude = [get_rid()]
	return dunya.direct_space_state.intersect_ray(sorgu).is_empty()

## Nisan yonundeki, menzil icindeki en uygun kanca noktasi. Yoksa null.
## Puan = hiza*NISAN_PUAN_HIZA - uzaklik/menzil + hiz_yonu_uyumu*NISAN_PUAN_HIZ.
func en_iyi_nokta(nisan: Vector2, menzil_carpani := 1.0) -> Node2D:
	var iyi: Node2D = null
	var iyi_puan := -INF
	var menzil: float = Ayarlar.KANCA_MENZIL * menzil_carpani
	# Hassasiyet dusukken koni genisler (daha cok yardim), yuksekken daralir.
	var asgari_hiza: float = Ayarlar.NISAN_ASGARI_HIZA * lerpf(0.4, 1.35, _nisan_hassasiyet())
	var hiz_yon := Vector2.ZERO
	if velocity.length() > Ayarlar.NISAN_HIZ_ESIGI:
		hiz_yon = velocity.normalized()
	for n in get_tree().get_nodes_in_group(KancaNoktasi.GRUP):
		if not is_instance_valid(n):
			continue
		if n.has_method("kullanilabilir") and not n.kullanilabilir():
			continue
		var fark: Vector2 = n.global_position - global_position
		var uzaklik := fark.length()
		if uzaklik > menzil or uzaklik < 1.0:
			continue
		var yon := fark / uzaklik
		var hiza := yon.dot(nisan)
		if hiza < asgari_hiza:
			continue
		if not gorus_var(n.global_position):
			continue
		var puan := hiza * Ayarlar.NISAN_PUAN_HIZA - uzaklik / Ayarlar.KANCA_MENZIL
		if hiz_yon != Vector2.ZERO:
			puan += yon.dot(hiz_yon) * Ayarlar.NISAN_PUAN_HIZ
		if puan > iyi_puan:
			iyi_puan = puan
			iyi = n
	return iyi

# --- Kanca -------------------------------------------------------------

## Verilen yonde kancayi firlatir. Halat ucmaya baslarsa true.
## Hedef yoksa kojot penceresindeki son aday denenir.
func kanca_at(nisan: Vector2) -> bool:
	var n := en_iyi_nokta(nisan)
	if n == null:
		n = _kojot_adayi()
	if n == null:
		return false
	kanca_birak()
	_ucus_hedef = n
	_ucus = Ayarlar.KANCA_UCUS_SURESI
	Ses.cal("kanca_at")
	return true

## Basisi tamponlar: hedef su an yoksa KANCA_TAMPON_SURESI boyunca beklenir.
func kanca_tamponla(nisan: Vector2) -> void:
	_nisan = nisan
	_kanca_tampon = Ayarlar.KANCA_TAMPON_SURESI

## Halat boyunu px cinsinden degistirir (dokunmatik kaydirma, testler, bot).
## Gergin halatta kisaltma pompayi tetikler.
func halat_degistir(px: float) -> void:
	_halat_dokunma += px

## Kojot-kanca: hedef bir an once gecerliydiyse hala tutulabilir.
func _kojot_adayi() -> Node2D:
	if _kojot_aday_yasi > Ayarlar.KANCA_KOJOT_SURESI or not is_instance_valid(_kojot_aday):
		return null
	if _kojot_aday.has_method("kullanilabilir") and not _kojot_aday.kullanilabilir():
		return null
	var uzaklik := global_position.distance_to(_kojot_aday.global_position)
	if uzaklik > Ayarlar.KANCA_MENZIL * Ayarlar.KANCA_KOJOT_PAYI:
		return null
	if not gorus_var(_kojot_aday.global_position):
		return null
	return _kojot_aday

## Testler icin: ucus suresini beklemeden dogrudan tutunur.
func kanca_at_hemen(nisan: Vector2) -> bool:
	if not kanca_at(nisan):
		return false
	_ucus = 0.0
	_tutun()
	return kancali()

func kanca_birak() -> void:
	_ucus = 0.0
	_ucus_hedef = null
	if kanca_nokta == null:
		return
	if is_instance_valid(kanca_nokta) and kanca_nokta.has_method("bagla"):
		kanca_nokta.bagla(false)
	kanca_nokta = null
	# Momentum korunur. Bonus yalniz esik ustu hizda: dogru anda birakmak odullensin.
	var bonus: bool = velocity.length() >= Ayarlar.BIRAKMA_ESIGI
	if bonus:
		velocity = (velocity * Ayarlar.BIRAKMA_CARPANI).limit_length(Ayarlar.AZAMI_HIZ)
		Ses.cal("firla")
	else:
		Ses.cal("kanca_birak")
	kanca_koptu.emit(velocity, bonus)

func kancali() -> bool:
	return kanca_nokta != null and is_instance_valid(kanca_nokta)

func uculuyor() -> bool:
	return _ucus > 0.0

func _tutun() -> void:
	if not is_instance_valid(_ucus_hedef):
		_ucus_hedef = null
		return
	kanca_nokta = _ucus_hedef
	_ucus_hedef = null
	halat_boyu = clampf(global_position.distance_to(kanca_nokta.global_position),
		Ayarlar.KANCA_ASGARI_HALAT, Ayarlar.KANCA_AZAMI_HALAT)
	if kanca_nokta.has_method("bagla"):
		kanca_nokta.bagla(true)
	Ses.cal("kanca_tak")
	kanca_takildi.emit(kanca_nokta.global_position)

# --- Fizik -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_fare_yasi += delta
	_kojot_aday_yasi += delta
	_dokunmatik = girdi_aktif and Ayarlar.dokunmatik_mi()
	if kanca_nokta != null and not is_instance_valid(kanca_nokta):
		kanca_nokta = null

	if girdi_aktif:
		_nisan = nisan_yonu()
		if not _dokunmatik:
			if Input.is_action_just_pressed("kanca_at"):
				kanca_tamponla(_nisan)
			if Input.is_action_just_released("kanca_at"):
				kanca_birak()
		aday_guncelle(_nisan)

	# Dokunmatik: dokun = hedef varsa kanca, yoksa zipla.
	if _dokunma_basti:
		_dokunma_basti = false
		if _dokunmatik:
			_nisan = nisan_yonu()
			kanca_tamponla(_nisan)
			if en_iyi_nokta(_nisan) == null and _kojot_adayi() == null:
				_tampon = Ayarlar.ZIPLA_TAMPON_SURESI

	# Tampon: basis saklandi, bu sure icinde hedef belirirse tak.
	if _kanca_tampon > 0.0:
		_kanca_tampon -= delta
		if not kancali() and not uculuyor() and kanca_at(_nisan):
			_kanca_tampon = 0.0

	if _ucus > 0.0:
		_ucus -= delta
		if not is_instance_valid(_ucus_hedef):
			_ucus = 0.0
			_ucus_hedef = null
		elif _ucus <= 0.0:
			_tutun()

	if kancali():
		_kanca_fizigi(delta)
	else:
		_yaya_fizigi(delta)

	velocity += ruzgar * Ayarlar.RUZGAR_IVME * delta
	velocity = velocity.limit_length(Ayarlar.AZAMI_HIZ)
	var dusus := velocity.y
	move_and_slide()

	if kancali():
		_halat_kisiti()
	_inis_kontrolu(dusus)
	_gorsel_guncelle(delta)
	_kamerayi_guncelle(delta)
	_halat_ciz()
	_iz_guncelle(delta)
	queue_redraw()

func _yaya_fizigi(delta: float) -> void:
	if is_on_floor():
		_kojot = Ayarlar.KOJOT_SURESI
	else:
		velocity.y += Ayarlar.YERCEKIMI * delta
		_kojot -= delta

	var yon := _yon_girdisi()
	var carpan := 1.0 if is_on_floor() else Ayarlar.HAVA_KONTROLU
	if yon != 0.0:
		# Kancadan gelen hiz kos hizindan yuksek olabilir; onu kirmamak icin
		# sadece hedef hizin altindayken (ya da ters yonde) hizlandir.
		if absf(velocity.x) < Ayarlar.HIZ or signf(velocity.x) != signf(yon):
			velocity.x = move_toward(velocity.x, yon * Ayarlar.HIZ, Ayarlar.IVME * delta * carpan)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, Ayarlar.SURTUNME * delta)

	if girdi_aktif and not _dokunmatik and Input.is_action_just_pressed("zipla"):
		_tampon = Ayarlar.ZIPLA_TAMPON_SURESI
	else:
		_tampon -= delta

	if _tampon > 0.0 and _kojot > 0.0:
		velocity.y = -Ayarlar.ZIPLA_GUCU
		_tampon = 0.0
		_kojot = 0.0
		_esnek = Vector2(0.78, 1.28)
		Ses.cal("zipla")
		zipladi.emit()

	if girdi_aktif and not _dokunmatik and Input.is_action_just_released("zipla") and velocity.y < 0.0:
		velocity.y *= 0.45

func _kanca_fizigi(delta: float) -> void:
	var capa: Vector2 = kanca_nokta.global_position
	var fark := global_position - capa
	if fark.length() < 0.001:
		fark = Vector2.DOWN
	var disa := fark.normalized()                  # capadan oyuncuya bakan birim vektor
	var teget := Vector2(-disa.y, disa.x)
	if teget.x < 0.0:
		teget = -teget                             # saga basinca saga hizlansin

	# Sallanirken yercekimi biraz agirlastirilir: yay dibinde daha cok hiz,
	# tepede daha kisa asili kalma. Carpan tools/olcum.gd ile tarandi.
	velocity.y += Ayarlar.YERCEKIMI * Ayarlar.SALLANMA_YERCEKIMI * delta
	var girdi := _yon_girdisi()
	if _dokunmatik:
		# Tek parmak semasi: pompalama otomatik, salinim yonunde hizlanir.
		girdi = signf(velocity.dot(teget))
	velocity += teget * girdi * Ayarlar.SALLANMA_IVMESI * delta
	velocity *= 1.0 - Ayarlar.SALLANMA_SONUMU * delta

	# Halat boyu: yukari kisaltir, asagi uzatir (dokunmatikte dikey kaydirma).
	var boy_girdi := 0.0
	if girdi_aktif and not _dokunmatik:
		boy_girdi = Input.get_axis("halat_kisalt", "halat_uzat")
	# _halat_dokunma: dokunmatik kaydirma ya da bot/test istegi (px).
	var eski_boy := halat_boyu
	halat_boyu = clampf(
		halat_boyu + boy_girdi * Ayarlar.HALAT_DEGISIM_HIZI * delta + _halat_dokunma,
		Ayarlar.KANCA_ASGARI_HALAT, Ayarlar.KANCA_AZAMI_HALAT)
	_halat_dokunma = 0.0

	var gergin := fark.length() >= halat_boyu - 1.0
	# Pompa: gergin halat kisalinca aci momentumu korunur, tegetsel hiz artar.
	# (Worms ninja halati ustaligi. POMPA_VERIMI ile yumusatilir.)
	if gergin and halat_boyu < eski_boy - 0.001 and halat_boyu > 0.001:
		var kazanc := eski_boy / halat_boyu - 1.0
		velocity += teget * velocity.dot(teget) * kazanc * Ayarlar.POMPA_VERIMI
		velocity = velocity.limit_length(Ayarlar.AZAMI_HIZ)

	# Halat gergiyse disari dogru hiz bileseni yok edilir -> halat uzamaz.
	if gergin:
		var disari := velocity.dot(disa)
		if disari > 0.0:
			velocity -= disa * disari

	# Kancaliyken zipla: kopar ve momentumla firla.
	if girdi_aktif and not _dokunmatik and Input.is_action_just_pressed("zipla"):
		kanca_birak()
		velocity.y -= Ayarlar.ZIPLA_GUCU * 0.5

## Sert halat kisiti: move_and_slide sonrasi oyuncu cemberin disina cikamaz VE
## kalan radyal hiz silinir. (v0.2'de yalniz konum duzeltiliyordu; radyal hiz
## kaldigi icin sonraki kare ayni sapmayi tekrar uretiyordu - enerji kacagi.)
func _halat_kisiti() -> void:
	var capa: Vector2 = kanca_nokta.global_position
	var fark := global_position - capa
	var uzaklik := fark.length()
	if uzaklik > halat_boyu and uzaklik > 0.001:
		var disa := fark / uzaklik
		global_position = capa + disa * halat_boyu
		var disari := velocity.dot(disa)
		if disari > 0.0:
			velocity -= disa * disari

func _yon_girdisi() -> float:
	if not girdi_aktif:
		return bot_yon
	if _dokunmatik:
		return 1.0   # kosu otomatik
	return Input.get_axis("move_left", "move_right")

func _inis_kontrolu(dusus_hizi: float) -> void:
	var havada := not is_on_floor()
	if _havadaydi and not havada:
		_esnek = Vector2(1.0 + minf(dusus_hizi / 1600.0, 0.35), 1.0 - minf(dusus_hizi / 1600.0, 0.35))
		yere_indi.emit(dusus_hizi)
	_havadaydi = havada

# --- Kamera ------------------------------------------------------------

## Ileri bakan kamera: ofset hiz yonune kayar, yuksek hizda goruntu genisler.
## Degerleri bolum.gd uygular (sarsinti ofsetiyle toplanmasi gerekiyor).
func _kamerayi_guncelle(delta: float) -> void:
	var hedef := Vector2(velocity.x, velocity.y * 0.35) * Ayarlar.KAMERA_ILERI
	hedef = hedef.limit_length(Ayarlar.KAMERA_ILERI_AZAMI)
	var k := minf(delta * Ayarlar.KAMERA_ILERI_YUMUSAKLIK, 1.0)
	kamera_ileri = kamera_ileri.lerp(hedef, k)
	var oran := clampf(
		(velocity.length() - Ayarlar.KAMERA_UZAKLASMA_ESIGI)
			/ (Ayarlar.AZAMI_HIZ - Ayarlar.KAMERA_UZAKLASMA_ESIGI), 0.0, 1.0)
	kamera_yakinlik = lerpf(kamera_yakinlik, 1.0 - Ayarlar.KAMERA_UZAKLASMA * oran, k)

# --- Gorsel ------------------------------------------------------------

## Aday noktayi ve menzil disindaki noktalarin soluk halini gunceller.
func aday_guncelle(nisan: Vector2) -> void:
	_nisan = nisan
	var yeni := en_iyi_nokta(nisan)
	for n in get_tree().get_nodes_in_group(KancaNoktasi.GRUP):
		if n.has_method("menzilde"):
			n.menzilde(global_position.distance_to(n.global_position) <= Ayarlar.KANCA_MENZIL)
	if yeni != null:
		_kojot_aday = yeni
		_kojot_aday_yasi = 0.0
	if yeni == _aday:
		return
	if is_instance_valid(_aday) and _aday.has_method("vurgu"):
		_aday.vurgu(false)
	_aday = yeni
	if is_instance_valid(_aday) and _aday.has_method("vurgu"):
		_aday.vurgu(true)

## Hedef onizlemesi: secili noktaya kesik cizgi.
func _draw() -> void:
	if not girdi_aktif or kancali() or _ucus > 0.0 or not is_instance_valid(_aday):
		return
	draw_dashed_line(Vector2.ZERO, to_local(_aday.global_position),
		Color(Palet.NOKTA_VURGU, 0.42), 1.0, 4.0)

func _gorsel_guncelle(delta: float) -> void:
	if absf(velocity.x) > 5.0:
		_bakis = signf(velocity.x)
	_gorsel.flip_h = _bakis < 0.0
	var hedef: StringName
	if kancali():
		hedef = &"sallan"
	elif is_on_floor():
		hedef = &"idle" if absf(velocity.x) < 5.0 else &"yuru"
	else:
		hedef = &"zipla" if velocity.y < 0.0 else &"dus"
	if _gorsel.animation != hedef:
		_gorsel.play(hedef)
	# Esneme-sikisma: her karede 1'e dogru toparlanir.
	_esnek = _esnek.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	_gorsel.scale = _esnek

func _halat_ciz() -> void:
	if kancali():
		_halat.visible = true
		_halat.points = PackedVector2Array([global_position, kanca_nokta.global_position])
	elif _ucus > 0.0 and is_instance_valid(_ucus_hedef):
		# Ucus: halat hedefe dogru uzar.
		var t := 1.0 - _ucus / Ayarlar.KANCA_UCUS_SURESI
		_halat.visible = true
		_halat.points = PackedVector2Array([
			global_position, global_position.lerp(_ucus_hedef.global_position, t)])
	else:
		_halat.visible = false

## Hiz izi: yalniz hizliyken cizilir, yavaslayinca kendiliginden erir.
func _iz_guncelle(delta: float) -> void:
	var hizli := velocity.length() > 330.0
	if hizli:
		_iz_noktalar.append(global_position)
		while _iz_noktalar.size() > 14:
			_iz_noktalar.remove_at(0)
	elif _iz_noktalar.size() > 0:
		_iz_noktalar.remove_at(0)
	if _iz_noktalar.size() >= 2:
		_iz.visible = true
		_iz.points = _iz_noktalar
		_iz.modulate.a = clampf((velocity.length() - 300.0) / 400.0, 0.0, 0.55)
	else:
		_iz.visible = false
