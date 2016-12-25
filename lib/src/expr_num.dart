// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Numeric expression
class ExprNum extends Expr {
  final num value;

  ExprNum(this.value) {
    assert(value != null); // Do not accept null as input.
  }

  @override
  ExprNum clone() => new ExprNum(value);

  @override
  bool equals(other) => other is ExprNum && other.value == value;

  @override
  int get expressionHash => hash2(0, value.hashCode);

  @override
  ExprMatchResult matchSuperset(superset) => equals(superset)
      ? new ExprMatchResult.exactMatch()
      : (superset is ExprSym && superset.isGeneric
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch());

  @override
  ExprNum remap(mapping) => clone();

  @override
  num _eval(canCompute, compute) => value;
}
