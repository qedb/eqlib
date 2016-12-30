// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Numeric expression
class NumberExpr extends Expr {
  final num value;

  NumberExpr(this.value) {
    assert(value != null); // Do not accept null as input.
  }

  @override
  NumberExpr clone() => new NumberExpr(value);

  @override
  bool equals(other) => other is NumberExpr && other.value == value;

  @override
  int get expressionHash => hash2(0, value.hashCode);

  @override
  ExprMatchResult matchSuperset(superset) => equals(superset)
      ? new ExprMatchResult.exactMatch()
      : (superset is SymbolExpr && superset.isGeneric
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch());

  @override
  NumberExpr remap(mapping) => clone();

  @override
  num evalInternal(canCompute, compute) => value;
}
