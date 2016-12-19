// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

class TreeDiff {
  final Eq rule;
  final List<TreeDiff> alt;
  TreeDiff(this.rule, [this.alt = const []]);
  String toString() =>
      alt.isEmpty ? rule.toString() : '($rule OR ${alt.join(" AND ")})';
}

class TreeDiffResult {
  /// Difference rules
  final TreeDiff diff;

  /// The result has a difference.
  final bool hasDiff;

  /// Two numbers are not equal
  final bool numsNotEqual;

  TreeDiffResult(
      {this.hasDiff: true, this.numsNotEqual: false, this.diff: null});

  String toString() => diff != null
      ? diff.toString()
      : '{hasDiff: $hasDiff, numsNotEqual: $numsNotEqual}';
}

/// Implementation of the full Tree-Diff algorithm for expression trees.
TreeDiffResult computeTreeDiff(Expr a, Expr b) {
  // If a == b, this branch can be terminated.
  if (a == b) {
    return new TreeDiffResult(hasDiff: false);
  }

  // If a and b are numeric, this branch can be discarded.
  else if (a is ExprNum && b is ExprNum) {
    // If a and b were equal, they would pass the first if statement, therefore
    // it can be concluded that this difference is invalid.
    return new TreeDiffResult(numsNotEqual: true);
  }

  // Potential rule: a = b
  final rule = new Eq(a, b);

  // If a and b are equal functions, their arguments can be compared.
  if (a is ExprFun &&
      b is ExprFun &&
      a.id == b.id &&
      a.args.length == b.args.length) {
    // Create alternate rules for each argument.
    final alt = new List<TreeDiff>();

    for (var i = 0; i < a.args.length; i++) {
      final result = computeTreeDiff(a.args[i], b.args[i]);
      if (result.numsNotEqual) {
        // The alternative is illegal: discard.
        return new TreeDiffResult(diff: new TreeDiff(rule));
      } else if (result.hasDiff) {
        // Include the resulting rules in the alt rules.
        alt.add(result.diff);
      }
    }

    return new TreeDiffResult(diff: new TreeDiff(rule, alt));
  } else {
    return new TreeDiffResult(diff: new TreeDiff(rule));
  }
}
