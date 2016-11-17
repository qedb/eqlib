// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/inline.dart';

void main() {
  final a = symbol('a');
  final b = symbol('b');
  final c = symbol('c');

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
    final e = eq(pvec, vec2d);
    e.subs(eq(vec2d, x * ihat + y * jhat));
    e.subs(eq(x, px));
    e.subs(eq(y, py));
    e.subs(eq(px, r * sin(theta)));
    e.subs(eq(py, r * cos(theta)));
    e.subs(eq((a * b) * c, a * (b * c)), exprIds([a, b, c]));
    e.subs(eq((a * b) * c, a * (b * c)), exprIds([a, b, c]));
    e.subs(eq(a * b + a * c, a * (b + c)), exprIds([a, b, c]));

    // Check
    expect(e, equals(eq(pvec, r * (sin(theta) * ihat + cos(theta) * jhat))));
  });

  test('Solve a simple equation', () {
    final x = symbol('x');
    final e = eq(x * 2 + 5, 9);
    e.wrap(a + b, exprIds([a, b]), innerExpr - b);
    e.subs(eq((a + b) - b, a), exprIds([a, b]));
    e.wrap(a * b, exprIds([a, b]), innerExpr / b);
    e.subs(eq((a * b) / b, a), exprIds([a, b]));
    e.eval();

    // Check
    expect(e, equals(eq(x, 2)));
  });

  test('Chain rule', () {
    final sin = fn1('sin');
    final cos = fn1('cos');
    final diff = fn2('diff');
    final fn = fn1('fn');
    final x = symbol('x');

    /// Use chain rule to find derivative of sin(x^3)
    final e = eq(symbol('y'), diff(sin(x ^ 3), x));
    e.subs(eq(diff(fn(a), b), diff(a, b) * diff(fn(a), a)),
        exprIds([a, b, fn(a)]));
    e.subs(eq(diff(a ^ b, a), b * a ^ (b - 1)), exprIds([a, b]));
    e.subs(eq(diff(sin(a), a), cos(a)), exprIds([a]));
    e.eval();
    expect(e, equals(eq(symbol('y'), (x ^ 2) * 3 * cos(x ^ 3))));
  }, skip: true);

  test('Fibonaci', () {
    //
  });

  test('Power operator', () {
    expect(
        eq(symbol('y'), symbol('x') ^ 3)
          ..subs(eq(symbol('x'), 3))
          ..eval(),
        equals(eq(symbol('y'), 27)));
  });
}
