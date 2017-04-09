// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/inline.dart';

void main() {
  final ctx = inlineExprContext;
  final equation = fn2('=');
  final a = generic('a'), b = generic('b'), c = generic('c');

  test('Derivation of centripetal acceleration (step 1)', () {
    final vec2d = symbol('vec2d');
    final theta = symbol('theta');
    final pvec = symbol('pvec');
    final ihat = symbol('ihat');
    final jhat = symbol('jhat');
    final px = symbol('px');
    final py = symbol('py');
    final x = symbol('x');
    final y = symbol('y');
    final r = symbol('r');
    final sin = fn1('sin');
    final cos = fn1('cos');

    // Derive equation for circular motion.
    final e = equation(pvec, vec2d)
        .substitute(rule(vec2d, x * ihat + y * jhat))
        .substitute(rule(x, px))
        .substitute(rule(y, py))
        .substitute(rule(px, r * sin(theta)))
        .substitute(rule(py, r * cos(theta)))
        .substitute(rule((a * b) * c, a * (b * c)))
        .substitute(rule((a * b) * c, a * (b * c)))
        .substitute(rule(a * b + a * c, a * (b + c)));

    expect(
        e, equals(equation(pvec, r * (sin(theta) * ihat + cos(theta) * jhat))));
  });

  test('Chain rule', () {
    final sin = fn1('sin');
    final cos = fn1('cos');
    final diff = fn2('diff');
    final fn = fn1('fn', generic: true);
    final x = symbol('x');

    /// Use chain rule to find derivative of sin(x^3)
    final e = equation(symbol('y'), diff(sin(x ^ 3), x))
        .substitute(rule(diff(fn(a), b), diff(a, b) * diff(fn(a), a)))
        .substitute(rule(diff(a ^ b, a), b * (a ^ (b - 1))))
        .substitute(rule(diff(sin(a), a), cos(a)))
        .evaluate(ctx.compute);

    expect(e, equals(equation(symbol('y'), number(3) * (x ^ 2) * cos(x ^ 3))));
  });

  test('Power operator', () {
    expect(
        equation(symbol('y'), symbol('x') ^ 3)
            .substitute(rule(symbol('x'), 3))
            .evaluate(ctx.compute),
        equals(equation(symbol('y'), 27)));
  });
}
