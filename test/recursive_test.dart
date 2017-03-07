// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/exceptions.dart';

void main() {
  final ctx = new SimpleExprContext();

  test('Fibonacci', () {
    final fib = ctx.parseEq('fib(?n) = ffib(?n, 1, 0)');
    final ffib = ctx.parseEq('ffib(?n, ?a, ?b) = ffib(?n - 1, ?a + ?b, ?a)');
    final ffib0 = ctx.parseEq('ffib(0, ?a, ?b) = ?b');

    var e = ctx.parse('fib(10)');
    e = e.substitute(fib);
    expect(ctx.evaluate(ctx.substituteRecursivly(e, ffib, ffib0)), equals(55));

    // Test max recursions.
    expect(
        () => ctx.substituteRecursivly(e, ffib, ffib0, 0), throwsArgumentError);
    expect(() => ctx.substituteRecursivly(e, ffib, ffib0, 9),
        eqlibThrows('reached maximum number of recursions'));

    // Test incorrect recursion.
    expect(
        () => ctx.substituteRecursivly(
            e, ctx.parseEq('fffib(?n, ?a, ?b) = 0'), ffib0),
        eqlibThrows('recursion ended before terminator was reached'));
  });

  test('Factorial', () {
    final fac = ctx.parseEq('fac(?n) = ?n * fac(?n - 1)');
    final fac1 = ctx.parseEq('fac(1) = 1');

    var e = ctx.parse('fac(10)');
    e = ctx.substituteRecursivly(e, fac, fac1);
    expect(ctx.evaluate(e), equals(3628800));
  });
}
