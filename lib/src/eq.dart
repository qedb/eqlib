// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Equation of two expressions
class Eq {
  /// Left and right hand side.
  Expr left, right;

  Eq(this.left, this.right);

  /// Parse an equation string representation.
  factory Eq.parse(String str, [ExprResolve resolver = eqlibSAResolve]) {
    final sides = str.split('=');
    return new Eq(new Expr.parse(sides.first, resolver),
        new Expr.parse(sides.last, resolver));
  }

  /// Create deep copy.
  Eq clone() => new Eq(left.clone(), right.clone());

  /// Substitute the given equation.
  bool subs(Eq eq, [int idx = 0]) {
    final index = new W<int>(idx);
    left = left.subsInternal(eq, index);
    if (index.v != -1) {
      right = right.subsInternal(eq, index);
      return index.v == -1;
    } else {
      return true;
    }
  }

  /// Wrap both sides of the equation using the given condition.
  void wrap(Expr condition, Expr wrapping) {
    final lmap = left.matchSuperset(condition);
    if (lmap.match) {
      _wrap(wrapping, lmap.mapping);
    } else {
      final rmap = right.matchSuperset(condition);
      if (rmap.match) {
        _wrap(wrapping, rmap.mapping);
      } else {
        throw new EqLibException('the condition does not match left or right');
      }
    }
  }

  /// Wrap both sides of the equation using the provided [wrapping] expression
  /// and expression [mapping].
  void _wrap(Expr wrapping, Map<int, Expr> mapping) {
    mapping[0] = left;
    left = wrapping.remap(mapping);
    mapping[0] = right;
    right = wrapping.remap(mapping);
  }

  /// Compute both sides of the equation as far as possible using the given
  /// resolver.
  void eval(
      [ExprCanCompute canCompute = eqlibSACanCompute,
      ExprCompute computer = eqlibSACompute]) {
    final lvalue = left.eval(canCompute, computer);
    if (lvalue != null) {
      left = new NumberExpr(lvalue);
    }
    final rvalue = right.eval(canCompute, computer);
    if (rvalue != null) {
      right = new NumberExpr(rvalue);
    }
  }

  /// Compare two equations.
  @override
  bool operator ==(dynamic other) {
    if (other is Eq) {
      return left == other.left && right == other.right;
    } else {
      return false;
    }
  }

  /// Equation hashcode.
  @override
  int get hashCode =>
      jFinish(jCombine(jCombine(0, left.hashCode), right.hashCode));

  /// Generate string representation.
  @override
  String toString() => '$left=$right';
}
