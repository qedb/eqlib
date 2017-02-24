// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/inline.dart';
import 'package:eqlib/exceptions.dart';

void main() {
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
    final e = eq(pvec, vec2d);
    e.substitute(eq(vec2d, x * ihat + y * jhat));
    e.substitute(eq(x, px));
    e.substitute(eq(y, py));
    e.substitute(eq(px, r * sin(theta)));
    e.substitute(eq(py, r * cos(theta)));
    e.substitute(eq((a * b) * c, a * (b * c)));
    e.substitute(eq((a * b) * c, a * (b * c)));
    e.substitute(eq(a * b + a * c, a * (b + c)));

    expect(e, equals(eq(pvec, r * (sin(theta) * ihat + cos(theta) * jhat))));
  });

  test('Solve simple equations', () {
    final x = symbol('x');

    final steps = new Stepper([
      new Step.envelop(a + b, innerExpr - b),
      new Step.substitute((a + b) - b, a),
      new Step.envelop(a * b, innerExpr / b),
      new Step.substitute((a * b) / b, a),
      new Step.evaluate()
    ]);

    expect(steps.run(eq(x * 2 + 5, 9)), equals(eq(x, 2)));
    expect(steps.run(eq(9, x * 2 + 5)), equals(eq(2, x)));

    // Fail on purpose.
    expect(() => steps.run(eq(x * 5, 9)),
        eqlibThrows('the template does not match left or right'));
  });

  test('Chain rule', () {
    final sin = fn1('sin');
    final cos = fn1('cos');
    final diff = fn2('diff');
    final fn = fn1('fn', generic: true);
    final x = symbol('x');

    /// Use chain rule to find derivative of sin(x^3)
    final e = eq(symbol('y'), diff(sin(x ^ 3), x));
    e.substitute(eq(diff(fn(a), b), diff(a, b) * diff(fn(a), a)));
    e.substitute(eq(diff(a ^ b, a), b * (a ^ (b - 1))));
    e.substitute(eq(diff(sin(a), a), cos(a)));
    e.evaluate();
    expect(e, equals(eq(symbol('y'), number(3) * (x ^ 2) * cos(x ^ 3))));
  });

  test('Power operator', () {
    expect(
        eq(symbol('y'), symbol('x') ^ 3)
          ..substitute(eq(symbol('x'), 3))
          ..evaluate(),
        equals(eq(symbol('y'), 27)));
  });
}
