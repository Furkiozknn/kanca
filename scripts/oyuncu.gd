extends CharacterBody2D
class_name Oyuncu
## Kanca oyuncusu: kos-zipla (kojot suresi + zipla tamponu) ve halat kisitli sarkac.
##
## Sarkac fizigi (kanca takiliyken, her karede):
##   1. yercekimi uygulanir
##   2. girdi tegetsel ivme olarak eklenir (sallanmayi buyutur)
##   3. halat gergiyse disari dogru hiz bileseni silinir -> halat uzamaz
##   4. move_and_slide
##   5. konum halat cemberine geri cekilir (sayisal kayma duzeltmesi)
## Birakinca hiza dokunulmaz (kucuk BIRAKMA_CARPANI disinda) -> momentum korunur.

## Testler ve ara sahneler icin girdiyi kapatir.
var girdi_aktif := true

var kanca_nokta: Node2D = null
var halat_boyu := 0.0

var _kojot := 0.0
var _tampon := 0.0
var _bakis := 1.0
var _nisan := Vector2.RIGHT
var _aday: Node2D = null
var _fare_yasi := 99.0

@onready var _gorsel: AnimatedSprite2D = $Gorsel
@onready var _halat: Line2D = $Halat

func _ready() -> void:
	_halat.top_level = true
	_halat.visible = false

func _unhandled_input(olay: InputEvent) -> void:
	if olay is InputEventMouseMotion:
		_fare_yasi = 0.0

# --- Nisan -------------------------------------------------------------

## Nisan yonu: once gamepad sag cubugu, sonra fare, ikisi de yoksa bakis yonu + yukari.
func nisan_yonu() -> Vector2:
	var cubuk := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if cubuk.length() > 0.35:
		return cubuk.normalized()
	if _fare_yasi < 2.0:
		var fare := get_global_mouse_position() - global_position
		if fare.length() > 1.0:
			return fare.normalized()
	return Vector2(_bakis, -0.75).normalized()

## Nisan yonundeki, menzil icindeki en uygun kanca noktasi. Yoksa null.
func en_iyi_nokta(nisan: Vector2) -> Node2D:
	var iyi: Node2D = null
	var iyi_puan := -INF
	for n in get_tree().get_nodes_in_group(KancaNoktasi.GRUP):
		if not is_instance_valid(n):
			continue
		var fark: Vector2 = n.global_position - global_position
		var uzaklik := fark.length()
		if uzaklik > Ayarlar.KANCA_MENZIL or uzaklik < 1.0:
			continue
		var puan := (fark / uzaklik).dot(nisan)
		if puan < Ayarlar.NISAN_ASGARI_HIZA:
			continue
		# Hizali olan agir basar, benzer hizada yakin olan kazanir.
		puan = puan * 2.0 - uzaklik / Ayarlar.KANCA_MENZIL
		if puan > iyi_puan:
			iyi_puan = puan
			iyi = n
	return iyi

# --- Kanca -------------------------------------------------------------

## Verilen yonde kanca atmayi dener. Takildiysa true.
func kanca_at(nisan: Vector2) -> bool:
	var n := en_iyi_nokta(nisan)
	if n == null:
		return false
	kanca_birak()
	kanca_nokta = n
	halat_boyu = clampf(global_position.distance_to(n.global_position),
		Ayarlar.KANCA_ASGARI_HALAT, Ayarlar.KANCA_AZAMI_HALAT)
	if n.has_method("bagla"):
		n.bagla(true)
	return true

func kanca_birak() -> void:
	if kanca_nokta == null:
		return
	if is_instance_valid(kanca_nokta) and kanca_nokta.has_method("bagla"):
		kanca_nokta.bagla(false)
	kanca_nokta = null
	# Momentum korunur; kucuk bir firlama bonusu disinda hiza dokunulmaz.
	velocity = (velocity * Ayarlar.BIRAKMA_CARPANI).limit_length(Ayarlar.AZAMI_HIZ)

func kancali() -> bool:
	return kanca_nokta != null and is_instance_valid(kanca_nokta)

# --- Fizik -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_fare_yasi += delta
	if kanca_nokta != null and not is_instance_valid(kanca_nokta):
		kanca_nokta = null

	if girdi_aktif:
		_nisan = nisan_yonu()
		if Input.is_action_just_pressed("kanca_at"):
			kanca_at(_nisan)
		if Input.is_action_just_released("kanca_at"):
			kanca_birak()
		_aday_guncelle()

	if kancali():
		_kanca_fizigi(delta)
	else:
		_yaya_fizigi(delta)

	velocity = velocity.limit_length(Ayarlar.AZAMI_HIZ)
	move_and_slide()

	if kancali():
		_halat_kisiti()
	_gorsel_guncelle()
	_halat_ciz()

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

	if girdi_aktif and Input.is_action_just_pressed("zipla"):
		_tampon = Ayarlar.ZIPLA_TAMPON_SURESI
	else:
		_tampon -= delta

	if _tampon > 0.0 and _kojot > 0.0:
		velocity.y = -Ayarlar.ZIPLA_GUCU
		_tampon = 0.0
		_kojot = 0.0

	if girdi_aktif and Input.is_action_just_released("zipla") and velocity.y < 0.0:
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

	velocity.y += Ayarlar.YERCEKIMI * delta
	velocity += teget * _yon_girdisi() * Ayarlar.SALLANMA_IVMESI * delta
	velocity *= 1.0 - Ayarlar.SALLANMA_SONUMU * delta

	# Halat boyu: yukari kisaltir, asagi uzatir.
	var boy_girdi := 0.0
	if girdi_aktif:
		boy_girdi = Input.get_axis("halat_kisalt", "halat_uzat")
	halat_boyu = clampf(halat_boyu + boy_girdi * Ayarlar.HALAT_DEGISIM_HIZI * delta,
		Ayarlar.KANCA_ASGARI_HALAT, Ayarlar.KANCA_AZAMI_HALAT)

	# Halat gergiyse disari dogru hiz bileseni yok edilir -> halat uzamaz.
	if fark.length() >= halat_boyu - 1.0:
		var disari := velocity.dot(disa)
		if disari > 0.0:
			velocity -= disa * disari

	# Kancaliyken zipla: kopar ve momentumla firla.
	if girdi_aktif and Input.is_action_just_pressed("zipla"):
		kanca_birak()
		velocity.y -= Ayarlar.ZIPLA_GUCU * 0.5

## move_and_slide sonrasi sayisal kaymayi duzeltir: oyuncu halat cemberinin disina cikamaz.
func _halat_kisiti() -> void:
	var capa: Vector2 = kanca_nokta.global_position
	var fark := global_position - capa
	var uzaklik := fark.length()
	if uzaklik > halat_boyu and uzaklik > 0.001:
		global_position = capa + fark / uzaklik * halat_boyu

func _yon_girdisi() -> float:
	return Input.get_axis("move_left", "move_right") if girdi_aktif else 0.0

# --- Gorsel ------------------------------------------------------------

func _aday_guncelle() -> void:
	var yeni := en_iyi_nokta(_nisan)
	if yeni == _aday:
		return
	if is_instance_valid(_aday) and _aday.has_method("vurgu"):
		_aday.vurgu(false)
	_aday = yeni
	if is_instance_valid(_aday) and _aday.has_method("vurgu"):
		_aday.vurgu(true)

func _gorsel_guncelle() -> void:
	if absf(velocity.x) > 5.0:
		_bakis = signf(velocity.x)
	_gorsel.flip_h = _bakis < 0.0
	var hedef: StringName
	if kancali():
		hedef = &"zipla"
	elif is_on_floor():
		hedef = &"idle" if absf(velocity.x) < 5.0 else &"yuru"
	else:
		hedef = &"zipla" if velocity.y < 0.0 else &"dus"
	if _gorsel.animation != hedef:
		_gorsel.play(hedef)

func _halat_ciz() -> void:
	if not kancali():
		_halat.visible = false
		return
	_halat.visible = true
	_halat.points = PackedVector2Array([global_position, kanca_nokta.global_position])
