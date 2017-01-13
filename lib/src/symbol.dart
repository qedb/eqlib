// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Symbolic expression
class SymbolExpr extends Expr {
  final int id;
  final bool generic;

  SymbolExpr(this.id, [this.generic = false]) {
    assert(id != null); // Do not accept null as input.
  }

  @override
  SymbolExpr clone() => new SymbolExpr(id, generic);

  @override
  bool equals(other) => other is SymbolExpr && other.id == id;

  @override
  int get expressionHash => jFinish(jCombine(0, id));

  @override
  bool get isGeneric => generic;

  @override
  ExprMatchResult matchSuperset(superset) => equals(superset)
      ? new ExprMatchResult.exactMatch()
      : (superset is SymbolExpr && superset.isGeneric
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch());

  @override
  Expr remap(mapping) =>
      mapping.containsKey(id) ? mapping[id].clone() : clone();

  @override
  num evalInternal(canCompute, compute) =>
      double.NAN; // Symbols cannot be evaluated.
}
