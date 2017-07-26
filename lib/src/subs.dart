// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

class Subs {
  final Expr left, right;
  Subs(this.left, this.right);

  /// Get copy.
  Subs clone({bool invert: false, bool deepCopy: false}) {
    final l = deepCopy ? left.clone() : left;
    final r = deepCopy ? right.clone() : right;
    return invert ? new Subs(r, l) : new Subs(l, r);
  }

  /// Get inverted substitution (not a deep copy).
  Subs get inverted => new Subs(right, left);

  /// Remap both sides.
  Subs remap(ExprMapping mapping) =>
      new Subs(left.remap(mapping), right.remap(mapping));

  /// Shorthand for [compareSubstitutions].
  bool compare(Subs pattern, ExprCompute compute, [ExprMapping mapping]) {
    return compareSubstitutions(this, pattern, compute, mapping);
  }

  @override
  bool operator ==(other) =>
      other is Subs && other.left == left && other.right == right;

  @override
  int get hashCode => hashCode2(left, right);
}

bool compareSubstitutions(Subs subs, Subs pattern, ExprCompute compute,
    [ExprMapping mapping]) {
  final theMapping = mapping ?? new ExprMapping();
  if (subs.left._compare(pattern.left, theMapping, compute)) {
    return subs.right._compare(pattern.right, theMapping, compute);
  } else {
    return false;
  }
}
