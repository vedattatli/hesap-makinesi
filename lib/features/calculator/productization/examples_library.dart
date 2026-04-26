import '../../../core/calculator/calculator.dart';
import '../worksheet/worksheet_block.dart';
import '../worksheet/worksheet_document.dart';
import '../worksheet/worksheet_graph_state.dart';

enum CalculatorExampleTarget { calculator, graph, worksheet }

class CalculatorExample {
  const CalculatorExample({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.expression,
    required this.target,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String expression;
  final CalculatorExampleTarget target;
}

abstract final class CalculatorExamplesLibrary {
  static const examples = <CalculatorExample>[
    CalculatorExample(
      id: 'basic-scientific',
      title: 'Scientific basics',
      category: 'Basic',
      description: 'Trig plus a square root in the current angle mode.',
      expression: 'sin(30) + sqrt(16)',
      target: CalculatorExampleTarget.calculator,
    ),
    CalculatorExample(
      id: 'exact-symbolic',
      title: 'Exact symbolic',
      category: 'Exact',
      description: 'Keeps rational and radical arithmetic exact.',
      expression: '1/3 + 1/6 + sqrt(8)',
      target: CalculatorExampleTarget.calculator,
    ),
    CalculatorExample(
      id: 'complex',
      title: 'Complex number',
      category: 'Complex',
      description: 'Complex-domain expression using i.',
      expression: 'sqrt(-1) + 2*i',
      target: CalculatorExampleTarget.calculator,
    ),
    CalculatorExample(
      id: 'matrix',
      title: 'Matrix inverse',
      category: 'Matrix',
      description: 'A small exact matrix inverse example.',
      expression: 'inv(mat(2,2,1,2,3,4))',
      target: CalculatorExampleTarget.calculator,
    ),
    CalculatorExample(
      id: 'units',
      title: 'Unit conversion',
      category: 'Units',
      description: 'Local unit-aware conversion with no network dependency.',
      expression: 'to(72 km/h, m/s)',
      target: CalculatorExampleTarget.calculator,
    ),
    CalculatorExample(
      id: 'statistics',
      title: 'Statistics mean',
      category: 'Stats',
      description: 'Dataset constructor plus descriptive statistics.',
      expression: 'mean(data(1,2,3,4))',
      target: CalculatorExampleTarget.calculator,
    ),
    CalculatorExample(
      id: 'graph-sine',
      title: 'Sine graph',
      category: 'Graph',
      description: 'Graph sin(x) over one full period.',
      expression: 'sin(x)',
      target: CalculatorExampleTarget.graph,
    ),
    CalculatorExample(
      id: 'worksheet-variable',
      title: 'Worksheet variable',
      category: 'Worksheet',
      description: 'A worksheet-style expression that depends on a variable.',
      expression: 'a * 6',
      target: CalculatorExampleTarget.worksheet,
    ),
    CalculatorExample(
      id: 'solve-cas',
      title: 'CAS-lite solve',
      category: 'CAS-lite',
      description: 'Exact quadratic solving through CAS-lite.',
      expression: 'solve(x^2 - 4 = 0, x)',
      target: CalculatorExampleTarget.calculator,
    ),
  ];
}

abstract final class SampleWorksheetFactory {
  static List<WorksheetDocument> buildSamples({DateTime? timestamp}) {
    final now = (timestamp ?? DateTime.now().toUtc()).toUtc();
    return <WorksheetDocument>[
      _trigGraphDemo(now),
      _unitPhysicsDemo(now),
      _matrixDemo(now),
      _statisticsDemo(now),
      _casSolveDemo(now),
    ];
  }

  static WorksheetDocument _document({
    required String id,
    required String title,
    required DateTime now,
    required List<WorksheetBlock> blocks,
  }) {
    return WorksheetDocument(
      id: id,
      title: title,
      blocks: List<WorksheetBlock>.unmodifiable(blocks),
      createdAt: now,
      updatedAt: now,
      version: WorksheetDocument.currentVersion,
    );
  }

  static WorksheetDocument _trigGraphDemo(DateTime now) {
    return _document(
      id: 'sample-trig-graph',
      title: 'Sample: Trig Graph Demo',
      now: now,
      blocks: <WorksheetBlock>[
        WorksheetBlock.text(
          id: 'sample-trig-note',
          orderIndex: 0,
          title: 'Goal',
          text: 'Compare sin(x) and cos(x) over [-pi, pi].',
          format: WorksheetTextFormat.markdownLite,
          createdAt: now,
          updatedAt: now,
        ),
        WorksheetBlock.graph(
          id: 'sample-trig-graph-block',
          orderIndex: 1,
          title: 'sin/cos graph',
          graphState: _graphState(
            id: 'sample-trig-state',
            title: 'Trig comparison',
            expressions: const <String>['sin(x)', 'cos(x)'],
            xMin: -3.141592653589793,
            xMax: 3.141592653589793,
            yMin: -1.5,
            yMax: 1.5,
            now: now,
          ),
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }

  static WorksheetDocument _unitPhysicsDemo(DateTime now) {
    return _document(
      id: 'sample-unit-physics',
      title: 'Sample: Unit Physics Demo',
      now: now,
      blocks: <WorksheetBlock>[
        _variable(
          id: 'sample-mass',
          orderIndex: 0,
          name: 'mass',
          expression: '2 kg',
          now: now,
        ),
        _variable(
          id: 'sample-velocity',
          orderIndex: 1,
          name: 'velocity',
          expression: '3 m/s',
          now: now,
        ),
        _calculation(
          id: 'sample-energy',
          orderIndex: 2,
          title: 'Kinetic energy',
          expression: '0.5 * mass * velocity^2',
          unitMode: UnitMode.enabled,
          now: now,
        ),
      ],
    );
  }

  static WorksheetDocument _matrixDemo(DateTime now) {
    return _document(
      id: 'sample-matrix',
      title: 'Sample: Matrix Demo',
      now: now,
      blocks: <WorksheetBlock>[
        _calculation(
          id: 'sample-matrix-det',
          orderIndex: 0,
          title: 'Determinant',
          expression: 'det(mat(2,2,1,2,3,4))',
          now: now,
        ),
        _calculation(
          id: 'sample-matrix-inv',
          orderIndex: 1,
          title: 'Inverse',
          expression: 'inv(mat(2,2,1,2,3,4))',
          now: now,
        ),
      ],
    );
  }

  static WorksheetDocument _statisticsDemo(DateTime now) {
    return _document(
      id: 'sample-statistics',
      title: 'Sample: Statistics Regression Demo',
      now: now,
      blocks: <WorksheetBlock>[
        _calculation(
          id: 'sample-stats-mean',
          orderIndex: 0,
          title: 'Mean',
          expression: 'mean(data(1,2,3,4))',
          now: now,
        ),
        _calculation(
          id: 'sample-stats-regression',
          orderIndex: 1,
          title: 'Linear regression',
          expression: 'linreg(data(1,2,3), data(2,4,6))',
          now: now,
        ),
      ],
    );
  }

  static WorksheetDocument _casSolveDemo(DateTime now) {
    return _document(
      id: 'sample-cas-solve',
      title: 'Sample: CAS Solve Demo',
      now: now,
      blocks: <WorksheetBlock>[
        _calculation(
          id: 'sample-cas-solve-block',
          orderIndex: 0,
          title: 'Quadratic roots',
          expression: 'solve(x^2 - 4 = 0, x)',
          now: now,
        ),
        WorksheetBlock.casTransform(
          id: 'sample-cas-factor-block',
          orderIndex: 1,
          expression: 'x^2 - 4',
          transformType: WorksheetCasTransformType.factor,
          angleMode: AngleMode.degree,
          precision: 10,
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.real,
          unitMode: UnitMode.disabled,
          resultFormat: NumberFormatStyle.auto,
          title: 'Factor polynomial',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }

  static WorksheetBlock _variable({
    required String id,
    required int orderIndex,
    required String name,
    required String expression,
    required DateTime now,
  }) {
    return WorksheetBlock.variableDefinition(
      id: id,
      orderIndex: orderIndex,
      name: name,
      expression: expression,
      angleMode: AngleMode.degree,
      precision: 10,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.enabled,
      resultFormat: NumberFormatStyle.auto,
      createdAt: now,
      updatedAt: now,
    );
  }

  static WorksheetBlock _calculation({
    required String id,
    required int orderIndex,
    required String expression,
    required DateTime now,
    String? title,
    UnitMode unitMode = UnitMode.disabled,
  }) {
    return WorksheetBlock.calculation(
      id: id,
      orderIndex: orderIndex,
      expression: expression,
      angleMode: AngleMode.degree,
      precision: 10,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: unitMode,
      resultFormat: NumberFormatStyle.auto,
      createdAt: now,
      updatedAt: now,
      title: title,
      isStale: true,
    );
  }

  static WorksheetGraphState _graphState({
    required String id,
    required String title,
    required List<String> expressions,
    required double xMin,
    required double xMax,
    required double yMin,
    required double yMax,
    required DateTime now,
  }) {
    return WorksheetGraphState(
      id: id,
      title: title,
      expressions: expressions,
      viewport: GraphViewport(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax),
      autoY: false,
      showGrid: true,
      showAxes: true,
      initialSamples: 512,
      maxSamples: 4096,
      adaptiveDepth: 6,
      discontinuityThreshold: 0.6,
      minStep: 1e-6,
      angleMode: AngleMode.radian,
      numericMode: NumericMode.approximate,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
      precision: 10,
      createdAt: now,
      updatedAt: now,
    );
  }
}
