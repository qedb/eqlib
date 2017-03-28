// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

class ExprDiffBranch {
  final bool different;
  final Eq diff;
  final List<ExprDiffBranch> arguments;

  ExprDiffBranch(this.different, this.diff, [this.arguments = const []]);

  @override
  bool operator ==(dynamic other) =>
      other is ExprDiffBranch &&
      other.diff == diff &&
      const ListEquality().equals(other.arguments, arguments);

  @override
  int get hashCode => hashCode2(diff, hashObjects(arguments));
}

class ExprDiffResult {
  /// Difference rules
  final ExprDiffBranch diff;

  /// The two expressions are both numbers and not equal.
  final bool numericInequality;

  ExprDiffResult({this.numericInequality: false, this.diff: null});

  @override
  bool operator ==(dynamic other) =>
      other is ExprDiffResult &&
      other.numericInequality == numericInequality &&
      other.diff == diff;

  @override
  int get hashCode => hashCode2(diff, numericInequality);
}

/// Generate [ExprDiffResult] from the difference between expression [a] and [b].
ExprDiffResult getExpressionDiff(Expr a, Expr b) {
  // If a == b, this branch can be terminated.
  if (a == b) {
    return new ExprDiffResult(diff: new ExprDiffBranch(false, null));
  }

  // If a and b are numeric, this branch can be discarded.
  else if (a is NumberExpr && b is NumberExpr) {
    // If a and b were equal, they would pass the first if statement, therefore
    // it can be concluded that this difference is invalid.
    return new ExprDiffResult(numericInequality: true);
  }

  // Potential rule: a = b
  final rule = new Eq(a, b);

  // If a and b are equal functions, their arguments can be compared.
  if (a is FunctionExpr &&
      b is FunctionExpr &&
      a.id == b.id &&
      a.args.length == b.args.length) {
    // Create alternate branches for each argument.
    final arguments = new List<ExprDiffBranch>();

    for (var i = 0; i < a.args.length; i++) {
      final result = getExpressionDiff(a.args[i], b.args[i]);
      if (result.numericInequality) {
        // The branch is illegal: discard argument rules.
        // Note that the difference can never be fully resolved if one of the
        // arguments has a numeric inequality. The rule must involve the parent
        // functions.
        return new ExprDiffResult(diff: new ExprDiffBranch(true, rule));
      } else {
        arguments.add(result.diff);
      }
    }

    return new ExprDiffResult(diff: new ExprDiffBranch(true, rule, arguments));
  } else {
    return new ExprDiffResult(diff: new ExprDiffBranch(true, rule));
  }
}
