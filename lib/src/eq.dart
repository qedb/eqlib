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
  factory Eq.parse(String str, [ExprAssignId assignId]) {
    final sides = str.split('=');
    return new Eq(new Expr.parse(sides.first, assignId),
        new Expr.parse(sides.last, assignId));
  }

  /// Create deep copy.
  Eq clone() => new Eq(left.clone(), right.clone());

  /// Substitute the given equation.
  bool substitute(Eq eq, [int idx = 0]) {
    final index = new W<int>(idx);
    left = left.substituteInternal(eq, index);
    if (index.v != -1) {
      right = right.substituteInternal(eq, index);
      return index.v == -1;
    } else {
      return true;
    }
  }

  /// Wrap both sides of the equation using the given [template].
  void envelop(Expr template, Expr envelope) {
    final lmap = left.matchSuperset(template);
    if (lmap.match) {
      _envelop(envelope, lmap.mapping);
    } else {
      final rmap = right.matchSuperset(template);
      if (rmap.match) {
        _envelop(envelope, rmap.mapping);
      } else {
        throw new EqLibException('the template does not match left or right');
      }
    }
  }

  /// Wrap both sides of the equation using the provided [envelope] expression
  /// and expression [mapping].
  void _envelop(Expr envelope, Map<int, Expr> mapping) {
    mapping[0] = left;
    left = envelope.remap(mapping, {});
    mapping[0] = right;
    right = envelope.remap(mapping, {});
  }

  /// Compute both sides of the equation as far as possible using the given
  /// resolver.
  void evaluate([ExprCompute compute]) {
    final lvalue = left.evaluate(compute);
    if (!lvalue.isNaN) {
      left = new NumberExpr(lvalue);
    }
    final rvalue = right.evaluate(compute);
    if (!rvalue.isNaN) {
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
