import '../worksheet_block.dart';
import 'worksheet_dependency_node.dart';

class WorksheetDependencyGraph {
  const WorksheetDependencyGraph({
    required this.nodesByBlockId,
    required this.dependenciesByBlockId,
    required this.dependentsByBlockId,
    required this.symbolOwners,
  });

  final Map<String, WorksheetDependencyNode> nodesByBlockId;
  final Map<String, Set<String>> dependenciesByBlockId;
  final Map<String, Set<String>> dependentsByBlockId;
  final Map<String, String> symbolOwners;

  Set<String> ancestorsOf(String blockId) {
    final visited = <String>{};
    void visit(String id) {
      for (final dependency in dependenciesByBlockId[id] ?? const <String>{}) {
        if (visited.add(dependency)) {
          visit(dependency);
        }
      }
    }

    visit(blockId);
    return visited;
  }

  Set<String> descendantsOf(String blockId) {
    final visited = <String>{};
    void visit(String id) {
      for (final dependent in dependentsByBlockId[id] ?? const <String>{}) {
        if (visited.add(dependent)) {
          visit(dependent);
        }
      }
    }

    visit(blockId);
    return visited;
  }

  String dependencySummary(String blockId) {
    final node = nodesByBlockId[blockId];
    if (node == null || node.dependencies.isEmpty) {
      return 'No dependencies';
    }
    return node.dependencies.join(', ');
  }

  List<WorksheetBlock> displayOrderedBlocks(List<WorksheetBlock> blocks) {
    final copy = blocks.toList(growable: false);
    copy.sort((left, right) => left.orderIndex.compareTo(right.orderIndex));
    return copy;
  }
}
