// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/default.dart';
import 'package:eqlib/inline.dart';
import 'package:math_expressions/math_expressions.dart' as mexpr;

void main() {
  final a = defaultResolver('a');
  final b = defaultResolver('b');
  final c = defaultResolver('c');

  test('Parse using math_expressions package', () {
    var e = new Expr.fromMathExpressions(new mexpr.Parser().parse('2 * x + 5'));
    expect(e, equals(add(mul(2, symbol('x')), 5)));
  });

  test('Parse using EqExParser', () {
    var result = new EqExParser().parse('3 * fn(a, b, 3 - 2 * 5) ^ (10 + -5)');
    expect(
        result.value,
        equals(new Expr.parse(
            'mul(3, pow(fn(a, b, sub(3, mul(2, 5))), add(10, -5)))')));
  });

  test('Derivation of centripetal acceleration (step 1)', () {
    var pvec = new Eq.parse('pvec = vec2d');
    pvec.subs(new Eq.parse('vec2d = add(mul(x, ihat), mul(y, jhat))'));
    pvec.subs(new Eq.parse('x = px'));
    pvec.subs(new Eq.parse('y = py'));
    pvec.subs(new Eq.parse('px = mul(r, sin(theta))'));
    pvec.subs(new Eq.parse('py = mul(r, cos(theta))'));
    pvec.subs(new Eq.parse('mul(mul(a, b), c) = mul(a, mul(b, c))'), [a, b, c]);
    pvec.subs(new Eq.parse('mul(mul(a, b), c) = mul(a, mul(b, c))'), [a, b, c]);
    pvec.subs(new Eq.parse('add(mul(a, b), mul(a, c)) = mul(a, add(b, c))'),
        [a, b, c]);

    // Check
    defaultPrinterOpChars = true;
    expect(pvec.toString(),
        equals('pvec={r}*{{sin(theta)}*{ihat} + {cos(theta)}*{jhat}}'));
  });

  test('Solve a simple equation', () {
    var eq = new Eq.parse('add(mul(x, 2), 5) = 9');
    eq.wrap(new Expr.parse('add(a, b)'), [a, b], new Expr.parse('sub(@, b)'));
    eq.subs(new Eq.parse('sub(add(a, b), b) = a'), [a, b]);
    eq.wrap(new Expr.parse('mul(a, b)'), [a, b], new Expr.parse('div(@, b)'));
    eq.subs(new Eq.parse('div(mul(a, b), b) = a'), [a, b]);
    eq.eval();

    // Check
    expect(eq.toString(), equals('x=2.0'));
  });
}
