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

  // First mix 0 with 1 to prevent collisions with symbols and functions.
  // jCombine(0, 1) = 1041
  @override
  int get expressionHash => jFinish(jCombine(1041, value.hashCode));

  @override
  ExprMatchResult matchSuperset(superset) => equals(superset)
      ? new ExprMatchResult.exactMatch()
      : (superset is FunctionSymbolExpr && superset.isGeneric
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch());

  @override
  NumberExpr remap(mapping, genericFunctions) => clone();

  @override
  num evaluate(compute) => value;
}
