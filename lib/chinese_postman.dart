library chinese_postman;


import 'package:dijkstra/dijkstra.dart';
import 'dart:core';
import 'dart:math' as math;

const int maxInt = 9999999999999999;

/*
Blossom algorithm for maximum matchings translated to Dart
from EdmondsBlossom by simlu https://github.com/simlu/EdmondsBlossom
and EdmondsBlossom by mattkrick https://github.com/mattkrick/EdmondsBlossom
both based on Python implementation at http://jorisvr.nl/maximummatching.html

The 'Wolfram Demonstrations Project' at
https://demonstrations.wolfram.com/TheBlossomAlgorithmForWeightedGraphs/#more
by Stan Wagon was extremely useful for further understanding of the
Edmonds blossom algorithm and for testing.

Postman().postmanTour method alters code to find minimum-weight
instead of maximum-weight matching.
*/
class Blossom {
  bool checkDelta = false;
  bool checkOptimum = false;
  bool debug = false;

  List<List<int>> edges = [];
  bool maxCardinality = false;
  int nEdge = 0;
  int nVertex = 0;
  int maxWeight = 0;
  List<int> endPoint = [];
  List<List<int>> neighBend = [];
  List<int> mate = [];
  List<int> label = [];
  List<int> labelEnd = [];
  List<int> inBlossom = [];
  List<int> blossomParent = [];
  List<List<int>> blossomChilds = [];
  List<int> blossomBase = [];
  List<List<int>> blossomEndps = [];
  List<int> bestEdge = [];
  List<List<int>> blossomBestEdges = [];
  List<int> unusedBlossoms = [];
  List<int> dualVar = [];
  List<bool> allowEdge = [];
  List<int> queue = [];

  Blossom(List<List<int>> e, bool mc) {
    edges = e;
    maxCardinality = mc;

    int nedge = e.length;
    int nvertex = 0;
    for (List<int> edge in e) {
      if (edge[0] >= nvertex) {
        nvertex = edge[0] + 1;
      }
      if (edge[1] >= nvertex) {
        nvertex = edge[1] + 1;
      }
    }
    nEdge = nedge;
    nVertex = nvertex;

    int maxweight = 0;
    for (List<int> edge in e) {
      maxweight = math.max(edge[2], maxweight);
    }
    maxWeight = maxweight;

    List<int> endpoint = List.filled(2 * nedge, -1);
    for (int p = 0; p < 2 * nedge; p++) {
      endpoint[p] = e[p ~/ 2][p % 2];
    }
    endPoint = endpoint;

    List<List<int>> neighbend = [];
    for (int n = 0; n < nvertex; n++) {
      neighbend.add([]);
    }
    for (int k = 0; k < nEdge; k++) {
      int i = e[k][0];
      int j = e[k][1];
      neighbend[i].add(2 * k + 1);
      neighbend[j].add(2 * k);
    }
    neighBend = neighbend;

    List<int> mateTemp = List.filled(nvertex, -1);
    mate = mateTemp;

    List<int> labelTemp = List.filled(2 * nVertex, -1);
    label = labelTemp;

    List<int> labelend = List.filled(2 * nvertex, -1);
    labelEnd = labelend;

    List<int> inblossom = [];

    for (int i = 0; i < nVertex; i++) {
      inblossom.add(i);
    }
    inBlossom = inblossom;

    List<int> blossomparent = List.filled(2 * nvertex, -1);
    blossomParent = blossomparent;

    List<List<int>> blossomchilds = [];
    for (int n = 0; n < 2 * nvertex; n++) {
      blossomchilds.add([]);
    }
    blossomChilds = blossomchilds;

    List<int> blossombase = List.filled(2 * nvertex, -1);
    for (int i = 0; i < nvertex; i++) {
      blossombase[i] = i;
    }
    blossomBase = blossombase;

    List<List<int>> blossomendps = [];
    for (int n = 0; n < 2 * nvertex; n++) {
      blossomendps.add([]);
    }
    blossomEndps = blossomendps;

    List<int> bestedge = List.filled(2 * nvertex, -1);
    bestEdge = bestedge;

    List<List<int>> blossombestedges = [];
    for (int n = 0; n < 2 * nvertex; n++) {
      blossombestedges.add([]);
    }

    blossomBestEdges = blossombestedges;

    List<int> unusedblossoms = [];
    for (int i = 0; i < nvertex; i++) {
      unusedblossoms.add(i + nvertex);
    }
    unusedBlossoms = unusedblossoms;

    List<int> dualvar = List.filled(2 * nvertex, 0);
    for (int i = 0; i < nvertex; i++) {
      dualvar[i] = maxweight;
    }
    dualVar = dualvar;

    List<bool> allowedge = List.filled(nedge, false);
    allowEdge = allowedge;
  }

  int slack(int k) {
    List<int> edge = edges[k];
    return dualVar[edge[0]] + dualVar[edge[1]] - 2 * edge[2];
  }

  List<int> blossomLeaves(int b) {
    if (b < nVertex) {
      return [b];
    }
    List<int> leaves = [];
    var childList = blossomChilds[b];
    for (int t = 0; t < childList.length; t++) {
      if (childList[t] <= nVertex) {
        leaves.add(childList[t]);
      } else {
        var leafList = blossomLeaves(childList[t]);
        for (var v = 0; v < leafList.length; v++) {
          leaves.add(leafList[v]);
        }
      }
    }
    return leaves;
  }

  void assignLabel(int w, int t, int p) {
    int b = inBlossom[w];
    label[w] = label[b] = t;
    labelEnd[w] = labelEnd[b] = p;
    bestEdge[w] = bestEdge[b] = -1;
    if (t == 1) {
      queue.addAll(blossomLeaves(b));
    } else if (t == 2) {
      int base = blossomBase[b];
      assignLabel(endPoint[mate[base]], 1, mate[base] ^ 1);
    }
  }

  int scanBlossom(int v, int w) {
    List<int> path = [];
    int base = -1;

    while (v != -1 || w != -1) {
      int b = inBlossom[v];
      if ((label[b] & 4) != 0) {
        base = blossomBase[b];
        break;
      }
      path.add(b);
      label[b] = 5;
      if (labelEnd[b] == -1) {
        v = -1;
      } else {
        v = endPoint[labelEnd[b]];
        b = inBlossom[v];

        v = endPoint[labelEnd[b]];
      }
      if (w != -1) {
        int t = v;
        v = w;
        w = t;
      }
    }
    for (int b in path) {
      label[b] = 1;
    }
    return base;
  }

  void addBlossom(int base, int k) {
    int v = edges[k][0];
    int w = edges[k][1];
    int bb = inBlossom[base];
    int bv = inBlossom[v];
    int bw = inBlossom[w];

    int b = unusedBlossoms.removeLast();

    blossomBase[b] = base;
    blossomParent[b] = -1;
    blossomParent[bb] = b;
    List<int> path = [];
    blossomChilds[b] = path;
    List<int> endps = [];
    blossomEndps[b] = endps;

    while (bv != bb) {
      blossomParent[bv] = b;
      blossomChilds[b].add(bv);
      blossomEndps[b].add(labelEnd[bv]);

      v = endPoint[labelEnd[bv]];
      bv = inBlossom[v];
    }
    blossomChilds[b].add(bb);
    blossomChilds[b] = blossomChilds[b].reversed.toList();
    blossomEndps[b] = blossomEndps[b].reversed.toList();
    blossomEndps[b].add(2 * k);

    while (bw != bb) {
      blossomParent[bw] = b;
      blossomChilds[b].add(bw);
      blossomEndps[b].add(labelEnd[bw] ^ 1);
      w = endPoint[labelEnd[bw]];
      bw = inBlossom[w];
    }

    label[b] = 1;
    labelEnd[b] = labelEnd[bb];

    dualVar[b] = 0;

    List<int> leaves = blossomLeaves(b);

    for (int ii = 0; ii < leaves.length; ii++) {
      v = leaves[ii];
      if (label[inBlossom[v]] == 2) {
        queue.add(v);
      }
      inBlossom[v] = b;
    }

    List<int> bestedgeto = List.filled(2 * nVertex, -1);
    for (int bvi in blossomChilds[b]) {
      List<List<int>> nblists = [];
      if (blossomBestEdges[bvi].isEmpty) {
        List<int> blossomleaves = blossomLeaves(bvi);
        nblists = List.filled(blossomleaves.length, []);
        for (int i = 0; i < blossomleaves.length; i++) {
          List<int> intArraylist = neighBend[blossomleaves[i]];
          nblists[i] = List.filled(intArraylist.length, -1);
          for (int j = 0; j < intArraylist.length; j++) {
            nblists[i][j] = intArraylist[j] ~/ 2;
          }
        }
      } else {
        nblists = [blossomBestEdges[bvi]];
      }
      for (List<int> nblist in nblists) {
        for (int ki in nblist) {
          int i = edges[ki][0];
          int j = edges[ki][1];
          if (inBlossom[j] == b) {
            j = i;
          }
          int bj = inBlossom[j];
          if (bj != b &&
              label[bj] == 1 &&
              (bestedgeto[bj] == -1 || slack(ki) < slack(bestedgeto[bj]))) {
            bestedgeto[bj] = ki;
          }
        }
      }

      blossomBestEdges[bvi] = [];
      bestEdge[bvi] = -1;
    }
    List<int> buffer = [];
    for (int ki in bestedgeto) {
      if (ki != -1) {
        buffer.add(ki);
      }
    }
    blossomBestEdges[b] = buffer;

    bestEdge[b] = -1;
    for (int ki in blossomBestEdges[b]) {
      if (bestEdge[b] == -1 || slack(ki) < slack(bestEdge[b])) {
        bestEdge[b] = ki;
      }
    }
  }

  void expandBlossom(int b, bool endstage) {
    for (int s in blossomChilds[b]) {
      blossomParent[s] = -1;
      if (s < nVertex) {
        inBlossom[s] = s;
      } else if (endstage && dualVar[s] == 0) {
        expandBlossom(s, endstage);
      } else {
        for (int v in blossomLeaves(s)) {
          inBlossom[v] = s;
        }
      }
    }

    if (!endstage && label[b] == 2) {
      int entrychild = inBlossom[endPoint[labelEnd[b] ^ 1]];

      int j = blossomChilds[b].indexOf(entrychild);
      int endptrick = -1;
      int jstep = -1;
      if ((j & 1) != 0) {
        j -= blossomChilds[b].length;
        jstep = 1;
        endptrick = 0;
      } else {
        jstep = -1;
        endptrick = 1;
      }

      int p = labelEnd[b];
      while (j != 0) {
        label[endPoint[p ^ 1]] = 0;
        label[endPoint[blossomEndps[b][
                ((blossomEndps[b].length + (j - endptrick)) %
                    blossomEndps[b].length)] ^
            endptrick ^
            1]] = 0;
        assignLabel(endPoint[p ^ 1], 2, p);
        allowEdge[blossomEndps[b][((blossomEndps[b].length + (j - endptrick)) %
                blossomEndps[b].length)] ~/
            2] = true;
        j += jstep;
        p = blossomEndps[b][(blossomEndps[b].length + (j - endptrick)) %
                blossomEndps[b].length] ^
            endptrick;
        allowEdge[p ~/ 2] = true;
        j += jstep;
      }

      int bv = blossomChilds[b][j];
      label[endPoint[p ^ 1]] = label[bv] = 2;
      labelEnd[endPoint[p ^ 1]] = labelEnd[bv] = p;
      bestEdge[bv] = -1;

      j += jstep;
      while (blossomChilds[b]
              [(blossomChilds[b].length + j) % blossomChilds[b].length] !=
          entrychild) {
        bv = blossomChilds[b]
            [(blossomChilds[b].length + j) % blossomChilds[b].length];
        if (label[bv] == 1) {
          j += jstep;
          continue;
        }
        int v = -1;
        for (int vt in blossomLeaves(bv)) {
          v = vt;
          if (label[vt] != 0) {
            break;
          }
        }

        if (label[v] != 0) {
          label[v] = 0;
          label[endPoint[mate[blossomBase[bv]]]] = 0;
          assignLabel(v, 2, labelEnd[v]);
        }
        j += jstep;
      }
    }

    label[b] = labelEnd[b] = -1;
    blossomChilds[b] = blossomEndps[b] = [];
    blossomBase[b] = -1;
    blossomBestEdges[b] = [];
    bestEdge[b] = -1;
    unusedBlossoms.add(b);
  }

  void augmentBlossom(int b, int v) {
    int t = v;

    while (blossomParent[t] != b) {
      t = blossomParent[t];
    }
    if (t >= nVertex) {
      augmentBlossom(t, v);
    }

    int i = blossomChilds[b].indexOf(t);
    int j = i;
    int jstep = -1;
    int endptrick = -1;
    if ((i & 1) != 0) {
      j -= blossomChilds[b].length;
      jstep = 1;
      endptrick = 0;
    } else {
      jstep = -1;
      endptrick = 1;
    }

    while (j != 0) {
      j += jstep;
      t = blossomChilds[b]
          [(blossomChilds[b].length + j) % blossomChilds[b].length];
      int p = blossomEndps[b][(blossomEndps[b].length + (j - endptrick)) %
              blossomEndps[b].length] ^
          endptrick;
      if (t >= nVertex) {
        augmentBlossom(t, endPoint[p]);
      }
      j += jstep;
      t = blossomChilds[b]
          [(blossomChilds[b].length + j) % blossomChilds[b].length];
      if (t >= nVertex) {
        augmentBlossom(t, endPoint[p ^ 1]);
      }
      mate[endPoint[p]] = p ^ 1;
      mate[endPoint[p ^ 1]] = p;
    }

    for (int c = 0; c < i; c++) {
      blossomChilds[b].add(blossomChilds[b][c]);
      blossomEndps[b].add(blossomEndps[b][c]);
    }

    blossomChilds[b] = blossomChilds[b].sublist(i);
    blossomEndps[b] = blossomEndps[b].sublist(i);
    blossomBase[b] = blossomBase[blossomChilds[b][0]];
  }

  void augmentMatching(int k) {
    int v = edges[k][0];
    int w = edges[k][1];

    for (int ii = 0; ii < 2; ii++) {
      int s = 0;
      int p = 0;
      if (ii == 0) {
        s = v;
        p = 2 * k + 1;
      } else {
        s = w;
        p = 2 * k;
      }

      while (true) {
        int bs = inBlossom[s];

        if (bs >= nVertex) {
          augmentBlossom(bs, s);
        }

        mate[s] = p;

        if (labelEnd[bs] == -1) {
          break;
        }
        int t = endPoint[labelEnd[bs]];
        int bt = inBlossom[t];

        s = endPoint[labelEnd[bt]];
        int j = endPoint[labelEnd[bt] ^ 1];

        if (bt >= nVertex) {
          augmentBlossom(bt, j);
        }

        mate[j] = labelEnd[bt];

        p = labelEnd[bt] ^ 1;
      }
    }
  }

  void verifyOptimum() {
    int vdualoffset = -1;
    int dualvarminleft = maxInt;
    for (int i = 0; i < nVertex; i++) {
      dualvarminleft = math.min(dualvarminleft, dualVar[i]);
    }
    int dualvarminright = maxInt;
    for (int i = nVertex; i < dualVar.length; i++) {
      dualvarminright = math.min(dualvarminright, dualVar[i]);
    }
    if (maxCardinality) {
      vdualoffset = math.max(0, -dualvarminleft);
    } else {
      vdualoffset = 0;
    }

    for (int k = 0; k < nEdge; k++) {
      int i = edges[k][0];
      int j = edges[k][1];
      int wt = edges[k][2];
      int s = dualVar[i] + dualVar[j] - 2 * wt;
      List<int> iblossoms = [];
      List<int> jblossoms = [];
      while (blossomParent[iblossoms[iblossoms.length - 1]] != -1) {
        iblossoms.add(blossomParent[iblossoms[iblossoms.length - 1]]);
      }
      while (blossomParent[jblossoms[jblossoms.length - 1]] != 1) {
        jblossoms.add(blossomParent[jblossoms[jblossoms.length - 1]]);
      }
      iblossoms = iblossoms.reversed.toList();
      jblossoms = jblossoms.reversed.toList();

      for (int c = 0; c < iblossoms.length; c++) {
        int bi = iblossoms[c];
        int bj = jblossoms[c];
        if (bi != bj) {
          break;
        }
        s += 2 * dualVar[bi];
      }

      if (mate[i] / 2 == k || mate[j] / 2 == k) {}
    }

    for (int v = 0; v < nVertex; v++) {}

    for (int b = nVertex; b < 2 * nVertex; b++) {
      if (blossomBase[b] >= 0 && dualVar[b] > 0) {
        for (int i = 1; i < blossomEndps[b].length; i += 2) {
          int p = blossomEndps[b][i];
        }
      }
    }
  }

  void checkDelta2() {
    for (int v = 0; v < nVertex; v++) {
      if (label[inBlossom[v]] == 0) {
        int bd = maxInt;
        int bk = -1;
        for (int p in neighBend[v]) {
          int k = p ~/ 2;
          int w = endPoint[p];
          if (label[inBlossom[w]] == 1) {
            int d = slack(k);
            if (bk == -1 || d < bd) {
              bk = k;
              bd = d;
            }
          }
        }
      }
    }
  }

  void checkDelta3() {
    int bk = -1;
    int bd = maxInt;
    int tbk = -1;
    int tbd = maxInt;
    for (int b = 0; b < 2 * nVertex; b++) {
      if (blossomParent[b] == -1 && label[b] == 1) {
        for (int v in blossomLeaves(b)) {
          for (int p in neighBend[v]) {
            int k = p ~/ 2;
            int w = endPoint[p];
            if (inBlossom[w] != b && label[inBlossom[w]] == 1) {
              int d = slack(k);
              if (bk == -1 || d < bd) {
                bk = k;
                bd = d;
              }
            }
          }
        }
        if (bestEdge[b] != -1) {
          int i = edges[bestEdge[b]][0];
          int j = edges[bestEdge[b]][1];
          if (tbk == -1 || slack(bestEdge[b]) < tbd) {
            tbk = bestEdge[b];
            tbd = slack(bestEdge[b]);
          }
        }
      }
    }
  }

  List<int> maxWeightMatching() {
    if (edges.isEmpty) {
      return [];
    }

    for (int t = 0; t < nVertex; t++) {
      for (int i = 0; i < label.length; i++) {
        label[i] = 0;
      }

      bestEdge = [];
      for (int i = 0; i < 2 * nVertex; i++) {
        bestEdge.add(-1);
      }

      for (int i = nVertex; i < blossomBestEdges.length; i++) {
        blossomBestEdges[i] = [];
      }

      allowEdge = List.filled(nEdge, false);

      queue.clear();

      for (int v = 0; v < nVertex; v++) {
        if (mate[v] == -1 && label[inBlossom[v]] == 0) {
          assignLabel(v, 1, -1);
        }
      }

      int augmented = 0;

      while (true) {
        while (queue.isNotEmpty && augmented == 0) {
          int v = queue.last;
          queue.removeLast();

          int w = -1;

          for (int p in neighBend[v]) {
            int k = (p ~/ 2);
            w = endPoint[p];

            if (inBlossom[v] == inBlossom[w]) {
              continue;
            }
            int kslack = maxInt;
            if (!allowEdge[k]) {
              kslack = slack(k);
              if (kslack <= 0) {
                allowEdge[k] = true;
              }
            }
            if (allowEdge[k]) {
              if (label[inBlossom[w]] == 0) {
                assignLabel(w, 2, p ^ 1);
              } else if (label[inBlossom[w]] == 1) {
                int base = scanBlossom(v, w);
                if (base >= 0) {
                  addBlossom(base, k);
                } else {
                  augmentMatching(k);
                  augmented = 1;
                  break;
                }
              } else if (label[w] == 0) {
                label[w] = 2;
                labelEnd[w] = p ^ 1;
              }
            } else if (label[inBlossom[w]] == 1) {
              int b = inBlossom[v];
              if (bestEdge[b] == -1 || kslack < slack(bestEdge[b])) {
                bestEdge[b] = k;
              }
            } else if (label[w] == 0) {
              if (bestEdge[w] == -1 || kslack < slack(bestEdge[w])) {
                bestEdge[w] = k;
              }
            }
          }
        }
        if (augmented != 0) {
          break;
        }

        int deltatype = -1;
        int delta = maxInt;
        int deltaedge = maxInt;
        int deltablossom = maxInt;

        if (checkDelta) {
          checkDelta2();
          checkDelta3();
        }

        if (!maxCardinality) {
          deltatype = 1;
          for (int i = 0; i < nVertex; i++) {
            delta = math.min(delta, dualVar[i]);
          }
        }

        for (int v = 0; v < nVertex; v++) {
          if (label[inBlossom[v]] == 0 && bestEdge[v] != -1) {
            int d = slack(bestEdge[v]);
            if (deltatype == -1 || d < delta) {
              delta = d;
              deltatype = 2;
              deltaedge = bestEdge[v];
            }
          }
        }

        for (int b = 0; b < 2 * nVertex; b++) {
          if (blossomParent[b] == -1 && label[b] == 1 && bestEdge[b] != -1) {
            int kslack = slack(bestEdge[b]);
            int d = kslack ~/ 2;
            if (deltatype == -1 || d < delta) {
              delta = d;
              deltatype = 3;
              deltaedge = bestEdge[b];
            }
          }
        }

        for (int b = nVertex; b < 2 * nVertex; b++) {
          if (blossomBase[b] >= 0 &&
              blossomParent[b] == -1 &&
              label[b] == 2 &&
              (deltatype == -1 || dualVar[b] < delta)) {
            delta = dualVar[b];
            deltatype = 4;
            deltablossom = b;
          }
        }

        if (deltatype == -1) {
          deltatype = 1;
          int mindualvar = maxInt;
          for (int i = 0; i < nVertex; i++) {
            mindualvar = math.min(mindualvar, dualVar[i]);
          }
          delta = math.max(0, mindualvar);
        }

        for (int v = 0; v < nVertex; v++) {
          if (label[inBlossom[v]] == 1) {
            dualVar[v] -= delta;
          } else if (label[inBlossom[v]] == 2) {
            dualVar[v] += delta;
          }
        }

        for (int b = nVertex; b < 2 * nVertex; b++) {
          if (blossomBase[b] >= 0 && blossomParent[b] == -1) {
            if (label[b] == 1) {
              dualVar[b] += delta;
            } else if (label[b] == 2) {
              dualVar[b] -= delta;
            }
          }
        }

        int i = -1;
        int j = -1;
        if (deltatype == 1) {
          break;
        } else if (deltatype == 2) {
          allowEdge[deltaedge] = true;
          i = edges[deltaedge][0];
          j = edges[deltaedge][1];
          if (label[inBlossom[i]] == 0) {
            int ti = i;
            i = j;
            j = ti;
          }
          queue.add(i);
        } else if (deltatype == 3) {
          allowEdge[deltaedge] = true;
          i = edges[deltaedge][0];
          j = edges[deltaedge][1];
          queue.add(i);
        } else if (deltatype == 4) {
          expandBlossom(deltablossom, false);
        }
      }
      if (augmented == 0) {
        break;
      }
      for (int b = nVertex; b < 2 * nVertex; b++) {
        if (blossomParent[b] == -1 &&
            blossomBase[b] >= 0 &&
            label[b] == 1 &&
            dualVar[b] == 0) {
          expandBlossom(b, true);
        }
      }
    }
    if (checkOptimum) {
      verifyOptimum();
    }

    for (int v = 0; v < nVertex; v++) {
      if (mate[v] >= 0) {
        mate[v] = endPoint[mate[v]];
      }
    }

    return mate;
  }
}

class Postman {
  double _totalCost = 0;
  List<int> _tour = [];

  double cost() {
    return _totalCost;
  }

  List<int> tour(){
    return _tour;
  }

  List<List<int>> flippedWeights(List<List<int>> l) {
    int max = -maxInt;
    List<List<int>> temp = l;
    for (List<int> edge in l) {
      if (edge[2] > max) {
        max = edge[2];
      }
    }
    for (List<int> edge in temp) {
      edge[2] = -edge[2] + max + 1;
    }
    List<List<int>> temp2 = [];
    for (List<int> l in temp) {
      temp2.add(l);
    }
    return temp2;
  }

  List<int> eulerianCycle(List<List<int>> edges) {
    List<List<int>> copy = edges;
    List<List<int>> paths = [[]];

    int start = edges[0][0];
    paths[0].add(start);
    int pathsIndex = 0;
    while (copy.isNotEmpty) {
      int end = -1;
      List<int> newEdge = copy.firstWhere((element) => element.contains(start));
      if (start == newEdge[0]) {
        end = newEdge[1];
      } else {
        end = newEdge[0];
      }

      paths[pathsIndex].add(end);

      copy.removeAt(copy
          .indexOf(copy.firstWhere((element) => listEquals(element, newEdge))));

      if (paths[pathsIndex].first == end) {
        paths.add([]);
        for (List<int> e in edges) {
          if (paths[pathsIndex].contains(e[0])) {
            start = e[0];
          } else if (paths[pathsIndex].contains(e[1])) {
            start = e[1];
          }
        }
        pathsIndex++;
        paths[pathsIndex].add(start);
      } else {
        start = end;
      }
    }

    paths.removeLast();

    if (paths.length == 1) {
      return paths.first;
    }

    List<List<int>> pathsCopy = List.from(paths);
    for (int i = paths.length - 2; i >= 0; i--) {
      int replaceIndex = paths[i].indexOf(paths[i + 1].first);
      pathsCopy[i].removeAt(replaceIndex);
      for (int j = 0; j < pathsCopy[i + 1].length; j++) {
        pathsCopy[i].insert(replaceIndex + j, pathsCopy[i + 1][j]);
      }
    }

    return pathsCopy.first;
  }

  List<int> postmanTour(Map<int, Map<int, double>> graph,
      {int startingVertex = 0}) {
    _totalCost = 0;
    List<List<int>> edges = [];
    Map<int, int> verticesCount = {};
    List<int> oddVertices = [];

    if (graph.keys.isEmpty) {
      return [];
    }

    double maxWeight = -1;
    for (int i in graph.keys) {
      for (int j in graph[i]!.keys) {
        if (graph[i]![j]! > maxWeight) {
          maxWeight = graph[i]![j]!.toDouble();
        }
      }
    }

    //make sure each edge is listed twice for Dijkstra package
    Map<int, Map<int, double>> graphCopy = Map.from(graph);
    for (int v in graph.keys) {
      for (int v2 in graph[v]!.keys) {
        if (!graphCopy.containsKey(v2)) {
          graphCopy.addAll({
            v2: {v: graph[v]![v2]!.toDouble()}
          });
        } else {
          graphCopy[v2]![v] = graph[v]![v2]!;
        }
      }
    }

    if (!graphCopy.keys.contains(startingVertex)) {
      startingVertex = graphCopy.keys.first;
    }

    //get list of edges
    for (int v in graph.keys) {
      for (int v2 in graph[v]!.keys) {
        List<int> newEdge = [math.min(v, v2), math.max(v, v2)];
        bool hasNewEdge = false;
        for (List<int> e in edges) {
          if (listEquals(e, newEdge)) {
            hasNewEdge = true;
            break;
          }
        }
        if (!hasNewEdge) {
          edges.add(newEdge);
        }
      }
    }

    for (int v in graphCopy.keys) {
      if (graphCopy[v]!.keys.length % 2 == 1) {
        oddVertices.add(v);
      }
    }

    //multiply weights by 1000 if number are not large
    //to keep some precision for numbers with decimals
    Map<int, Map<int, int>> graphCopyWeighted = {};
    if (maxWeight < 100000) {
      for (int v in graphCopy.keys) {
        for (int v2 in graphCopy[v]!.keys) {
          if (!graphCopyWeighted.containsKey(v)) {
            graphCopyWeighted.addAll({
              v: {v2: (graphCopy[v]![v2]! * 1000).toInt()}
            });
          } else {
            graphCopyWeighted[v]![v2] = (graphCopy[v]![v2]! * 1000).toInt();
          }
        }
      }
    } else {
      for (int v in graphCopy.keys) {
        for (int v2 in graphCopy[v]!.keys) {
          if (!graphCopyWeighted.containsKey(v)) {
            graphCopyWeighted.addAll({
              v: {v2: (graphCopy[v]![v2]!).toInt()}
            });
          } else {
            graphCopyWeighted[v]![v2] = (graphCopy[v]![v2]!).toInt();
          }
        }
      }
    }

    List<List<int>> oddVerticesEdges = [];
    for (int i = 0; i < oddVertices.length - 1; i++) {
      for (int j = i + 1; j < oddVertices.length; j++) {
        List path = Dijkstra.findPathFromGraph(
            graphCopyWeighted, oddVertices[i], oddVertices[j]);
        int cost = 0;
        for (int p = 0; p < path.length - 1; p++) {
          cost += graphCopyWeighted[path[p]]![path[p + 1]]!.toInt();
        }
        oddVerticesEdges.add([oddVertices[i], oddVertices[j], cost]);
      }
    }

    Blossom b = Blossom(flippedWeights(oddVerticesEdges), true);
    List<int> matching = b.maxWeightMatching();

    List<int> matchingCopy = List.from(matching);
    List<List<int>> matchingPairs = [];
    for (int i = 0; i < matching.length; i++) {
      if (matching[i] == -1) {
        continue;
      } else {
        matchingPairs.add([i, matching[i]]);
        matchingCopy[i] = -1;
        matchingCopy[matching[i]] = -1;
      }
    }

    List<int> oddVerticesCopy = List.from(oddVertices);
    for (int o in oddVertices) {
      if (!oddVerticesCopy.contains(o)) {
        continue;
      } else {
        List path =
            Dijkstra.findPathFromGraph(graphCopyWeighted, o, matching[o]);
        for (int p = 0; p < path.length - 1; p++) {
          edges.add([path[p], path[p + 1]]);
        }
        oddVerticesCopy
          ..remove(o)
          ..remove(matching[o]);
      }
    }

    List<int> cycle = eulerianCycle(edges);
    for (int v = 0; v < cycle.length - 1; v++) {
      _totalCost += graphCopy[cycle[v]]![cycle[v + 1]]!;
    }

    List<int> cycleCopy = [];
    for (int c = 0; c <= cycle.length; c++) {
      if (cycle.indexOf(startingVertex) + c == cycle.length) {
        continue;
      }
      cycleCopy
          .add((cycle[(cycle.indexOf(startingVertex) + c) % cycle.length]));
    }

    _tour = cycleCopy;
    return cycleCopy;
  }
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
