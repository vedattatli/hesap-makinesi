# Calculator Architecture - Phase 3

## Faz 1 ve Faz 2'den Devralinan Mimari

Faz 1 ile birlikte proje saf Dart bir matematik cekirdegi kazandi:

- lexer
- parser
- AST
- evaluator
- `CalculatorEngine`
- typed outcome modeli

Faz 2'de bunun uzerine application ve presentation iskeleti kuruldu:

- `CalculatorController`
- `CalculatorState`
- history modeli
- settings modeli
- local storage
- responsive Flutter UI

Bu nedenle Faz 3'te ana hedef UI'yi veya controller omurgasini yeniden yazmak
degil, evaluatorun sadece `double` ile calisan yapisini daha profesyonel bir
typed numeric modele tasimakti.

## Neden Double Tek Basina Yeterli Degil?

`double` hizli ve pratik bir baslangictir ancak su sorunlari tasir:

- `1/3 + 1/6` gibi exact rasyonel islemleri tam koruyamaz
- `0.1 + 0.2` gibi finite decimal literal'larda binary floating-point hata
  birikimi olusur
- exact ve approximate sonuc ayrimi yapamaz
- kullaniciya alternatif fraction / decimal gosterimleri acikca sunamaz

Profesyonel hesap makinesinde kullanicinin gordugu sonuc ile motorun iceride
temsil ettigi sayi ayrilmalidir.

## Yeni Typed Value ve Exact Mode Mimarisi

Faz 3'te cekirdege yeni numeric policy ve typed value yapisi eklendi:

- `NumericMode.approximate`
- `NumericMode.exact`
- `CalculatorValue`
- `DoubleValue`
- `RationalValue`

Approximate mode mevcut davranisa yakin kalir; evaluator sayilari `double`
tabanli isler.

Exact mode acikken evaluator once sayi literal'larini `RationalValue`'ya
cevirir ve exact kalabilen islemleri `BigInt` tabanli rasyonel aritmetik ile
surdurur.

## Approx Mode ve Exact Mode Farki

Approx mode:

- hizli `double` tabanli davranis
- mevcut Faz 1/Faz 2 deneyimi korunur
- ana sonuc genellikle decimal gosterilir

Exact mode:

- sayi literal'lari exact rational olarak tutulur
- fraction sonucu korunabilir
- decimal alternative ayrica uretilir
- exact kalamayan fonksiyonlar kontrollu approximate fallback yapar

Ornek:

- Approx: `1/3 + 1/6 -> 0.5`
- Exact: `1/3 + 1/6 -> 1/2`, decimal alternative `0.5`

## Exact Kalan Islemler

Faz 3'te su davranislar exact kalir:

- integer / finite decimal / scientific notation literal'lari
- unary plus / minus
- `+`, `-`, `*`, `/`
- `^` integer exponent ile
- `pow(a, b)` b integer ise
- `abs`
- `min`, `max`
- `floor`, `ceil`, `round`
- `sqrt` sadece perfect-square rational ise

Ornekler:

- `0.1 + 0.2 -> 3/10`
- `2^-3 -> 1/8`
- `sqrt(1/4) -> 1/2`

## Approximate Fallback Yapan Islemler

Su alanlar exact mode icinde approximate fallback yapar:

- `sin`, `cos`, `tan`
- `asin`, `acos`, `atan`
- `ln`, `log`, `log10`, `log2`
- `exp`
- `pi`, `e`
- `sqrt` perfect-square degilse
- `^` ve `pow` non-integer exponent ile

Fallback oldugunda evaluator warning uretir. Bu warning'ler result card ve
history'de korunur.

## Result Formatting Tasarimi

`ResultFormatter` artik sadece `double` formatlamaz; `CalculatorValue`
tiplerine gore calisir.

Desteklenen formatlar:

- `auto`
- `decimal`
- `fraction`
- mevcut uyumluluk icin `scientific`

Kurallar:

- exact rational + auto -> fraction
- exact rational + decimal -> decimal display, fraction alternative saklanir
- exact rational + fraction -> fraction display
- approximate -> decimal/scientific davranisi korunur

`CalculationResult` da su alanlarla genisletildi:

- `numericMode`
- `valueKind`
- `exactDisplayResult`
- `decimalDisplayResult`
- `fractionDisplayResult`
- `alternativeResults`

## Settings, History ve UI Guncellemeleri

`CalculatorSettings` artik su alanlari da saklar:

- `numericMode`
- `resultFormat`

`CalculatorHistoryItem` ise su bilgileri de tasir:

- `numericMode`
- `resultFormat`
- `valueKind`
- `exactDisplayResult`
- `decimalDisplayResult`
- `fractionDisplayResult`

Eski JSON kayitlariyla uyumluluk korundu. Eksik alanlar defaultlarla
tamamlaniyor.

UI tarafinda:

- ust satira APPROX / EXACT toggle eklendi
- result card'a EXACT / APPROX badge eklendi
- rational sonuc varsa fraction / decimal alternatifleri gosteriliyor
- history paneli numeric mode badge gosteriyor
- settings sheet numeric mode ve result format ayari aliyor

## Hesaplama Limitleri

Exact rational hesaplar icin iki koruma eklendi:

- numerator veya denominator 10.000 digit'i asarsa `computationLimit`
- integer exponent exact mode'da 2048 buyuklugunu asarsa `computationLimit`

Bu koruma `999999999^999999999` benzeri ifadelerde uygulamanin donmasini
engellemek icin secildi.

## Sonraki Faz Icin Symbolic-lite Plani

Faz 4'te exact rational yapinin uzerine symbolic-lite katman eklemek icin su
yol onerilir:

1. `CalculatorValue` hiyerarsisine `SymbolicValue` eklemek
2. `sqrt(2)` gibi sadelesmeyen kokleri approximate fallback yerine symbolic
   alternative olarak saklamak
3. `pi` ve `e` icin exact symbolic kimlik + approximate numeric alternative
4. basit kok sadelestirme ve perfect-square faktor ayirma
5. ozel trigonometrik degerler:
   - `sin(pi/2) = 1`
   - `cos(pi) = -1`
   - `sin(30 deg) = 1/2`
6. result card'da exact symbolic + decimal alternative birlikte gosterimi

Bu sayede Faz 3'te kurulan rational temel bozulmadan `sqrt(2)`, `pi` ve basit
symbolic alternatifler profesyonel sekilde sisteme eklenebilir.
