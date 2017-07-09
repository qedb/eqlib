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
  int get expressionHash => jPostprocess(jMix(1041, value.hashCode));

  @override
  bool get isGeneric => false;

  @override
  List<Expr> flatten() => [this];

  @override
  void getFunctionIds(target) {}

  @override
  bool _compare(pattern, mapping) {
    if (equals(pattern)) {
      return true;
    } else if (pattern is FunctionExpr && pattern.isGeneric) {
      return mapping.addExpression(pattern.id, this);
    } else {
      return false;
    }
  }

  @override
  NumberExpr remap(mapping) => clone();

  @override
  Expr _substituteAt(substitution, position) {
    if (position.v-- == 0) {
      if (compare(substitution.left)) {
        return substitution.right.clone();
      } else {
        throw const EqLibException(
            'substitution does not match at the given position');
      }
    } else {
      return clone();
    }
  }

  @override
  Expr _rearrangeAt(rearrangeFormat, position, rearrangeableIds) {
    if (position.v-- == 0) {
      throw const EqLibException(
          'given position is not a rearrangeable function');
    }
    return clone();
  }

  @override
  NumberExpr evaluate(compute) => clone();
}
