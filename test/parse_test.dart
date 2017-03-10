// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/inline.dart';

/// Even shorter alias for convenience.
NumberExprOps n(num val) => number(val);

void main() {
  final ctx = inlineCtx;

  test('Fundamental checks for the parser', () {
    final a = generic('a'), b = generic('b'), c = generic('c');

    // Extra parentheses
    expect(ctx.parse('(((?a + ?b)))'), equals(a + b));

    // Precedence and whitespaces
    expect(ctx.parse(' ( 1 + 2 ) * 3 ^ sin( a + ?b ) '),
        equals((n(1) + 2) * (n(3) ^ fn1('sin')(symbol('a') + b))));

    // Numeric values
    expect(ctx.parse('-1.23 - 4 + .567 ^ -.89'),
        equals((n(-1.23) - 4) + (n(.567) ^ -.89)));
    expect((ctx.evaluate(ctx.parse('-1.23 - 4 + .567 ^ -.89')) * 1000).toInt(),
        equals(-3573));

    // Unary minus
    expect(ctx.evaluate(ctx.parse('-  - -1')), equals(-1));
    expect(ctx.parse('---?a'), equals(-(-(-a))));
    expect(ctx.parse('-?a ^ ?b'), equals((-a) ^ b));

    // Implicit multiplication
    expect(ctx.parse('?a^?b?c'), equals(a ^ (b * c)));
    expect(ctx.parse('?a^f(?b)?c'), equals(a ^ (fn1('f')(b)) * c));
    expect(ctx.parse('?a ?b ?c'), equals(a * (b * c)));
    expect(ctx.parse('(?a ?b) ?c'), equals((a * b) * c));
    expect(ctx.parse('?a sin(?b)'), equals(a * fn1('sin')(b)));
    expect(ctx.parse('-1 2 ^ -3 4'), equals(n(-1) * (n(2) ^ (n(-3) * 4))));
    expect(ctx.parse('-3sin(2 ^3 (4+5)?b)'),
        equals(n(-3) * fn1('sin')(n(2) ^ (n(3) * ((n(4) + 5) * b)))));

    // Singleton suffix operator (factorial, !)
    // To keep things together the printing test is also here.
    final fac = fn1('!');
    expect(ctx.parse('(?a! + ?b!)/?c!'), equals((fac(a) + fac(b)) / fac(c)));
    expect(ctx.str(ctx.parse('(?a! + ?b!)/?c!')), equals('(?a!+?b!)/?c!'));
  });

  test('Parentheses mismatch', () {
    expect(() => ctx.parse(''), throwsFormatException);
    expect(() => ctx.parse(')'), throwsFormatException);
    expect(() => ctx.parse('a+b)'), throwsFormatException);
    expect(() => ctx.parse('fn(,)'), throwsFormatException);
    expect(() => ctx.parse('a,b'), throwsFormatException);
    expect(() => ctx.parse('a+b,b'), throwsFormatException);
    expect(() => ctx.parse('(a,b)'), throwsFormatException);
    expect(() => ctx.parse('a+'), throwsFormatException);
  });

  test('Derivation of centripetal acceleration (step 1)', () {
    final pvec = ctx.parseEq('pvec = vec2d');
    pvec.substitute(ctx.parseEq('vec2d = x ihat + y jhat'));
    pvec.substitute(ctx.parseEq('x = px'));
    pvec.substitute(ctx.parseEq('y = py'));
    pvec.substitute(ctx.parseEq('px = r sin(theta)'));
    pvec.substitute(ctx.parseEq('py = r cos(theta)'));
    pvec.substitute(ctx.parseEq('(?a ?b) ?c = ?a (?b ?c)'));
    pvec.substitute(ctx.parseEq('(?a ?b) ?c = ?a (?b ?c)'));
    pvec.substitute(ctx.parseEq('?a ?b + ?a ?c = ?a*(?b+?c)'));
    expect(ctx.str(pvec), equals('pvec=r*(sin(theta)*ihat+cos(theta)*jhat)'));
  });

  test('Solve a simple equation', () {
    final eq = ctx.parseEq('x 2 + 5 = 9');
    eq.envelop(ctx.parse('?a + ?b'), ctx.parse('{} - ?b'));
    eq.substitute(ctx.parseEq('?a + ?b - ?b = ?a'));
    eq.envelop(ctx.parse('?a*?b'), ctx.parse('{} / ?b'));
    eq.substitute(ctx.parseEq('(?a * ?b) / ?b = ?a'));
    eq.evaluate(ctx.compute);

    expect(eq.left, equals(symbol('x')));
    expect(ctx.evaluate(eq.right), equals(2.0));
  });
}
