# Kanca — itch.io page copy

> Bu dosya itch.io sayfasına yapıştırılmak için hazırlandı. **Yükleme yapılmadı**,
> sayfa oluşturulmadı. Karar Furki'de.

---

## English

### Kanca

**Throw your hook, swing like a pendulum, let go at the right moment and fly.
Finish each level as fast as you can.**

A speed-focused 2D swinging platformer set on storm-swept floating islands.
No double jump, no dash — everything you have is one rope and your own momentum.
Release timing is the entire game: let go too early and you stall, too late and
you swing back. Fourteen levels, each with gold / silver / bronze target times
and a ghost of your own best run to chase.

**Features**

- **One mechanic, deep:** a rope-constrained pendulum. Shorten the rope to spin
  faster, lengthen it to reach farther. Momentum is never taken from you.
- **14 hand-tuned levels**, each introducing one idea: moving anchors, single-use
  brittle anchors that snap when you let go, updraft currents, ceiling spikes.
- **Medals and ghosts:** gold/silver/bronze times per level, and your best run
  replays beside you as a translucent ghost. Once you earn gold on a level you
  can switch the ghost to the **golden ghost** — the reference run itself — and
  watch the line you are missing.
- **Daily challenge:** one level picked by the date plus a small modifier
  (short rope, or a constant side wind). Same for everyone, changes every day,
  scored in its own slot so it never touches your main progress.
- **Checkpoints** in the long levels — the clock keeps running, so dying still costs you.
- **Flow chain:** every anchor you catch without touching the ground extends your
  chain. It is scored separately from time — the fastest run is not always the
  most stylish one.
- **Route hint:** once you earn gold on a level, the anchors the reference route
  uses are marked, so "how is that even possible" has an answer.
- **Target times are measured, not guessed.** A bot plays **all fourteen levels**
  in the real physics with randomised reaction delays — it pumps the rope,
  re-routes when a line fails and grabs a rescue anchor mid-fall; the medals
  come from those runs, down to the millisecond.
- Hand-made pixel art on a single limited palette, procedurally generated chiptune.
- Keyboard + mouse, gamepad, and a **one-finger touch scheme** for phones.
  Rebindable keys and adjustable aim assist. Turkish interface.

**Controls**

| Action | Keyboard / Mouse | Gamepad |
|---|---|---|
| Run / pump the swing | `A` `D` or arrows | Left stick, D-pad |
| Jump (while hooked: release + launch) | `Space` | `A` |
| Aim | Mouse | Right stick |
| Fire hook (hold) / release | `Left click` | `RB` |
| Shorten / lengthen rope | `W` `S` or up/down | D-pad up/down |
| Restart level | `R` | `X` |
| Pause | `Esc` | `Start` |

If you are not aiming, the hook automatically picks the best anchor in the
direction you are facing — scored by how well it lines up with your aim, how far
it is, and where you are already moving; anchors behind a wall are never picked.
The selected anchor glows white with a dashed line to it, the one you are
attached to glows gold, and out-of-range anchors go grey.

**One finger (touch):** running is automatic, tap to hook (or jump if there is no
anchor), lift to release, and slide up/down while holding to shorten or lengthen
the rope. After a death a single-tap **restart** button appears. You can try the
whole scheme on desktop from Settings.

**Notes**

- Runs in the browser (single-threaded build — no SharedArrayBuffer needed) and
  as a Windows download.
- Interface language is Turkish.

---

## Türkçe

### Kanca

**Kancanı at, sarkaç gibi salın, tam zamanında bırak ve momentumla uç.
Her bölümü olabildiğince hızlı bitir.**

Fırtınalı gökyüzü adalarında geçen, hız odaklı 2B sallanma platform oyunu.
Çift zıplama yok, atılma yok — elindeki tek şey bir halat ve kendi momentumun.
Bırakma zamanlaması oyunun tamamı: erken bırakırsan havada kalırsın, geç
bırakırsan geri savrulursun. On dört bölüm, her birinde altın / gümüş / bronz
hedef süre ve kovalayacağın kendi en iyi koşunun hayaleti.

**Özellikler**

- **Tek mekanik, derin:** halatla kısıtlanmış sarkaç. Halatı kısalt, daha hızlı
  dönersin; uzat, daha uzağa ulaşırsın. Momentum senden asla geri alınmaz.
- **Elle ayarlanmış 14 bölüm**, her biri tek bir fikri tanıtıyor: hareketli
  kanca noktaları, bıraktığın an kırılan tek kullanımlık noktalar, yukarı iten
  rüzgâr akıntıları, dikenli tavanlar.
- **Madalya ve hayalet:** bölüm başına altın/gümüş/bronz süre, ve en iyi koşun
  yanında yarı saydam hayalet olarak tekrar oynuyor. Bir bölümde altın
  madalyayı aldıysan hayaleti **altın hayalete** çevirebilirsin: referans
  koşunun kendisi yanında koşar.
- **Günlük meydan okuma:** tarihe göre seçilen bir bölüm ve küçük bir
  değiştirici (kısa halat ya da sürekli yan rüzgâr). Herkeste aynı, her gün
  değişir, kendi kayıt yuvasında — ana ilerlemeye dokunmaz.
- **Kontrol noktaları** uzun bölümlerde — ama sayaç durmuyor, ölmek yine de
  süre kaybı.
- **Akış zinciri:** yere değmeden yakaladığın her nokta zinciri uzatır. Süreden
  ayrı notlanır — en hızlı koşu her zaman en şık koşu değildir.
- **Rota ipucu:** bir bölümde altın madalyayı aldığında referans rotanın
  kullandığı noktalar işaretlenir; "bu nasıl mümkün" sorusunun cevabı görünür.
- **Hedef süreler tahmin değil, ölçüm.** Bir bot **14 bölümün tamamını** gerçek
  fizikte, rastgele tepki gecikmeleriyle oynuyor — halatı pompalıyor, tıkandığı
  rotayı değiştiriyor, düşerken ara noktaya tutunuyor; madalyalar o koşulardan,
  ms hassasiyetinde.
- Tek sınırlı palette elle üretilmiş pixel art, kodla üretilmiş chiptune müzik.
- Klavye + fare, gamepad ve telefon için **tek parmak şeması**. Tuş atama ve
  ayarlanabilir nişan yardımı. Türkçe arayüz.

**Kontroller**

| İş | Klavye / Fare | Gamepad |
|---|---|---|
| Koş / salınımı büyüt | `A` `D` veya `←` `→` | Sol çubuk, D-pad |
| Zıpla (kancalıyken: kopar + fırla) | `Boşluk` | `A` |
| Nişan al | Fare | Sağ çubuk |
| Kancayı at (basılı tut) / bırak | `Sol tık` | `RB` |
| Halatı kısalt / uzat | `W` `S` veya `↑` `↓` | D-pad yukarı/aşağı |
| Bölümü yeniden başla | `R` | `X` |
| Duraklat | `Esc` | `Start` |

Nişan almıyorsan kanca, baktığın yöndeki en uygun noktaya kendiliğinden gider:
nişan hizası, uzaklık ve mevcut hız yönüne göre puanlanır; duvarın arkasındaki
nokta hiç seçilmez. Seçili nokta beyaz yanar ve araya kesik çizgi çekilir, bağlı
olduğun nokta altın rengi olur, menzil dışındakiler grileşir.

**Tek parmak (dokunmatik):** koşu otomatik, dokun = kanca (hedef yoksa zıplama),
parmağı kaldır = bırak, basılıyken yukarı/aşağı kaydır = halat boyu. Öldükten
sonra tek dokunuşluk **"Baştan başla"** düğmesi beliriyor.
Masaüstünde Ayarlar'dan denenebilir.

**Notlar**

- Tarayıcıda çalışır (tek iş parçacıklı yapı — SharedArrayBuffer gerekmez) ve
  Windows indirmesi olarak da var.

---

## Sayfa ayarları (itch.io formu)

| Alan | Değer |
|---|---|
| Title | Kanca |
| Short description | Swing, release, fly. A speed-focused hook platformer on storm islands. |
| Classification | Game |
| Kind of project | HTML (playable in browser) + downloadable Windows build |
| Release status | Released |
| Pricing | Free (donations off) |
| Genre | Platformer |
| Tags | pixel-art, speedrun, grappling-hook, physics, precision-platformer, godot, 2d, singleplayer, daily-challenge |
| Input | Keyboard, Mouse, Gamepad, Touchscreen |
| Cover image | `yayin/kapak.png` (630×500) |
| GIF (sayfa metninin başına) | `yayin/tanitim.gif` — 3,6 sn, 640×360: kanca takma → salınım → fırlama bonusu |
| Screenshots | `yayin/ekran_1.png` … `ekran_4.png` (1280×720) |
| Embed | 1280×720, "Click to run" **kapalı**, fullscreen butonu **açık** |
| SharedArrayBuffer | **Gerekmiyor** (thread_support kapalı) — kutuyu işaretleme |
