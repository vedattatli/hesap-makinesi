# Calculator Architecture - Phase 12

## Faz 11'den Devralınan Durum
Faz 11 sonunda worksheet-scoped variable/function resolver, dependency graph, topological sort, stale propagation, scoped worksheet execution ve scoped graph block evaluation zaten mevcuttu. Calculator engine ve graph engine Flutter'dan bağımsız kalıyor, worksheet UI ise ayrı presentation katmanı olarak çalışıyordu. Bu faz, o resolver ve dependency altyapısının üstüne CAS-lite solve/transform katmanı ekler.

## CAS-lite ile Tam CAS Farkı
Bu faz tam symbolic algebra sistemi değildir. Hedef; equation object modeli, güvenli polynomial detection, exact linear/quadratic solving, guarded rational-root factoring, interval tabanlı numeric solving ve sınırlı derivative/integral transforms sağlamaktır. General symbolic simplification, equation systems, matrix solve, inequality solve ve broad symbolic factorization bilinçli olarak dışarıda bırakılır.

## Equation Parsing Yaklaşımı
Lexer tarafına `=` token eklendi. Parser default olarak `allowEquation: false` çalışır; bu yüzden normal expression parse akışı değişmez ve `2 = 2` hâlâ normal evaluate yolunda syntax/unexpected token olarak kalır. `solve(...)`, `nsolve(...)` ve equation-aware worksheet/dependency bağlamlarında parser `allowEquation: true` ile çalıştırılır ve `lhs = rhs` ifadesi `EquationNode` üretir. Birden fazla `=` bu fazda desteklenmez.

## EquationValue Tasarımı
`EquationValue`, AST tabanlı `EquationModel` saklar. Model:
- `left`
- `right`
- `normalizedLeft`
- `normalizedRight`
- `displayEquation`

Equation object numeric değildir; `toDouble()` anlamlı olmadığından `NaN` döner. Ana amaç solve/result/export/UI için symbolic metadata taşımaktır.

## SolveResultValue Tasarımı
`SolveResultValue` şu alanları taşır:
- `variableName`
- `equation`
- `solutions`
- `method`
- `domain`
- `exact`
- `warnings`
- `noSolutionReason`
- `infiniteSolutions`
- `intervalMin`
- `intervalMax`

Bu model exact ve approximate çözüm yollarını aynı value tipinde temsil eder. Tek çözüm, çoklu çözüm, çözüm yok ve sonsuz çözüm senaryoları tek yerde toplanır.

## Polynomial Detection Yaklaşımı
`PolynomialDetector` expression AST'den tek değişkenli sparse polynomial üretmeye çalışır. Desteklenen formlar:
- sabitler
- değişken
- toplama/çıkarma
- çarpma
- integer exponent ile kuvvet
- unary minus
- scalar'a bölme
- worksheet scoped numeric constants
- worksheet user-defined function body substitution

Desteklenmeyen formlar:
- `sin(x)`
- `x^x`
- `1/x`
- `sqrt(x)`
- matrix/vector/dataset/regression outputs
- incompatible unit/complex coefficients

Exact closed-form solve için derece limiti `2`, rational-root factoring için derece limiti `6`.

## Exact Solver Kapsamı
Desteklenen exact solve yolları:
- Degree 0: no solution / infinite solutions
- Linear: `a*x + b = 0`
- Quadratic: discriminant tabanlı exact çözüm
- Rational-root polynomial: degree `3..6` için guarded rational root theorem + deflation

Quadratic çözümler mevcut symbolic-lite radical ve complex değer sistemini reuse eder. Real domain `D < 0` ise no real solution, complex domain ise exact complex pair üretir.

## Numeric Solver Fallback
Non-polynomial solving veya explicit `nsolve(...)` için numeric fallback kullanılır. Bu katman `GraphAnalysis.roots` ile aynı sampling + sign-change + bisection yaklaşımını reuse eder. Sonsuz aralık taranmaz; interval zorunludur. Guard limitleri:
- max scan samples: `2048`
- max bisection iterations: `80`
- max returned roots: `100`

## Complex Domain Solve Yaklaşımı
Complex domain exact solve yalnız güvenli quadratic kapsamında açılır. Örnek: `solve(x^2 + 1 = 0, x)` complex domain'de `-i, i` üretir. General complex numeric solving bu fazın dışında tutulur. Rational-root higher-degree complex factoring yapılmaz; real exact kökler korunur, daha geniş complex solve sonraki faza bırakılır.

## Derivative Helper Kapsamı
`diff` / `derivative` sınırlı symbolic transform üretir. Desteklenen kurallar:
- sabit
- solve variable
- unary minus
- addition/subtraction
- product rule
- quotient rule
- integer power
- `sin`, `cos`, `tan`, `exp`, `ln`
- güvenli chain rule

Unsupported forms typed `unsupportedExpressionTransform` veya `invalidDerivative` ile döner. `derivativeAt` önce symbolic derivative dener, başarısızsa guarded numeric central difference fallback kullanır.

## Integral Helper Kapsamı
`integral(expr, variable)` symbolic-lite indefinite integral için sınırlı kural seti kullanır:
- constant
- `x^n`
- linear combination
- direct `sin`, `cos`, `exp`
- scalar multiplication

Unsupported indefinite integrals typed error verir. `integrate(expr, variable, min, max)` bounded numeric integral olarak `GraphAnalysis.area` ile hizalanır.

## Worksheet SolveBlock Tasarımı
Yeni `WorksheetBlockType.solve` eklendi. Solve block alanları:
- `expression` as equation/expression text
- `solveVariableName`
- `intervalMinExpression`
- `intervalMaxExpression`
- `solveMethodPreference`
- `result`
- `dependencies`
- `isStale`
- `lastEvaluatedAt`
- worksheet error alanları
- mode snapshot

Solve block sembol tanımlamaz; yalnız solve sonucu üretir. Upstream variable/function dependencies değişirse stale olur.

## Dependency Graph Integration
Dependency analyzer artık:
- `EquationNode`
- solve block
- solve/diff/integral style local variable ignore
- graph `x` ignore
- built-in names ignore
- unit identifiers ignore

yapabiliyor. Böylece `solve(a*x+b=0, x)` yalnız `a` ve `b`'ye bağlanır; `x` dependency sayılmaz.

## Graph Root Solver Reuse
Numeric solving, graph helper kök taramasıyla hizalı kalır. `root(...)` / `roots(...)` graph API'leri bozulmadan devam eder; `solve(..., x, min, max)` fallback yolu aynı numerik çekirdeği kullanır. Bu sayede root sonuçları ve solve sonuçları tolerans/guard açısından tutarlı kalır.

## UI Solve Yaklaşımı
UI tarafında:
- keypad'e `solve`, `eq`, `nsolve`, `diff`, `derivativeAt`, `integral`, `integrate`
- result card'a `EQUATION`, `SOLVE`, `CAS-LITE`, `NUMERIC SOLVE`, `DERIVATIVE`, `INTEGRAL`
- worksheet paneline `Solve block`
- solve block kartına equation, variable, interval ve method alanları

eklendi. Standalone calculator global resolver hâlâ kapalıdır.

## Export / Storage / Backward Compatibility
Worksheet storage şeması backward-compatible alan genişletmesiyle solve block destekler. Solve block metadata Markdown/CSV export'a eklenir. History serialization solve/equation/transform metadata alanlarıyla genişletilir. Full dependency graph serialize edilmez; derived structure olarak yeniden kurulur.

## Guard Limitleri
- max exact closed-form degree: `2`
- max rational-root degree: `6`
- max rational-root candidates: `5000`
- max numeric solve scan samples: `2048`
- max bisection iterations: `80`
- max solutions returned: `100`
- max derivative transform node count: `1000`
- max integral transform node count: `1000`
- max worksheet function call depth: `32`

## Sonraki Faz İçin Plan
Bir sonraki doğal genişleme CAS-lite manipulation katmanı olur:
- limited simplify rules
- limited factor/expand
- equation systems
- inequality solve
- broader derivative rule table
- richer integral table
- solve steps UI
- graph solve overlay / highlighted roots
