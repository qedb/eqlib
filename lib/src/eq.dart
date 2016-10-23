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
    return new Eq(new Expr()..parse(sides[0].replaceAll(' ', '')),
        new Expr()..parse(sides[1].replaceAll(' ', '')));
  }

  /// Substitute the given equation.
  void sub(Eq eq, {List<String> gen: const [], int idx: 0}) {
    idx = l.sub(eq, gen, idx);
    if (idx != -1) {
      r.sub(eq, gen, idx);
    }
  }

  /// Generate string representation.
  String toString() => '$l=$r';
}
