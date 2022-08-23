# Dart package to solve the Chinese Postman Problem for undirected graphs:
#### How to travel through each edge and return to the start in the shortest way possible
![img.png](img.png)

```dart
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

```

This outputs the following:
```dart
[2, 5, 7, 5, 4, 1, 3, 4, 6, 3, 6, 7, 2, 5, 1, 2]
total cost: 123.0
```
The start/end vertex is 2.

The list above shows the path to traverse each edge and return to vertex 2.

Some edges are repeated. This is unavoidable. A more detailed explanation of how to solve the problem is below:
## Chinese Postman Problem
Firstly, the graph must be connected (there should be a path between any 2 vertices).
![disconnected.png](disconnected.png)


The first thing to do is count how many edges meet at each vertex. If this number of edges is odd, the vertex is called an odd vertex.
