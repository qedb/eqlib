// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/exceptions.dart';

void main() {
  final ctx = new SimpleExprContext();
  test('Fibonacci', () {
    final fib = ctx.parseSubs('fib(?n) = ffib(?n, 1, 0)');
    final ffib = ctx.parseSubs('ffib(?n, ?a, ?b) = ffib(?n - 1, ?a + ?b, ?a)');
    final ffib0 = ctx.parseSubs('ffib(0, ?a, ?b) = ?b');

    final e = ctx.parse('fib(10)').substitute(fib);
    expect(
        substituteRecursive(e, ffib, ffib0, ctx.compute).evaluate(ctx.compute),
        equals(ctx.parse('55')));

    // Test max recursions.
    expect(() => substituteRecursive(e, ffib, ffib0, ctx.compute, n: 1, max: 9),
        eqlibThrows('reached maximum number of recursions'));

    // Test incorrect recursion.
    expect(
        () => substituteRecursive(
            e, ctx.parseSubs('ffib(?n, ?a, ?b) = 0'), ffib0, ctx.compute),
        eqlibThrows('could not find 1 substitution sites'));
  });

  test('Factorial', () {
    final fac = ctx.parseSubs('fac(?n) = ?n * fac(?n - 1)');
    final fac1 = ctx.parseSubs('fac(1) = 1');

    final e = ctx.parse('fac(10)');
    expect(substituteRecursive(e, fac, fac1, ctx.compute).evaluate(ctx.compute),
        equals(ctx.parse('3628800')));
  });
}
