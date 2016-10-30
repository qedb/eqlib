// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';

void main() {
  test('Derivation of centripetal acceleration (step 1)', () {
    var pvec = new Eq.parse('pvec = vec2d');
    pvec.sub(new Eq.parse('vec2d = add(mult(x, ihat), mult(y, jhat))'));
    pvec.sub(new Eq.parse('x = px'));
    pvec.sub(new Eq.parse('y = py'));
    pvec.sub(new Eq.parse('px = mult(r, sin(th))'));
    pvec.sub(new Eq.parse('py = mult(r, cos(th))'));
    pvec.sub(new Eq.parse('mult(mult(a, b), c) = mult(a, mult(b, c))'),
        gen: ['a', 'b', 'c']);
    pvec.sub(new Eq.parse('mult(mult(a, b), c) = mult(a, mult(b, c))'),
        gen: ['a', 'b', 'c']);
    pvec.sub(new Eq.parse('add(mult(a, b), mult(a, c)) = mult(a, add(b, c))'),
        gen: ['a', 'b', 'c']);

    // Check
    expect(pvec.toString(),
        equals('pvec=mult(r,add(mult(sin(th),ihat),mult(cos(th),jhat)))'));
  });

  test('Solve a simple equation', () {
    var resolver = new ExprResolver();
    resolver.addResolver('add', (args) => args[0] + args[1]);
    resolver.addResolver('sub', (args) => args[0] - args[1]);
    resolver.addResolver('mult', (args) => args[0] * args[1]);
    resolver.addResolver('div', (args) => args[0] / args[1]);

    var eq = new Eq.parse('add(mult(x, 2), 5) = 9');
    eq.wrap(
        new Expr.parse('add(a, b)'), ['a', 'b'], new Expr.parse('sub(%, b)'));
    eq.sub(new Eq.parse('sub(add(a, b), b) = a'), gen: ['a', 'b']);
    eq.wrap(
        new Expr.parse('mult(a, b)'), ['a', 'b'], new Expr.parse('div(%, b)'));
    eq.sub(new Eq.parse('div(mult(a, b), b) = a'), gen: ['a', 'b']);
    eq.compute(resolver);

    // Check
    expect(eq.toString(), equals('x=2.0'));
  });
}
