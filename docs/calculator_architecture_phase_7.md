# Calculator Architecture Phase 7

## Faz 6'dan Devralınan Mimari
Faz 6 sonunda hesap motoru `CalculatorValue` hiyerarsisi uzerinden scalar, symbolic, complex, vector ve matrix tiplerini ayri ayri tasiyordu. `ExpressionEvaluator` value-based dispatch ile exact/approximate ve real/complex domain kararlarini veriyor, `ResultFormatter` ayni value tiplerini UI dostu stringlere ceviriyordu. `CalculatorController`, `CalculatorState`, settings/history/storage ve presentation katmanlari ise motoru Flutter UI'dan ayri tutuyordu.

## Neden UnitValue Ayrı Bir CalculatorValue Tipi Olmalı?
Fiziksel birimler yalnizca scalar buyukluklerin yanina eklenen string etiketleri degildir. Bir birim sonucu:
- boyut vektoru tasir,
- display birimi ile base SI birimi arasinda cevrim yapar,
- toplama/cikarma icin dimension eslesmesi ister,
- temperature gibi affine birimlerde normal carpma/toplama kurallarindan ayrilir.

Bu nedenle birim sistemi sadece formatter katmaninda degil, evaluator ve arithmetic dispatch katmaninda da tipli olarak temsil edilmelidir.

## DimensionVector Tasarımı
`DimensionVector` immutable SI base dimension modelidir:
- length
- mass
- time
- electricCurrent
- thermodynamicTemperature
- amountOfSubstance
- luminousIntensity

Davranislar:
- add / subtract
- multiplyByExponent / divideByExponent
- equality / hashCode
- dimensionless detection
- display/debug string

Bu model `m/s^2`, `N`, `J`, `Pa` gibi derived boyutlarin tam olarak tasinmasini saglar.

## UnitDefinition / UnitRegistry Tasarımı
`UnitDefinition` her unit icin su bilgileri tutar:
- canonical key
- display symbol
- aliases
- dimension
- factorToBase
- offsetToBase
- flavor: regular / affineAbsolute / affineDelta

`UnitRegistry` minimum ama genisleyebilir bir yerel registry sunar:
- base SI units
- common scaled metric units
- basic imperial length/mass units
- time units
- limited volume units
- core derived SI units
- affine temperature units

Registry iki ana isi yapar:
- identifier -> unit definition lookup
- compound `UnitExpression` -> uygun derived display name canonicalization

## UnitExpression Tasarımı
`UnitExpression` display odakli unit ifadesidir. Sadece dimension tutmaz; kullanicinin gorecegi `km/h`, `m/s^2`, `N*m`, `J/s` gibi ifadeleri de temsil eder.

Desteklenen davranislar:
- multiply
- divide
- integerPower
- squareRoot (yalnizca integral exponents kalabiliyorsa)
- factorToBase
- dimension
- display string

Derived unit canonicalization, arithmetic sonucu olusan compound ifadeleri daha dogal gostermek icin registry seviyesinde yapilir:
- `N*m -> J`
- `J/s -> W`
- `N/m^2 -> Pa`

`to(...)` gibi explicit conversion hedeflerinde ise hedef display birimi korunur.

## Unit Parsing Yaklaşımı
Faz 7'de unit parsing `UnitMode` ile kontrollu hale getirildi:
- `UnitMode.disabled`
- `UnitMode.enabled`

Default davranis `disabled` secildi. Sebep:
- onceki fazlarda bilinmeyen identifier davranisini bozmamak
- mevcut test ve kullanici beklentilerini korumak
- unit parsing'i bilincli bir ozellik togglei ile acmak

Parser destegi:
- `3 m`
- `3m`
- `3*m`
- `m/s`
- `m/s^2`
- `kg*m/s^2`
- `to(100 cm, m)`

Ek olarak vector/matrix literal ve function parser'lari korunur. Unit attachment, scalar primary sonrasinda implicit veya explicit `*` ile gelen gercek unit chain'lerini quantity olarak baglar.

Bu fazda infix `100 cm to m` eklenmedi; `to(value, unit)` ve `convert(value, unit)` fonksiyonlari resmi API olarak kullaniliyor.

## Unit-Aware Arithmetic Dispatch
`UnitMath` dar bir helper katmani olarak eklendi. Burada:
- same-dimension add/subtract
- scalar * unit / unit * scalar
- unit * unit
- unit / unit
- integer power
- sqrt with integral dimension halves
- abs / round / compare
- explicit conversion

kurallari tipli sekilde uygulanir.

Display politikasi:
- add/subtract: sol operandin display unit'i korunur
- multiply/divide: yeni dimension olusuyorsa compound/derived display secilir
- dimensionless cancellation: scalar'a duser

## Conversion Engine Yaklaşımı
`UnitConverter` magnitude'i display unit ile base SI arasi cevirir:
- regular unitler
- affine absolute temperatures
- affine delta temperatures

`to(value, targetUnit)` icin:
- source fiziksel quantity olmali
- target unit expression olmali
- dimensions uyusmali
- absolute/delta temperature kurallari gecilmeli

## Temperature Affine Unit Yaklaşımı
Absolute temperatures:
- `degC`
- `degF`

Delta temperatures:
- `deltaC`
- `deltaF`

Kelvin bu fazda regular temperature base unit olarak tutuldu; affine arithmetic kurallari esasen absolute Celsius/Fahrenheit akislari uzerinden korunuyor.

Kurallar:
- absolute + delta -> absolute
- absolute - absolute -> delta
- delta + delta -> delta
- absolute + absolute -> error
- absolute * scalar -> error
- absolute temperature in multiply/divide -> error

Bu sayede `25 degC + 10 degC` gibi fiziksel olarak anlamsiz islemler sessizce hesaplanmiyor.

## Exact / Symbolic / Complex / Vector / Matrix ile Etkileşim
`UnitValue` scalar magnitude olarak mevcut value sistemini reuse eder:
- `RationalValue`
- `SymbolicValue`
- `ComplexValue`
- `DoubleValue`

Bu sayede:
- `sqrt(2) m`
- exact fraction magnitudes
- limited complex/unit entry tasima
- vector/matrix icinde unit entries

mevcut altyapi uzerinden calisir.

Vector/matrix tarafinda Faz 7'nin hedefi tam unit-linear-algebra degildi. Var olan scalar helper dispatch'i sayesinde:
- heterogeneous vector entries korunur
- unit entry tasiyan vector/matrix elemanlari render edilebilir
- basic element-wise vector operations dogru sekilde calisir

Determinant/inverse icin tam matrix-unit cebiri bu fazda bilincli olarak sinirli tutuldu.

## Result Formatting Tasarımı
`ResultFormatter` artik `UnitValue` icin de structured cikti uretir:
- `displayResult`
- `unitDisplayResult`
- `baseUnitDisplayResult`
- `dimensionDisplayResult`
- `conversionDisplayResult`

Format etkilesimi:
- auto + exact unit -> exact magnitude + unit
- decimal + exact unit -> decimal magnitude + unit
- fraction + exact unit -> fraction magnitude + unit
- symbolic + symbolic magnitude -> symbolic magnitude + unit

Vector/matrix icindeki unit entries scalar formatter uzerinden formatlanir.

## Settings / History / UI Değişiklikleri
### Settings
`CalculatorSettings.unitMode` eklendi.

### State / Controller
`CalculatorState.unitMode` ve `CalculatorController.setUnitMode(...)` eklendi.
Mode degisince aktif ifade yeniden evaluate edilir.

### History
`CalculatorHistoryItem` artik unit odakli alanlar tasir:
- unitDisplayResult
- baseUnitDisplayResult
- dimensionDisplayResult
- conversionDisplayResult
- unitMode

Duplicate policy su alanlari da dikkate alir:
- valueKind
- unitMode
- numericMode
- resultFormat
- calculationDomain

### UI
UI tarafinda:
- `UNITS OFF / UNITS ON` toggle
- settings sheet aciklamasi
- unit keypad kisayollari
- UNIT badge
- base SI ve dimension alternatives
- history badge ve unit summary

Bu fazda ayri bir unit converter panel eklenmedi; `to(` kisayolu ve keypad unit butonlari ilk surum olarak yeterli tutuldu.

## Guard Limitleri
Bu faz yeni global cache veya broad runtime degisikligi getirmez. Mevcut guard'lar korunur:
- exact rational digit guard
- symbolic term/factor guard
- matrix/vector size guard

Unit tarafinda ek korumalar:
- parser sadece tanimli unit chain'lerini quantity attachment olarak alir
- fractional physical dimensions genel olarak desteklenmez
- unsupported affine operations typed error uretir

Bu fazda ayrica ekstra persistent cache, schema degisikligi veya network bagimliligi eklenmedi.

## Sonraki Faz İçin Statistics / Probability Planı
Bir sonraki mantikli adim statistics/probability katmanidir:
- dataset parser
- `mean`, `median`, `variance`, `stddev`
- combinatorics (`nCr`, `nPr`)
- regression helpers
- basic distributions
- UI dataset editor / bottom sheet
- history serialization for datasets/statistical summaries

Mevcut typed value mimarisi bu genislemeyi destekler; gerekirse sonraki fazda `DatasetValue` benzeri yeni bir value tipi eklenebilir.
