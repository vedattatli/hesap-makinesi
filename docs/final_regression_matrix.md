# Final Regression Matrix

Bu matris Faz 1-18 özelliklerini release öncesi must-pass örneklerle izlemek için hazırlanmıştır. Otomasyon kapsamı test paketinde, manuel smoke kapsamı ise release adaylarında kullanılmalıdır.

| Alan | Must-pass örnek | Beklenen davranış | Test odağı |
| --- | --- | --- | --- |
| Lexer | `to(100 cm, m)` | Unit implicit multiplication tokenları doğru üretilir | Tokenization |
| Parser | `solve(x^2 - 4 = 0, x)` | Equation syntax yalnız solve bağlamında parse edilir | Equation parse |
| Parser Guard | `x^2 = 4` | Normal expression bağlamında syntax/typed error | Equation isolation |
| Scalar | `1/3 + 1/6` exact | `1/2` | Rational exact |
| Trig | `sin(30)` degree | `0.5` | Angle mode |
| Symbolic | `sqrt(8)` exact/symbolic | Simplified radical | Symbolic formatting |
| Complex | `conj(3+4i)` | `3 - 4i` | Complex helper |
| Vector | `vec(1,2,3)+vec(4,5,6)` | Elementwise vector result | Vector arithmetic |
| Matrix | `det(mat(2,2,1,2,3,4))` | `-2` | Determinant |
| Matrix Guard | `inv(mat(2,2,1,2,2,4))` | Singular matrix typed error | Guard/error |
| Units | `to(100 cm, m)` | `1 m` | Conversion |
| Temperature | `to(32 degF, degC)` | `0 degC` | Offset units |
| Dataset | `mean(data(1,2,3,4))` | `5/2` exact or `2.5` approx | Stats exactness |
| Probability | `binomPmf(10,0.5,3)` | Numeric/exact probability | Distribution |
| Regression | `corr(data(1,2,3),data(2,4,6))` | `1` | Regression |
| Graph Scope | `evalAt(x^2, 3)` | `9` | Scoped variable |
| Graph Plot | `plot(1/x, -1, 1)` | Segment break around zero | Discontinuity |
| Roots | `roots(x^2 - 4, -5, 5)` | `[-2, 2]` | Numeric graph root |
| Worksheet | variable `a=2`, calc `a+3` | `5` inside worksheet | Scoped symbols |
| Worksheet Isolation | normal `a+1` | Undefined variable/function error | Global resolver off |
| Dependency Graph | `a=b+1`, `b=a+1` | Cycle error, no crash | Topological sort |
| Solve | `solve(2*x+3=7,x)` | `x = 2` | Exact linear |
| Quadratic | `solve(x^2-4=0,x)` | `x = {-2, 2}` | Exact quadratic |
| Complex Solve | `solve(x^2+1=0,x)` complex | `x = {-i, i}` | Complex domain |
| Numeric Solve | `nsolve(cos(x)-x,x,0,1)` | Approx `0.739085` | Bisection |
| CAS Simplify | `simplify(x+x)` | `2*x` or canonical equivalent | Transform |
| CAS Expand | `expand((x+1)^2)` | `x^2 + 2*x + 1` | Polynomial expansion |
| CAS Factor | `factor(x^2-4)` | `(x - 2)(x + 2)` | Factorization |
| Systems | `linsolve(mat(2,2,2,1,1,-1), vec(5,1))` | `[2, 1]` | Linear solve |
| Export Markdown | Worksheet with calc/solve/graph | Deterministic markdown text | Export |
| Export CSV | Worksheet calculations | RFC-style escaping | Export |
| SVG | Graph block export | Separate paths per segment | Graph export |
| Backup | Export then parse JSON | Settings/history/worksheets roundtrip | Productization |
| Localization | Turkish/English labels | Strings switch cleanly | I18n |
| Accessibility | Result/graph/worksheet semantics | Screen reader summary present | Semantics |
| Reduced Motion | Setting enabled | Animations shortened/disabled | A11y setting |
| High Contrast | Setting enabled | Badge/error/focus readable | Theme |
| Keyboard | `Enter`, `Ctrl+K`, `Ctrl+L` | Expected command behavior | Shortcuts |
| Performance | graph/matrix/worksheet guards | Typed limits, no hang | Hardening |

## Release Smoke Flow

1. Launch app and verify CALC default mode.
2. Evaluate `1/3 + 1/6` in exact mode.
3. Save result to worksheet.
4. Add variable `a = 2`.
5. Add solve block `a*x + 4 = 0`, variable `x`, run all.
6. Open graph panel and plot `sin(x)`.
7. Export worksheet Markdown and graph SVG preview.
8. Export backup JSON and parse/restore through preview workflow.
9. Switch language and high-contrast settings.
10. Verify normal calculator still rejects `a+1` outside worksheet scope.
