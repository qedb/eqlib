// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Equation of two expressions
class Eq {
  /// Left and right hand side.
  Expr l, r;

  Eq(this.l, this.r);

  /// Parse an equation string representation.
  factory Eq.parse(String str) {
    final sides = str.split('=');
    return new Eq(new Expr()..parseUnsafe(sides[0].replaceAll(' ', '')),
        new Expr()..parseUnsafe(sides[1].replaceAll(' ', '')));
  }

  /// Substitute the given equation.
  void sub(Eq eq, {List<String> gen: const [], int idx: 0}) {
    idx = l.sub(eq, gen, idx);
    if (idx != -1) {
      r.sub(eq, gen, idx);
    }
  }

  /// Wrap both sides of the equation using the given condition.
  void wrap(Expr condition, List<String> generic, Expr wrapping) {
    final lmap = l.matchSuperset(condition, generic);
    if (lmap != null) {
      lmap['%'] = l;
      l = wrapping.remap(lmap);
      lmap['%'] = r;
      r = wrapping.remap(lmap);
    }
  }

  /// Compute both sides of the equation as far as possible using the given
  /// resolver.
  void compute(ExprResolver resolver) {
    num lvalue = l.compute(resolver);
    if (lvalue != null) {
      l = new Expr.from(lvalue.toString(), []);
    }
    num rvalue = r.compute(resolver);
    if (rvalue != null) {
      r = new Expr.from(rvalue.toString(), []);
    }
  }

  /// Generate string representation.
  String toString() => '$l=$r';
}
