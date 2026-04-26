# Calculator Architecture Phase 8

## Faz 7'den Devralinan Value Mimarisi
Faz 7 sonunda motor `CalculatorValue` hiyerarsisi uzerinden scalar, symbolic, complex, vector, matrix ve unit tiplerini ayri ayri tasiyordu. `ExpressionEvaluator` value-based dispatch ile exact/approximate, real/complex ve units on/off politikalarini birlestiriyor; `ResultFormatter` da ayni value tiplerini UI dostu alternatiflerle gosteriyordu. Bu sayede istatistik katmanini da ayni tipli cekirdek uzerine eklemek dogal bir sonraki adim oldu.

## Neden Dataset / Statistics Layer Ayrica Tasarlandi?
Istatistik fonksiyonlari yalnizca "bir vektor uzerinde map/reduce" degildir. Su davranislar ortak, tekrar kullanilabilir ve typed olmalidir:
- dataset olusturma ve dogrulama
- exact vs approximate toplama/ortalama politikasi
- quantile interpolation politikasi
- weighted statistics kurallari
- probability parameter validation
- regression sonucu gibi structured result tipleri

Bu nedenle Faz 8'de `DatasetValue` ve `RegressionValue` eklenerek istatistik katmani, var olan `VectorValue` uzerine tesadufi bir convention olmaktan cikartildi.

## DatasetValue Tasarimi
`DatasetValue` immutable `List<CalculatorValue>` tasir.

Ozellikler:
- bos dataset yasak
- `length`
- `isExact`: tum elemanlar exact ise true
- `isApproximate`: herhangi bir eleman approximate ise true
- `sortedValues(compare)` ile sirali kopya uretir ama orijinal sirayi bozmaz
- `toDouble()` dataset icin anlamsal bir "tek sayi" degildir; UI ve formatter dataset display uzerinden calisir

Dataset display politikasi:
- compact: `data(1, 2, 3, 4)`
- buyuk dataset preview: `data(1, 2, 3, ...; n=100)`

Preview limiti Faz 8'de `50` secildi.

## Existing VectorValue ile Iliski
Istatistik fonksiyonlari:
- `data(...)`
- `dataset(...)`
- `ds(...)`

ile acik dataset kurabilir.

Ayrica tek argumanli istatistik fonksiyonlarinda mevcut `VectorValue` veya `[1,2,3]` literal sonucu dataset gibi coercion alir. Bu sayede kullanici hem `mean(data(1,2,3))` hem `mean(vec(1,2,3))` yazabilir.

Matrix, nested dataset ve complex statistics ise bu fazda bilincli olarak desteklenmedi.

## Statistics Function Registry Yaklasimi
`ExpressionEvaluator` function switch'i su yeni gruplari aldi:
- dataset constructors
- descriptive statistics
- quantile helpers
- weighted mean
- combinatorics
- discrete distributions
- continuous distributions
- covariance / correlation / regression / prediction

Bu registry yaklasimi Faz 1-7'deki function-based evaluator mimarisini korur; broad parser refactor gerektirmez.

## Exact vs Approximate Statistics Davranisi
Exact mode'da mumkun olan yerlerde su tipler korunur:
- `count`, `sum`, `product`
- `mean`, `median`
- `varp`, `vars`
- exact rational `binomPmf` / `binomCdf`
- exact rational `geomPmf` / `geomCdf`
- `factorial`, `nCr`, `nPr`
- `corr`, `covp`, `covs`, slope/intercept

`stdp` / `stds` karekok gerektirdigi icin:
- perfect square ise rational
- degilse Faz 4 symbolic-lite altyapisiyla radical symbolic sonuc
- dogal olarak transcendental olan dagilim fonksiyonlari ise approximate

Approximate sonuclar:
- `poissonPmf`, `poissonCdf`
- `normalPdf`, `normalCdf`
- `uniformPdf`, `uniformCdf`
- `zscore`

Bu sonuclar `DoubleValue` ile doner ve `isApproximate` true olur.

## Variance / Stddev Policy
Default policy:
- `variance(data(...))` -> sample variance
- `stddev(data(...))` -> sample standard deviation

Acik population/sample fonksiyonlari:
- `varp`, `variancep`
- `vars`, `variances`
- `stdp`, `stdevp`
- `stds`, `stdevs`

Kural:
- sample variance/stddev icin `n >= 2`
- population variance/stddev icin `n >= 1`

## Quantile Interpolation Policy
Faz 8'de deterministic R-7 politikasi secildi:
- `h = 1 + (n - 1) * q`
- alt ve ust index arasinda linear interpolation

Bu politika Excel / NumPy / Python dunyasindaki tanidik davranisa yakindir.

Fonksiyonlar:
- `quantile(data, q)` where `q in [0,1]`
- `percentile(data, p)` where `p in [0,100]`
- `quartiles(data)` -> `[Q1, Q2, Q3]`
- `iqr(data)` -> `Q3 - Q1`

Exact mode'da q rational ise interpolasyon da mumkun oldugunca rational kalir.

## Weighted Statistics Policy
Faz 8 minimum zorunlu kapsam olarak `wmean` / `weightedMean` ekledi.

Kurallar:
- values ve weights ayni uzunlukta olmali
- weights real, numeric ve dimensionless olmali
- negative weight yasak
- weight toplami sifir olamaz
- values unit ise weights boyutsuz kaldigi surece weighted mean sonucu ayni unit ile doner

Weighted variance/stddev bu fazda bilincli olarak eklenmedi; mimari bunu sonraki fazlarda alabilecek sekilde duzenli tutuldu.

## Probability Distribution Approximation Policy
### Exact veya yarim-exact
- `binomPmf`, `binomCdf`: `p` rational ise exact mode'da rational sonuc
- `geomPmf`, `geomCdf`: `p` rational ise exact mode'da rational sonuc

### Approximate
- `poissonPmf`, `poissonCdf`
- `normalPdf`, `normalCdf`
- `uniformPdf`, `uniformCdf`
- `zscore`

`normalCdf` icin ucuncu parti paket kullanilmadi; yerel `erf` approx kullanildi.
`normalCdf(0,0,1)` gibi kritik noktalarda temiz display icin noise normalization mevcut formatter tarafinda korunur.

Geometric policy:
- `k` trial number olarak 1'den baslar
- `PMF = (1-p)^(k-1) * p`
- `CDF = 1 - (1-p)^k`

## Regression Result Modeli
`RegressionValue` structured result olarak eklendi.

Alanlar:
- `slope`
- `intercept`
- `r`
- `rSquared`
- `sampleSize`
- `xMean`
- `yMean`

Display:
- ana display: `y = 2x + 0`
- alternatives: slope, intercept, r, rSquared, n
- summary: compact regression ozeti

Prediction icin:
- `linreg(xData, yData)`
- `linpred(xData, yData, x)`

Bu fazda `predict(regressionValue, x)` gecisi evaluator tarafinda zorunlu kilinmadi; `linpred(...)` dogrudan API olarak yeterli tutuldu.

## Result Formatting Tasarimi
Formatter su yeni structured alanlari doldurur:
- `datasetDisplayResult`
- `statisticsDisplayResult`
- `regressionDisplayResult`
- `probabilityDisplayResult`
- `summaryDisplayResult`
- `sampleSize`
- `statisticName`

Display politikasi:
- dataset preview buyukse kisaltilir
- scalar stats mevcut rational/symbolic/unit formatter akisini reuse eder
- regression ana display equation olur
- probability fonksiyonlari mevcut decimal precision politikasini kullanir

## Settings / History / UI Degisiklikleri
### Settings
Yeni bir global istatistik ayari eklenmedi.
Variance/stddev default policy kod seviyesinde sabit tutuldu:
- variance -> sample
- stddev -> sample

### History
History modeline su alanlar eklendi:
- `datasetDisplayResult`
- `statisticsDisplayResult`
- `regressionDisplayResult`
- `probabilityDisplayResult`
- `summaryDisplayResult`
- `sampleSize`
- `statisticName`

### UI
UI tarafinda:
- DATASET / STATS / REGRESSION / PROBABILITY badge'leri
- sample size gosterimi
- regression summary alternatives
- keypad stats/probability kisayollari
- `data(` template insertion

Tam dataset editor bu fazda bilincli olarak eklenmedi; `data(` girisi ve keypad kisayollari ilk surum icin yeterli tutuldu.

## Unit / Vector / Matrix / Complex Etkilesimi
### Unit
Desteklenenler:
- `sum`, `mean`, `min`, `max`, `range`
- variance -> squared unit
- stddev -> original unit

Ornek:
- `mean(data(1 m, 20 cm)) -> 3/5 m`
- `variance(data(1 m, 20 cm)) -> 8/25 m^2`
- `stddev(data(1 m, 20 cm)) -> 2√2/5 m`

### Vector
Tek dataset argumani olarak vector coercion desteklenir.

### Matrix
Default olarak unsupported.

### Complex
Default olarak unsupported.

## Guard Limitleri
Faz 8 guard limitleri:
- max exact dataset length: `10000`
- dataset preview limiti: `50`
- max factorial input: `5000`
- max distribution summation iterations: `100000`

Bu guard'lar Faz 3-7'de gelen:
- BigInt digit guard
- symbolic factor/term guard
- matrix element guard
- unit expression guard

mekanizmalarini bozmaz; onlarla birlikte calisir.

## Sonraki Faz Icin Graphing / Function Plotting Plani
Faz 9 icin dogal sonraki adim graphing/function plotting katmani olur.

Onerilen taslak:
- `FunctionValue`
- plot expression parser
- viewport modeli
- adaptive sampling
- discontinuity handling
- trace/cursor helpers
- root/intersection helpers
- graph panel + history/export entegrasyonu

`RegressionValue` ve dataset preview altyapisi, ileride scatter plot + regression line gosterimi icin dogrudan yeniden kullanilabilir.
