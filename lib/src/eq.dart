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
  factory Eq.parse(String str) {
    final sides = str.split('=');
    if (sides.length == 2) {
      return new Eq(new Expr.parse(sides[0]), new Expr.parse(sides[1]));
    } else {
      throw new FormatException(
          "the equation should be of the format 'Expr=Expr'");
    }
  }

  /// Substitute the given equation.
  void substitute(Eq eq, {List<int> gen: const [], int idx: 0}) {
    final index = new W<int>(idx);
    left = left.substitute(eq, gen, index);
    if (index.v != -1) {
      right = right.substitute(eq, gen, index);
    }
  }

  /// Wrap both sides of the equation using the given condition.
  void wrap(Expr condition, List<int> generic, Expr wrapping) {
    final lmap = left.matchSuperset(condition, generic);
    if (lmap != null) {
      _wrap(wrapping, lmap);
    } else {
      final rmap = right.matchSuperset(condition, generic);
      if (rmap != null) {
        _wrap(wrapping, rmap);
      } else {
        throw new Exception('the condition does not match left or right');
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
  void compute(
      [ExprCanCompute canCompute = defaultCanCompute,
      ExprCompute computer = defaultCompute]) {
    num lvalue = left.compute(canCompute, computer);
    if (lvalue != null) {
      left = new Expr.numeric(lvalue);
    }
    num rvalue = right.compute(canCompute, computer);
    if (rvalue != null) {
      right = new Expr.numeric(rvalue);
    }
  }

  /// Generate string representation.
  String toString() => '$left=$right';
}
