# Calculator Architecture - Phase 4

## Faz 3'ten Devralinan Numeric Value Mimarisi

Faz 3 sonunda cekirdek su ayrimi kurmustu:

- `DoubleValue` ile approximate hesap
- `RationalValue` ile exact rational hesap
- `NumericMode.approximate` ve `NumericMode.exact`
- value-tabanli `ResultFormatter`
- controller, settings, history ve UI katmanlarinda numeric mode farkindaligi

Bu temel, Faz 4'te symbolic-lite katmani eklemek icin yeterliydi. Bu nedenle
approximate davranis korunurken exact mode daha profesyonel exact sonuc
uretebilir hale getirildi.

## Symbolic-lite Neden Gerekli?

Sadece rational exact desteklemek su problemlere yol aciyordu:

- `sqrt(2)` gibi ifadeler exact mode'da gereksiz yere approximate sonuca dusuyordu
- `pi` ve `e` exact mode'da warning ile decimal'a iniyordu
- `sin(pi/6)` gibi klasik ozel degerler exact mode'da exact donmuyordu
- kullanici exact mod acsa bile bircok universiteseviye ifade sembolik
  kimligini kaybediyordu

Profesyonel bilimsel hesap makinesinde exact mode kullaniciya sadece fraction
degil, anlamli sembolik kimlik de vermelidir.

## Tam CAS ile Symbolic-lite Farki

Bu faz tam CAS degildir. Yapilmayanlar:

- degiskenli cebir
- polinom acilimlari
- denklem cozme
- turev / integral
- genel trig acilimlari
- genel symbolic rewrite sistemi

Yapilan sey ise daha dar ve kontrolludur:

- radical simplification
- `pi` ve `e` gibi temel sabitleri exact symbolic tutma
- ayni factor yapisina sahip terimleri toplama
- secili trig / inverse trig exact table
- desteklenmeyen symbolic durumlarda kontrollu approximate fallback

## Yeni Symbolic Value Modeli

Faz 4'te yeni katmanlar eklendi:

- `SymbolicFactor`
- `ConstantFactor`
- `RadicalFactor`
- `SymbolicTerm`
- `SymbolicValue`
- `SymbolicSimplifier`

Temel fikir:

- Bir `SymbolicTerm`, `RationalValue coefficient + normalized factors` yapisina
  sahiptir.
- Factor turleri bu fazda:
  - `pi`
  - `e`
  - `sqrt(integer)`
- `SymbolicValue`, bu terimlerin normalize edilmis toplamidir.

Ornekler:

- `sqrt(2)` -> coefficient `1`, factor `sqrt(2)`
- `2sqrt(2)` -> coefficient `2`, factor `sqrt(2)`
- `pi/2` -> coefficient `1/2`, factor `pi`
- `3sqrt(2) + 1` -> iki terimli symbolic sum

Normalization kurallari:

- sifir katsayili terimler silinir
- ayni factor yapisina sahip terimler toplanir
- rational-only sonuc tekrar `RationalValue`'a duser
- factor sirasi stabil tutulur

## Radical Simplification Yaklasimi

`sqrt` exact mode'da once rational kok denemesi yapar:

- perfect square ise `RationalValue`
- degilse symbolic radical

Sadelestirme su sekilde yapilir:

1. numerator ve denominator ayri ayri square factor extraction gecirir
2. disari alinabilen square factor coefficient'e carpilir
3. kalan parca square-free radical olarak tutulur
4. denominator'da square-free parca varsa okunabilir form icin radical
   rationalize edilir

Ornekler:

- `sqrt(8)` -> `2sqrt(2)`
- `sqrt(12)` -> `2sqrt(3)`
- `sqrt(8/9)` -> `2sqrt(2)/3`
- `sqrt(12/25)` -> `2sqrt(3)/5`

Bu faz symbolic-lite oldugu icin buyuk radicand factorization'inda koruyucu bir
limit vardir. Cok buyuk sayilarda pahali tam factorization yerine exact ama
daha az sade bir symbolic radical tutulabilir.

## Symbolic Constant Yaklasimi

Exact mode'da:

- `pi` ve `π` -> exact symbolic `π`
- `e` -> exact symbolic `e`

Bu sayede:

- `2*pi` -> `2π`
- `pi/2` -> `π/2`
- `pi + pi` -> `2π`
- `e + e` -> `2e`

Bu sabitlerin decimal alternative degeri yine hesaplanir:

- `π` -> `math.pi`
- `e` -> `math.e`

## Exact Trig Table Yaklasimi

Faz 4 exact trig sistemi angle mode'a gore argumani turn fraction olarak
normalizer:

- DEG -> angle / 360
- RAD -> eger ifade pure `coefficient * π` ise coefficient / 2
- GRAD -> angle / 400

Sonra desteklenen birinci bolge referans acilarindan exact table okunur ve
quadrant sign kurallari uygulanir.

Desteklenen temel exact degerler:

- `0`
- `π/6`, `π/4`, `π/3`, `π/2`
- bunlarin DEG karsiliklari: `30`, `45`, `60`, `90`
- bunlarin GRAD karsiliklari: `50`, `100`

Exact donen ornekler:

- `sin(pi/6) -> 1/2`
- `cos(pi/3) -> 1/2`
- `tan(pi/4) -> 1`
- `sin(45 deg) -> sqrt(2)/2`
- `cos(30 deg) -> sqrt(3)/2`
- `asin(1) -> π/2`, `90`, `100`

## Hangi Islemler Exact Symbolic Kaliyor?

Exact mode'da bu fazda exact kalanlar:

- Faz 3'teki tum rational exact islemler
- `sqrt` ile uretilen square-root symbolic sonuclar
- `pi`, `π`, `e`
- ayni factor yapisina sahip toplama / cikarma
- rational ile symbolic carpma / bolme
- tek terimli symbolic carpma
- secili exact trig / inverse trig sonuclari
- integer power
- `2^0.5` ve `pow(2, 0.5)` gibi half-power durumlari

## Hangi Islemler Approximate Fallback Yapiyor?

Asagidaki alanlar hala approximate fallback kullanir:

- `ln`, `log`, `log10`, `log2`, `exp`
- exact table disi trig / inverse trig girisleri
- tam desteklenmeyen genel symbolic division
- tam desteklenmeyen symbolic transcendental kombinasyonlar
- tam CAS gerektiren islemler

Ornekler:

- `ln(pi)` -> warning + approximate
- `sin(sqrt(2))` -> warning + approximate
- symbolic sabitlerin paydada kaldigi daha genel durumlar -> warning + approximate

## Result Formatting Tasarimi

`ResultFormatter` artik `SymbolicValue` tanir. Formatlar:

- `auto`
- `decimal`
- `fraction`
- `symbolic`
- mevcut uyumluluk icin `scientific`

Davranis:

- auto + rational -> fraction
- auto + symbolic -> symbolic
- decimal + symbolic -> decimal ana display, symbolic alternative saklanir
- symbolic + symbolic -> symbolic ana display
- fraction + symbolic -> symbolic ana display
- approximate double -> Faz 1-3 davranisi

Yeni result alanlari:

- `symbolicDisplayResult`
- `decimalDisplayResult`
- `exactDisplayResult`
- `alternativeResults`
- `valueKind = symbolic`

## Settings, History ve UI Degisiklikleri

Settings:

- `resultFormat` artik `symbolic` de alabilir
- eski JSON payload'lari defaultlarla tamamlanir

History:

- `valueKind = symbolic`
- `symbolicDisplayResult`
- `decimalDisplayResult`
- mevcut backward compatibility korunur

UI:

- result card `SYMBOLIC` badge gosterebilir
- decimal alternative symbolic sonuc icin gorunur
- settings sheet'e `Symbolic` result format secenegi eklendi
- history paneli symbolic badge gosterir

## Hesaplama Limitleri

Faz 3 limitleri korunur:

- exact rational digit limiti: 10.000
- exact integer exponent limiti: 2048

Faz 4 symbolic-lite limitleri:

- max symbolic term count: 100
- max factor count per term: 24

Bu limitler tam CAS patlamalarini engelleyip symbolic-lite'i kontrollu tutmak
icin secildi.

## Sonraki Faz Icin Complex Number Plani

Faz 5 icin dogal genisleme complex number katmani olur:

1. `CalculatorValue` hiyerarsisine `ComplexValue`
2. `sqrt(-1) = i`
3. `a + bi` rectangular form
4. polar / exponential form
5. real mode ve complex mode ayrimi
6. `ln(-1)`, `sqrt(-1)`, negative fractional powers icin controlled complex
   fallback
7. UI'da real / complex mode switch

Bu gecis symbolic-lite ile uyumludur cunku Faz 4 zaten exact symbolic ve
approximate fallback ayrimini acik sekilde kurmustur.
