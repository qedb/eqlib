// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/utils.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/inline.dart';
import 'package:eqlib/exceptions.dart';

import 'dummy_expr.dart';

void main() {
  final ctx = inlineCtx;
  final a = symbol('a'), b = symbol('b');

  test('hashCode utils', () {
    expect(hashCode2(1, 10), equals(hashCode2(1, 10)));
    expect(hashCode2(1, 10), isNot(hashCode2(1, 11)));
    expect(hashCode3(1, 10, 100), equals(hashCode3(1, 10, 100)));
    expect(hashCode3(1, 10, 100), isNot(hashCode3(1, 11, 100)));
    expect(hashObjects([1, 10, 100]), equals(hashObjects([1, 10, 100])));
    expect(hashObjects([1, 10, 100]), isNot(hashObjects([1, 11, 100])));
  });

  test('Eq.hashCode', () {
    expect(
        ctx.parseEq('100=100').hashCode,
        equals(jPostprocess(jMix(jMix(0, jPostprocess(jMix(1041, 100))),
            jPostprocess(jMix(1041, 100))))));
    expect(ctx.parseEq('a * b = b * a').hashCode,
        equals(eq(a * b, b * a).hashCode));

    // Vaildate hashCodes across different expression types.
    expect(new NumberExpr(10).hashCode,
        isNot(new FunctionExpr(10, false, []).hashCode));
  });

  test('EqLibException', () {
    expect(new EqLibException('abc').toString(), equals('abc'));
    expect(eqlibThrows('abc').describe(new StringDescription()).toString(),
        equals('throws EqLibException:<abc>'));
  });

  test('Expr.from', () {
    expect(new Expr.from(new FunctionExpr(100, false, [])),
        equals(new FunctionExpr(100, false, [])));
    expect(new Expr.from(100), equals(new NumberExpr(100)));
    expect(() => new Expr.from('a'), throwsArgumentError);
  });

  test('FunctionExpr.compare', () {
    expect(ctx.parse('a(b)').compare(number(1)), equals(false));
    expect(
        () => ctx.parse('a(b)').compare(new DummyExpr()), throwsArgumentError);
  });

  test('Basic SimpleExprContext checks', () {
    expect(ctx.evaluate(ctx.parse('-(1 + 1)')), equals(-2));
    expect(() => ctx.str(new DummyExpr()), throwsArgumentError);

    // Resolve generic/non-generic is distinctive.
    expect(ctx.assignId('x', false), isNot(equals(ctx.assignId('x', true))));
    expect(new PrinterEntry('x', false).hashCode,
        isNot(new PrinterEntry('x', true).hashCode));

    // Printing.
    final printTest = ctx.parse('1 + a - 3 * (b / 5) ^-c');
    expect(ctx.str(printTest), equals('1+a-3*(b/5)^-c'));

    // Equation parsing exception.
    expect(() => ctx.parseEq('a'), eqlibThrows('no top level equation found'));

    // Printing exception.
    expect(() => ctx.str([]), throwsArgumentError);
  });
}
