// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

class Subs {
  final Expr left, right;
  Subs(this.left, this.right);

  @override
  bool operator ==(other) =>
      other is Subs && other.left == left && other.right == right;

  @override
  int get hashCode => hashCode2(left, right);

  /// Get inverted substitution (not a deep copy).
  Subs get inverted => new Subs(right, left);

  /// Shorthand for [compareSubstitutions].
  bool compare(Subs pattern, ExprCompute compute, [ExprMapping mapping]) =>
      compareSubstitutions(this, pattern, compute, mapping);
}

bool compareSubstitutions(Subs subs, Subs pattern, ExprCompute compute,
    [ExprMapping mapping]) {
  final theMapping = mapping ?? new ExprMapping();
  if (subs.left._compare(pattern.left, theMapping)) {
    final rightEvaluated = pattern.right.remap(theMapping).evaluate(compute);
    return subs.right._compare(rightEvaluated, theMapping);
  } else {
    return false;
  }
}
