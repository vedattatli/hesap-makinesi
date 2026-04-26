# Calculator Architecture - Phase 5

## Faz 4'ten Devralinan Symbolic-lite Mimari

Faz 4 sonunda calculator core su temel katmanlari saglam sekilde ayirmisti:

- `DoubleValue` ile approximate scalar hesap
- `RationalValue` ile exact rational hesap
- `SymbolicValue` ile symbolic-lite exact hesap
- `NumericMode.approximate` ve `NumericMode.exact`
- `ResultFormatter` ile value-tabanli sonuc bicimleme
- controller, settings, history ve UI tarafinda mode / format farkindaligi

Bu temel, Faz 5'te complex support eklemek icin yeterliydi. Yeni is hedefi,
mevcut real davranisi bozmadan complex sonuclari ayrik bir domain olarak
calistirmakti.

## Complex Mode Neden Ayri Domain Olarak Gerekiyor?

Complex sayilar numeric mode'dan farkli bir problem cozer:

- numeric mode, exact mi approximate mi hesaplayacagimizi belirler
- calculation domain ise hangi sayi kumesinde oldugumuzu belirler

Ornek:

- `sqrt(-1)` real domain'de domain error olmali
- ayni ifade complex domain'de `i` olmali
- `ln(-1)` real domain'de error, complex domain'de `pi i`

Bu nedenle complex support, mevcut `NumericMode` ustune ek bir policy olarak
`CalculationDomain.real` ve `CalculationDomain.complex` seklinde tasarlandi.

## Real Mode ile Complex Mode Farki

Real mode:

- Faz 1-4 davranisini korur
- `i` taninmaz
- negatif radicand gercek sayilarda hata verir
- negatif logaritma hata verir

Complex mode:

- `i` sabiti taninir
- scalar ifadeler gerekirse otomatik complex'e promote edilir
- negatif kokler, negatif log ve bazi kesirli usler complex sonuca yonlenir
- sonucu rectangular formda gosterir, polar alternative de sunabilir

Default domain bilincli olarak `real` kalir.

## Yeni ComplexValue Mimarisi

Faz 5'te yeni value tipi:

- `ComplexValue`

Temel model:

- `realPart: CalculatorValue`
- `imaginaryPart: CalculatorValue`

Bu sayede complex sayinin bileşenleri su mevcut altyapidan faydalanabilir:

- `RationalValue`
- `SymbolicValue`
- `DoubleValue`

Yani su gibi exact sonuclar dogrudan temsil edilebilir:

- `11/25 + 2i/25`
- `sqrt(2)i`
- `pi i`

`ComplexValue` destekleri:

- scalar promotion
- add / subtract / multiply / divide
- integer power
- reciprocal
- conjugate
- magnitude
- argument
- simplify

`simplify()` kurali:

- imaginer kisim `0` ise sonuc scalar'a duser
- `0 + i` -> `i`
- `0 - i` -> `-i`
- `0 + 2i` -> `2i`

## Rectangular ve Polar Gosterim Tasarimi

Ana display complex sonuclarda rectangular formdur:

- `i`
- `-i`
- `2i`
- `3 + 4i`
- `11/25 + 2i/25`
- `sqrt(2)i`
- `pi i`

Canonical secimler:

- imaginary suffix sonda: `sqrt(2)i`, `pi i` degil `pii` yazilmaz
- rational imaginary parca okunabilir sekilde: `2i/25`

Alternative results:

- `rectangularDisplayResult`
- `complexDisplayResult`
- `polarDisplayResult`
- `magnitudeDisplayResult`
- `argumentDisplayResult`
- varsa `decimalDisplayResult`
- varsa `symbolicDisplayResult`

Polar alternative bu fazda genellikle approximate uretir:

- `r∠theta rad`
- `r∠theta°`
- `r∠theta grad`

## Exact / Symbolic Complex ile Approximate Complex Farki

Exact / symbolic complex:

- her iki part da exact ise `isApproximate = false`
- ornekler:
  - `i`
  - `2i`
  - `sqrt(-2) -> sqrt(2)i`
  - `ln(-1) -> pi i`
  - `(1+2i)/(3+4i) -> 11/25 + 2i/25`

Approximate complex:

- en az bir part approximate ise `isApproximate = true`
- genel transcendental complex hesaplar burada yer alir
- ornek:
  - `sin(i)`
  - `exp(1 + i)` genel durumda approximate complex olabilir

## Hangi Islemler Exact Kaliyor?

Complex domain + exact mode'da exact kalan temel yollar:

- `i`
- scalar + complex promotion
- complex toplama / cikarma
- complex carpma / bolme
- integer power
- `sqrt(-n)` ve `sqrt(-rational)` gibi saf negatif reellerin kokleri
- `(-1)^0.5`, `pow(-1, 0.5)` gibi half-power ozel halleri
- `re`, `im`, `conj`, `abs`
- `arg` icin temel exact acilar
- `polar` ve `cis` icin Faz 4 trig table kapsamina giren acilar
- `ln(-1) -> pi i`
- `ln(i) -> pi i / 2`
- `exp(i*pi) -> -1`
- `exp(i*pi/2) -> i`

## Hangi Islemler Approximate Fallback Yapiyor?

Asagidaki alanlar halen warning ile approximate complex fallback yapabilir:

- exact table disi complex trig
- genel complex `ln(a+bi)` ve `exp(a+bi)` durumlari
- general complex non-integer power
- desteklenmeyen symbolic complex kombinasyonlar

Ornekler:

- `sin(i)`
- `cos(1+i)`
- `exp(2 + i*pi/7)`

Kural:

- sessizce yanlis exact sonuc uretilmez
- approximate fallback yapiliyorsa warning listesi doldurulur

## Result Formatting Tasarimi

`CalculationResult` Faz 5'te complex alanlarla genislestirildi:

- `complexDisplayResult`
- `rectangularDisplayResult`
- `polarDisplayResult`
- `magnitudeDisplayResult`
- `argumentDisplayResult`
- `calculationDomain`

Display politikasi:

- `displayResult` ana sonuc olmaya devam eder
- complex sonuclarda default rectangular form kullanilir
- `numericValue` politikasi olarak complex sonuclarda magnitude kullanilir
  - bu sayede history / siralama / bazi basit numeric yuzeyler bozulmaz
  - ama UI ana sonuc olarak bunu degil rectangular sonucu gosterir

## Settings / History / UI Degisiklikleri

Settings:

- `calculationDomain` eklendi
- eski JSON icinde alan yoksa default `real`
- backward compatibility korunuyor

History:

- `calculationDomain`
- `complexDisplayResult`
- `rectangularDisplayResult`
- `polarDisplayResult`
- `magnitudeDisplayResult`
- `argumentDisplayResult`

Duplicate policy artik su farklari da dikkate alir:

- numeric mode
- result format
- calculation domain
- value kind

UI:

- ust toolbar'da `REAL / COMPLEX` toggle
- settings sheet'te domain secimi
- keypad'te `i`, `re(`, `im(`, `conj(`, `arg(`, `cis(`, `polar(`
- result card'ta `COMPLEX` badge
- rectangular ana sonuc + polar/magnitude/argument alternatives
- history panelinde complex badge

## Hesaplama Guard ve Limitleri

Faz 3 ve Faz 4 korumalari korunur:

- exact rational digit limiti: 10.000
- exact exponent limiti: 2048
- symbolic term limiti: 100
- term basina factor limiti: 24

Complex support bu guard'lari yeniden kullanir. Ayrica:

- complex bolmede denominator sifirsa typed `divisionByZero`
- desteklenmeyen complex symbolic patlamalarda approximate fallback veya
  `computationLimit`

## Sonraki Faz Icin Matrix / Vector Plani

Faz 6 icin en mantikli genisleme matrix/vector modulu olur:

1. `VectorValue`
2. `MatrixValue`
3. scalar + vector + matrix arithmetic
4. determinant
5. transpose
6. inverse
7. matris editoru ve UI veri girisi
8. future-proof olarak complex matrix desteğine acik veri modeli

Bu Faz 5 tasarimi buna uygundur cunku:

- `CalculatorValue` hiyerarsisi genisleyebilir
- `ResultFormatter` yeni value tipleri eklenerek buyutulebilir
- `CalculationDomain` real/complex ayrimini coktan cozer
- controller/history/settings yeni mode alanlari tasiyabilecek sekilde ayrik
  yapidadir
