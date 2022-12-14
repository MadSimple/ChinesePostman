import 'package:chinese_postman/chinese_postman.dart';

void main() {

  Postman p = Postman();

  Map<int, Map<int, double>> graph = {
    1: {2: 6, 5: 10, 4: 10, 3: 10},
    2: {5: 7, 7: 16},
    3: {4: 10, 6: 7},
    4: {5: 1, 6: 5},
    5: {7: 7},
    6: {7: 13}
  };

  List<int> tour = p.postmanTour(graph, startingVertex: 2);
  print(tour);
  print('total cost: ${p.cost()}');

}
