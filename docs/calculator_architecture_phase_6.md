# Calculator Architecture - Phase 6

## Faz 5'ten Devralinan Mimari

Faz 5 sonunda calculator core zaten Flutter'dan bagimsiz, typed value tabanli ve katmanliydi. Scalar dunyada `DoubleValue`, `RationalValue`, `SymbolicValue` ve `ComplexValue` birlikte calisiyordu; evaluator exact/approx, real/complex ve symbolic-lite davranislarini `CalculationContext` icinde tasiyordu. Uygulama tarafinda controller, settings, history, persistence ve presentation zaten ayrik sorumluluklarla kurulmustu.

Bu faz, bu mevcut mimariyi bozmadan lineer cebir katmani ekler. Temel tasarim ilkesi su oldu:

- scalar davranisi aynen korunur
- vector ve matrix yeni `CalculatorValue` tipleri olur
- evaluator islem dispatch'ini operand tiplerine gore yapar
- formatter mevcut scalar formatter'i entry bazinda tekrar kullanir
- UI ve history yeni sonuc tiplerini sadece gosterir, hesap mantigini ustlenmez

## Neden Vector / Matrix Ayrı CalculatorValue Tipleri?

Vektor ve matrisler scalar degerlerden yapisal olarak farklidir. Bunlari string ya da liste gibi tasimak yerine ayri `CalculatorValue` tipleri yapmak su avantajlari saglar:

- type-safe operation dispatch kurulabilir
- `valueKind` uzerinden formatter, history ve UI karar verebilir
- exact, symbolic ve complex entry'ler ayni kapsayici icinde korunabilir
- lineer cebir operasyonlari reusable bir modulde tutulabilir
- ileride `MatrixValue`, `VectorValue`, `UnitValue`, `TensorValue` gibi buyume icin zemin hazir kalir

## VectorValue Tasarimi

`VectorValue` immutable bir `List<CalculatorValue>` saklar. Bu fazda orientation ayri tip olarak modellenmedi; display standardi `[a, b, c]` seklinde kaldirildi. Politikalar:

- bos vector desteklenmez
- `isExact`: tum entry'ler exact ise true
- `isApproximate`: herhangi bir entry approximate ise true
- `toDouble()`: Euclidean norm doner
- `simplify()`: her entry sadeleşir ama tek elemanli vector scalar'a dusmez

Bu sayede `[1/2, √2, π, i]` gibi karmasik entry kombinasyonlari da tek kapsayici icinde korunur.

## MatrixValue Tasarimi

`MatrixValue` immutable satir listeleri saklar:

- `rows`
- `rowCount`
- `columnCount`
- `isSquare`

Politikalar:

- bos matrix desteklenmez
- non-rectangular satirlar hata verir
- 1x1 matrix scalar'a otomatik dusmez
- `isExact`: tum entry'ler exact ise true
- `isApproximate`: herhangi entry approximate ise true
- `toDouble()`: Frobenius norm doner

Bu tasarim, scalar entry turlerinden tamamen bagimsizdir; matrix entry olarak rational, symbolic, complex veya approximate degerler tasinabilir.

## Matrix Literal ve Constructor Tasarimi

Bu fazda iki giris yolu desteklenir:

1. Function constructor

- `vec(1,2,3)`
- `vector(1,2,3)`
- `mat(2,2,1,2,3,4)`
- `matrix(2,2,1,2,3,4)`
- `identity(3)`
- `zeros(2,3)`
- `ones(2,2)`
- `diag(1,2,3)`

`mat(rows, cols, values...)` row-major yorumlanir. `rows * cols` ile deger sayisi eslesmezse typed `invalidMatrixShape` uretilir.

2. Bracket literal

- `[1,2,3]` -> vector
- `[[1,2],[3,4]]` -> matrix
- `[[1,2,3]]` -> 1x3 matrix
- `[[1],[2],[3]]` -> 3x1 matrix

Nested row uzunluklari farkliysa parser/evaluator typed hata verir. Empty literal'lar bu fazda bilincli olarak reddedilir.

## Scalar / Vector / Matrix Operation Dispatch

Evaluator arithmetic dispatch'i operand tiplerine gore yapar:

- scalar + scalar -> mevcut Faz 1-5 davranisi
- vector + vector -> element-wise toplama
- matrix + matrix -> shape-equal toplama
- scalar * vector / vector * scalar -> scale
- scalar * matrix / matrix * scalar -> scale
- matrix * matrix -> lineer cebir carpimi
- matrix * vector -> vector sonucu

Bilincsiz sessiz anlam yukleme yapilmadi. Ornegin:

- `vector * vector` dot product yapmaz, kullanici `dot(a, b)` yazmalidir
- `matrix / matrix` otomatik inverse yapmaz
- `vector + scalar` desteklenmez
- `matrix + scalar` desteklenmez

Bu kararlar hata durumlarini daha acik ve tahmin edilebilir tutar.

## Exact / Symbolic / Complex Entry Desteği

Vector ve matrix entry'leri `CalculatorValue` olarak tutuldugu icin asagidaki kombinasyonlar calisir:

- exact rational: `[[1/2, 3/4], [5/6, 7/8]]`
- symbolic: `[[π, 0], [0, π]]`
- radical symbolic: `[[√2, 0], [0, √2]]`
- complex: `[[i, 0], [0, i]]`

Determinant ve basic matrix arithmetic mevcut scalar helper katmanini kullandigi icin bu entry tiplerini tekrar yazmadan reuse eder.

## Determinant ve Inverse Algoritmasi

### Determinant

Determinant icin karma bir strateji secildi:

- 1x1, 2x2, 3x3: dogrudan kapali form
- exact matrixlerde: recursive minor / Laplace expansion
- approximate matrixlerde: elimination tabanli hesap

Bu sayede küçük exact matrixlerde rational/symbolic/complex exactlik korunuyor; daha buyuk approximate senaryolarda ise daha hizli yol kullaniliyor.

### Inverse

Inverse icin Gauss-Jordan elimination kullanildi. Exact rational ve exact complex entry'ler scalar helper seviyesinde desteklendigi surece sonuc da exact kalabiliyor. Singular matrix durumunda `singularMatrix` hatasi donuyor.

Genel buyuk symbolic inverse bu fazda hedeflenmedi; scalar layer exact destek vermedigi noktalarda hata veya computation guard devreye girebilir.

## Computation Guard Limitleri

Bu fazda lineer cebir icin su korumalar eklendi:

- matrix constructor max total elements: 400
- exact determinant max size: 6x6
- approximate determinant max size: 12x12
- inverse max size: 10x10
- result preview max rows: 6
- result preview max columns: 6

Bu limitler UI donmalarini ve symbolic patlamayi engellemek icin secildi. Scalar taraftaki Faz 3-5 BigInt, exponent ve symbolic term guard'lari da korunuyor.

## Result Formatting Tasarimi

Formatter yeni value tiplerini scalar formatter'in uzerine kurar:

- vector display: `[1, 2, 3]`
- matrix compact display: `[[1, 2], [3, 4]]`
- shape metadata:
  - vector -> `3 x 1`
  - matrix -> `2 x 2`

Entry formatting scalar formatter'i tekrar kullanir. Yani matrix icindeki `1/2`, `√2`, `π`, `3 + 4i` gibi degerler mevcut exact/symbolic/complex kurallariyla gosterilir.

Buyuk matrixlerde ana `displayResult` preview olabilir; tam icerik `matrixDisplayResult` alaninda saklanir. Bu, result card'in tasmasini engellerken history ve alternatif gosterim bilgisini korur.

## Settings / History / UI Degisiklikleri

### Settings

Bu fazda yeni kalici global ayar eklenmedi. Var olan `resultFormat`, `numericMode` ve `calculationDomain` matrix/vector entry formatting icin reuse edilir.

### History

History item modeli su alanlarla genisletildi:

- `vectorDisplayResult`
- `matrixDisplayResult`
- `shapeDisplayResult`
- `rowCount`
- `columnCount`

Duplicate policy artik `valueKind`, `shape`, `numericMode`, `resultFormat` ve `calculationDomain` farklarini da dikkate alir.

### UI

UI tarafinda:

- `VECTOR` ve `MATRIX` badge eklendi
- shape gosterimi eklendi
- keypad'e `vec`, `mat`, `dot`, `cross`, `norm`, `det`, `inv`, `tr`, `id` butonlari eklendi
- matrix editor dialog bu fazda eklenmedi
- en azindan template insertion ile `vec(` ve `mat(` akisi saglandi

## Sonraki Faz: Unit Conversion / Dimension Analysis Plani

Bir sonraki mantikli buyume, typed `UnitValue` katmani kurmak olur. O fazda:

- SI temel boyut vektoru
- derived unit tanimlari
- unit parser
- conversion engine
- temperature offset handling
- unit-aware scalar arithmetic
- UI unit converter paneli

eklenebilir.

En onemli mimari avantaji su: `MatrixValue` ve `VectorValue` entry olarak `CalculatorValue` tuttugu icin ileride unit-aware vector veya matrix yapilari icin de temel hazir durumda.
