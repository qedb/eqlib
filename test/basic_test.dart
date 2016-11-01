// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/compute.dart';

void main() {
  final symbolA = defaultResolver('a');
  final symbolB = defaultResolver('b');
  final symbolC = defaultResolver('c');

  test('Derivation of centripetal acceleration (step 1)', () {
    var pvec = new Eq.parse('pvec = vec2d');
    pvec.substitute(new Eq.parse('vec2d = add(mul(x, ihat), mul(y, jhat))'));
    pvec.substitute(new Eq.parse('x = px'));
    pvec.substitute(new Eq.parse('y = py'));
    pvec.substitute(new Eq.parse('px = mul(r, sin(th))'));
    pvec.substitute(new Eq.parse('py = mul(r, cos(th))'));
    pvec.substitute(new Eq.parse('mul(mul(a, b), c) = mul(a, mul(b, c))'),
        gen: [symbolA, symbolB, symbolC]);
    pvec.substitute(new Eq.parse('mul(mul(a, b), c) = mul(a, mul(b, c))'),
        gen: [symbolA, symbolB, symbolC]);
    pvec.substitute(
        new Eq.parse('add(mul(a, b), mul(a, c)) = mul(a, add(b, c))'),
        gen: [symbolA, symbolB, symbolC]);

    // Check
    expect(pvec.toString(),
        equals('pvec={r}*{{sin(th)}*{ihat} + {cos(th)}*{jhat}}'));
  });

  test('Solve a simple equation', () {
    var eq = new Eq.parse('add(mul(x, 2), 5) = 9');
    eq.wrap(new Expr.parse('add(a, b)'), [symbolA, symbolB],
        new Expr.parse('sub(%, b)'));
    eq.substitute(new Eq.parse('sub(add(a, b), b) = a'),
        gen: [symbolA, symbolB]);
    eq.wrap(new Expr.parse('mul(a, b)'), [symbolA, symbolB],
        new Expr.parse('div(%, b)'));
    eq.substitute(new Eq.parse('div(mul(a, b), b) = a'),
        gen: [symbolA, symbolB]);
    eq.compute();

    // Check
    expect(eq.toString(), equals('x=2.0'));
  });
}
