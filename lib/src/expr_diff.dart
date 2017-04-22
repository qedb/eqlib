// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Difference between two expressions.
class ExprDiffBranch {
  /// Branch position in the expression (can be used with [Expr.substituteAt]
  /// and [Expr.rearrangeAt]).
  final int position;

  /// Expressions being compared.
  final Expr left, right;

  /// Rearrangement of children
  ///
  /// When rearrangement is not possible, this list should be empty.
  /// Multiple rearrangements can be specified if different nested functions are
  /// rearranged simultaneously.
  final List<Rearrangement> rearrangements;

  /// Difference between each argument (if a and b are similar functions).
  final List<ExprDiffBranch> argumentDifference;

  ExprDiffBranch(this.position, this.left, this.right,
      {this.rearrangements: const [],
      Iterable<ExprDiffBranch> argumentDifference})
      : argumentDifference = argumentDifference == null
            ? new List<ExprDiffBranch>()
            : new List<ExprDiffBranch>.from(argumentDifference);

  @override
  bool operator ==(dynamic other) =>
      other is ExprDiffBranch &&
      other.position == position &&
      other.left == left &&
      other.right == right &&
      const ListEquality().equals(other.rearrangements, rearrangements) &&
      const ListEquality().equals(other.argumentDifference, argumentDifference);

  @override
  int get hashCode => hashCode3(hashCode3(position, left, right),
      hashObjects(rearrangements), hashObjects(argumentDifference));

  bool get isDifferent => left != right;
}

class ExprDiffResult {
  /// Difference rules
  final ExprDiffBranch branch;

  /// The two expressions are both numbers and not equal.
  final bool numericInequality;

  ExprDiffResult({this.numericInequality: false, this.branch: null});

  @override
  bool operator ==(dynamic other) =>
      other is ExprDiffResult &&
      other.numericInequality == numericInequality &&
      other.branch == branch;

  @override
  int get hashCode => hashCode2(branch, numericInequality);
}

/// Generate [ExprDiffResult] for the difference between expression [a] and [b].
/// You must specify a set of [rearrangeableIds] (usually addition and
/// multiplication).
ExprDiffResult getExpressionDiff(Expr a, Expr b, List<int> rearrangeableIds,
    [int _position = -1]) {
  var position = _position + 1;

  // If there is no difference, this branch can be terminated.
  if (a == b) {
    return new ExprDiffResult(branch: new ExprDiffBranch(position, a, b));
  }

  // If a and b are numeric, this branch can be discarded.
  else if (a is NumberExpr && b is NumberExpr) {
    // If a and b were equal, they would pass the first if statement, therefore
    // it can be concluded that this difference is invalid.
    return new ExprDiffResult(numericInequality: true);
  }

  // Basic return object.
  final result = new ExprDiffResult(
      branch: new ExprDiffBranch(position, a, b,
          rearrangements:
              _computeRearrangement(position, a, b, rearrangeableIds)));

  // If a rearrangement resolves this branch, there is no need to compare
  // individual arguments.
  if (result.branch.rearrangements.isNotEmpty) {
    return result;
  }

  // If a and b are equal functions, their arguments can be compared.
  else if (a is FunctionExpr &&
      b is FunctionExpr &&
      !a.isSymbol &&
      a.id == b.id &&
      a.arguments.length == b.arguments.length) {
    // Add branches for each argument.
    for (var i = 0; i < a.arguments.length; i++) {
      final argResult = getExpressionDiff(
          a.arguments[i], b.arguments[i], rearrangeableIds, position);

      if (argResult.numericInequality) {
        // The branch is illegal: discard argument rules.
        // Note that the difference can never be fully resolved if one of the
        // arguments has a numeric inequality. The rule must involve the parent
        // functions.
        result.branch.argumentDifference.clear();
        return result;
      } else {
        position += a.arguments[i].flatten().length;
        result.branch.argumentDifference.add(argResult.branch);
      }
    }

    return result;
  } else {
    return result;
  }
}

/// Check if expression [a] can be rearranged into expression [b]. If so, a list
/// of rearrangement steps is returned.
List<Rearrangement> _computeRearrangement(
    int position, Expr a, Expr b, List<int> rearrangeableIds) {
  if (a is FunctionExpr &&
      b is FunctionExpr &&
      rearrangeableIds.contains(a.id) &&
      a.id == b.id) {
    // If only one argument is actually different, return the rearrangement of
    // this argument.
    final different = new List<Tuple2<int, int>>();
    var distanceSum = 1;
    for (var i = 0; i < a.arguments.length; i++) {
      if (a.arguments[i] != b.arguments[i]) {
        different.add(new Tuple2<int, int>(i, distanceSum));
      }
      distanceSum += a.arguments[i].size;
    }
    if (different.length == 1) {
      final argi = different[0].item1;
      final distance = different[0].item2;
      return _computeRearrangement(position + distance, a.arguments[argi],
          b.arguments[argi], rearrangeableIds);
    }

    final result = new List<Rearrangement>();

    // Build child map.
    final map = new Map<int, List<int>>();
    final aChildren = a.getChildren();
    for (var i = 0; i < aChildren.length; i++) {
      final hash =
          _computeRearrangeableHash(aChildren[i].expr, rearrangeableIds);
      map.putIfAbsent(hash, () => new List<int>());
      map[hash].add(i);
    }

    // Iterate over children in b and construct a rearrangement format.
    final bChildren = b.getChildren(true);
    final format = new List<int>();
    for (final bChild in bChildren) {
      if (bChild == null) {
        format.add(-1);
      } else {
        final hash = _computeRearrangeableHash(bChild.expr, rearrangeableIds);
        if (map.containsKey(hash) && map[hash].isNotEmpty) {
          format.add(map[hash].removeAt(0));

          // Check if expressions are different. If this is the case, then a
          // rearrangement cycle must be inserted before the current one.
          final aChild = aChildren[format.last];
          if (aChild.expr != bChild.expr) {
            final preArrangement = _computeRearrangement(
                position + aChild.distance,
                aChild.expr,
                bChild.expr,
                rearrangeableIds);
            result.addAll(preArrangement);
          }
        } else {
          // Mismatch: expression a cannot be rearranged into expression b.
          return [];
        }
      }
    }

    result.add(new Rearrangement.at(position, format));
    return result;
  } else {
    return [];
  }
}

/// Computes expression hash. Except this hash is equal when the expression can
/// be rearranged.
int _computeRearrangeableHash(Expr expr, List<int> rearrangeableIds) {
  if (expr is FunctionExpr && rearrangeableIds.contains(expr.id)) {
    final children = expr
        .getChildren()
        .map((child) => _computeRearrangeableHash(child.expr, rearrangeableIds))
        .toList();
    children.sort();
    return jPostprocess(
        jMix(children.fold(0, (hash, arg) => jMix(hash, arg)), expr.id));
  } else {
    return expr.hashCode;
  }
}

class Rearrangement {
  int position;
  List<int> format;

  /// This allows re-use with the rpc package.
  Rearrangement();

  Rearrangement.at(this.position, this.format);

  @override
  bool operator ==(dynamic other) =>
      other is Rearrangement &&
      other.position == position &&
      const ListEquality().equals(other.format, format);

  @override
  int get hashCode => hashCode2(position, hashObjects(format));
}
