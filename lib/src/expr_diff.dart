// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Difference between two expressions.
class ExprDiffBranch {
  /// Are a and be different?
  final bool different;

  /// Is a rearranged into b?
  final bool rearranged;

  /// Is a replaced by b?
  final Rule replaced;

  /// Difference between each argument (if a and b are similar functions).
  final List<ExprDiffBranch> argumentDifference;

  ExprDiffBranch(this.different,
      {this.replaced,
      this.rearranged: false,
      Iterable<ExprDiffBranch> argumentDifference})
      : argumentDifference = argumentDifference == null
            ? new List<ExprDiffBranch>()
            : new List<ExprDiffBranch>.from(argumentDifference);

  @override
  bool operator ==(dynamic other) =>
      other is ExprDiffBranch &&
      other.different == different &&
      other.rearranged == rearranged &&
      other.replaced == replaced &&
      const ListEquality().equals(other.argumentDifference, argumentDifference);

  @override
  int get hashCode => hashCode2(replaced, hashObjects(argumentDifference));
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

/// Get unique hash of deep arrangable child expressions.
int _hashArrangableFingerprint(Expr expr, List<int> arrangeableFunctions,
    [int parentFunction = -1]) {
  if (expr is FunctionExpr) {
    if (arrangeableFunctions.contains(expr.id)) {
      final deep = new List<Expr>();
      _getDeepChildren(expr, deep, expr.id);

      /// Convert to sorted list of fingerprints.
      final deepFingerprints = deep
          .map((child) =>
              _hashArrangableFingerprint(child, arrangeableFunctions))
          .toList();
      deepFingerprints.sort();

      return hashObjects(deepFingerprints);
    }
  }

  return expr.hashCode;
}

/// Get all deep children that are not functions with the same ID.
/// Helper for [_hashArrangableFingerprint].
void _getDeepChildren(Expr src, List<Expr> dst, int parentFunction) {
  if (src is FunctionExpr && src.id == parentFunction) {
    src.arguments.forEach((arg) => _getDeepChildren(arg, dst, parentFunction));
  } else {
    dst.add(src);
  }
}

/// Generate [ExprDiffResult] for the difference between expression [a] and [b].
/// You must specify a set of [arrangeableFunctions] (usually addition and
/// multiplication).
ExprDiffResult getExpressionDiff(
    Expr a, Expr b, List<int> arrangeableFunctions) {
  // If a == b, this branch can be terminated.
  if (a == b) {
    return new ExprDiffResult(branch: new ExprDiffBranch(false));
  }

  // If a and b are numeric, this branch can be discarded.
  else if (a is NumberExpr && b is NumberExpr) {
    // If a and b were equal, they would pass the first if statement, therefore
    // it can be concluded that this difference is invalid.
    return new ExprDiffResult(numericInequality: true);
  }

  // Potential rule: a = b
  final result = new ExprDiffResult(
      branch: new ExprDiffBranch(true,
          rearranged: _hashArrangableFingerprint(a, arrangeableFunctions) ==
              _hashArrangableFingerprint(b, arrangeableFunctions),
          replaced: new Rule(a, b)));

  // If a and b are equal functions, their arguments can be compared.
  if (a is FunctionExpr &&
      b is FunctionExpr &&
      !a.isSymbol &&
      a.id == b.id &&
      a.arguments.length == b.arguments.length) {
    // Add branches for each argument.
    for (var i = 0; i < a.arguments.length; i++) {
      final argResult = getExpressionDiff(
          a.arguments[i], b.arguments[i], arrangeableFunctions);

      if (argResult.numericInequality) {
        // The branch is illegal: discard argument rules.
        // Note that the difference can never be fully resolved if one of the
        // arguments has a numeric inequality. The rule must involve the parent
        // functions.
        result.branch.argumentDifference.clear();
        return result;
      } else {
        result.branch.argumentDifference.add(argResult.branch);
      }
    }

    return result;
  } else {
    return result;
  }
}
