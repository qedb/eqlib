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

  ExprNum clone() => new ExprNum(value);

  bool equals(other) => other is ExprNum && other.value == value;
  int get expressionHash => hash2(0, value.hashCode);

  ExprMatchResult matchSuperset(superset) => equals(superset)
      ? new ExprMatchResult.exactMatch()
      : (superset is ExprSym && superset.isGeneric
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch());

  ExprNum remap(mapping) => clone();

  num eval(canCompute, compute) => value;
}
