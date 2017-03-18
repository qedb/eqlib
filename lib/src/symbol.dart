// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Symbolic expression
class SymbolExpr extends FunctionSymbolExpr {
  SymbolExpr(int id, bool generic) : super(id, generic) {
    assert(id != null); // Do not accept null as input.
  }

  @override
  SymbolExpr clone() => new SymbolExpr(id, _generic);

  @override
  bool equals(other) => other is SymbolExpr && other.id == id;

  @override
  int get expressionHash => jFinish(jCombine(0, id));

  @override
  ExprMatchResult matchSuperset(superset) => equals(superset)
      ? new ExprMatchResult.exactMatch()
      : (superset is FunctionSymbolExpr && superset.isGeneric
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch());

  @override
  Expr remap(mapping, genericFunctions) =>
      mapping.containsKey(id) ? mapping[id].clone() : clone();

  @override
  num evaluate(compute) => double.NAN; // Symbols cannot be evaluated.
}
