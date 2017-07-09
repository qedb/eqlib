// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:math';

import 'package:test/test.dart';
import 'package:eqlib/inline.dart';

/// Even shorter alias for convenience.
NumberExprOps n(num val) => number(val);

void main() {
  final ctx = inlineExprContext;

  test('Fundamental checks for the parser', () {
    final a = generic('a'), b = generic('b'), c = generic('c');

    // Operator precedence
    expect(ctx.parse('?a + ?b + ?c'), equals((a + b) + c));

    // Extra parentheses
    expect(ctx.parse('(((?a() + ?b)))'), equals(a + b));

    // Precedence and whitespaces
    expect(ctx.parse(' ( 1 + 2 ) * 3 ^ sin( a + ?b ) '),
        equals((n(1) + 2) * (n(3) ^ fn1('sin')(symbol('a') + b))));

    // Numeric values
    expect(ctx.parse('-1.23 - 4 + .567 ^ -.89'),
        equals((-n(1.23) - 4) + (n(.567) ^ -n(.89))));
    expect(ctx.parse('-1.23 - 4 + .567 ^ -.89').evaluate(ctx.compute),
        equals(number(-1.23 - 4 + pow(.567, -.89))));

    // Unary minus
    expect(ctx.parse('-  - -1').evaluate(ctx.compute), equals(number(-1)));
    expect(ctx.parse('---?a'), equals(-(-(-a))));
    expect(ctx.parse('-?a ^ ?b'), equals((-a) ^ b));

    // Implicit multiplication
    expect(ctx.parse('?a^?b?c'), equals(a ^ (b * c)));
    expect(ctx.parse('?a^f(?b)?c'), equals(a ^ (fn1('f')(b)) * c));
    expect(ctx.parse('?a ?b ?c'), equals(a * (b * c)));
    expect(ctx.parse('(?a ?b) ?c'), equals((a * b) * c));
    expect(ctx.parse('?a sin(?b)'), equals(a * fn1('sin')(b)));
    expect(ctx.parse('-1 2 ^ -3 4'), equals(-n(1) * (n(2) ^ (-n(3) * 4))));
    expect(ctx.parse('-3sin(2 ^3 (4+5)?b)'),
        equals(-n(3) * fn1('sin')(n(2) ^ (n(3) * ((n(4) + 5) * b)))));

    // Postfix operator (factorial, !)
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
    final pvec = ctx
        .parse('pvec = vec2d')
        .substitute(ctx.parseSubs('vec2d = x ihat + y jhat'))
        .substitute(ctx.parseSubs('x = px'))
        .substitute(ctx.parseSubs('y = py'))
        .substitute(ctx.parseSubs('px = r sin(theta)'))
        .substitute(ctx.parseSubs('py = r cos(theta)'))
        .substitute(ctx.parseSubs('(?a ?b) ?c = ?a (?b ?c)'))
        .substitute(ctx.parseSubs('(?a ?b) ?c = ?a (?b ?c)'))
        .substitute(ctx.parseSubs('?a ?b + ?a ?c = ?a*(?b+?c)'));

    expect(ctx.str(pvec), equals('pvec=r*(sin(theta)*ihat+cos(theta)*jhat)'));
  });

  test('Solve a simple equation', () {
    final e = ctx
        .parse('x 2 + 5 = 9')
        .substitute(ctx.parseSubs('(?a + ?b = ?c) = (?a = ?c - ?b)'))
        .substitute(ctx.parseSubs('(?a * ?b = ?c) = (?a = ?c / ?b)'))
        .evaluate(ctx.compute);

    expect(e, equals(ctx.parse('x = 2.0')));
  });
}
