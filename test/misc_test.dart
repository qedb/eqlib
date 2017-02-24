// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/utils.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/inline.dart';
import 'package:eqlib/exceptions.dart';

import 'myexpr.dart';

void main() {
  final a = symbol('a'), b = symbol('b');

  test('Eq.hashCode', () {
    expect(
        new Eq.parse('100=100').hashCode,
        equals(jFinish(jCombine(jCombine(0, jFinish(jCombine(1041, 100))),
            jFinish(jCombine(1041, 100))))));
    expect(new Eq.parse('a * b = b * a').hashCode,
        equals(eq(a * b, b * a).hashCode));

    // Vaildate hashCodes across different expression types.
    expect(new NumberExpr(10).hashCode, isNot(new SymbolExpr(10).hashCode));
  });

  test('EqLibException', () {
    expect(new EqLibException('abc').toString(), equals('abc'));
    expect(eqlibThrows('abc').describe(new StringDescription()).toString(),
        equals('throws EqLibException:<abc>'));
  });

  test('Expr.from', () {
    expect(new Expr.from(new SymbolExpr(100)), equals(new SymbolExpr(100)));
    expect(new Expr.from(100), equals(new NumberExpr(100)));
    expect(() => new Expr.from('a'), throwsArgumentError);
  });

  test('FunctionExpr.matchSuperset', () {
    expect(
        new Expr.parse('a(b)').matchSuperset(number(1)).match, equals(false));
    expect(() => new Expr.parse('a(b)').matchSuperset(new MyExpr()),
        throwsArgumentError);
  });

  test('Standalone engine', () {
    expect(new Expr.parse('-(1 + 1)').evaluate(), equals(-2));
    expect(() => eqlibSAPrint(new MyExpr()), throwsArgumentError);

    // Standalone resolve generic/non-generic distinctive.
    expect(eqlibSAResolve('x'), isNot(equals(eqlibSAResolve('x', true))));

    // Standalone printer.
    final allIn = new Expr.parse('1 + a - 3 * b / 5 ^-c');
    eqlibSABackend.printerOpChars = true;
    expect(allIn.toString(), equals('1 + a - {{3}*{b}}/{{5}^{-{c}}}'));
    eqlibSABackend.printerOpChars = false;
    expect(allIn.toString(),
        equals('sub(add(1, a), div(mul(3, b), pow(5, neg(c))))'));
  });
}
