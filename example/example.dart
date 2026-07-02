import 'package:chinese_postman/chinese_postman.dart';

void main() {
  Postman p = Postman();

  // Repeating entries in the graph will not add duplicate edges.
  // If the original graph contains duplicate edges,
  // add new vertices with a distance of 0 from other vertices.

  Map<int, Map<int, double>> graph = {
    1: {2: 6, 5: 10, 4: 10, 3: 10},
    2: {5: 7, 7: 16},
    3: {4: 10, 6: 7},
    4: {5: 1, 6: 5},
    5: {7: 7},
    6: {7: 13},
    // This will not change the result
    // since the edges are already above
    // 7: {2: 16, 5: 7, 6: 13}
  };

  List<int> tour = p.postmanTour(graph, startingVertex: 2);

  print(tour);
  print('total cost: ${p.cost}');
}
