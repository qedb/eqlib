// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Symbolic expression
class ExprSym extends Expr {
  final int id;
  final bool generic;

  ExprSym(this.id, [this.generic = false]) {
    assert(id != null); // Do not accept null as input.
  }

  @override
  ExprSym clone() => new ExprSym(id, generic);

  @override
  bool equals(other) => other is ExprSym && other.id == id;

  @override
  int get expressionHash => hash2(1, id);

  @override
  bool get isGeneric => generic;

  @override
  ExprMatchResult matchSuperset(superset) => equals(superset)
      ? new ExprMatchResult.exactMatch()
      : (superset is ExprSym && superset.isGeneric
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch());

  @override
  Expr remap(mapping) =>
      mapping.containsKey(id) ? mapping[id].clone() : clone();

  @override
  num _eval(canCompute, compute) => null; // Symbols cannot be evaluated.
}
