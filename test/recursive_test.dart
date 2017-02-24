// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/exceptions.dart';

void main() {
  test('Fibonacci', () {
    final fib = new Eq.parse('fib(?n) = ffib(?n, 1, 0)');
    final ffib = new Eq.parse('ffib(?n, ?a, ?b) = ffib(?n - 1, ?a + ?b, ?a)');
    final ffib0 = new Eq.parse('ffib(0, ?a, ?b) = ?b');

    var e = new Expr.parse('fib(10)');
    e = e.substitute(fib);
    expect(e.substituteRecursivly(ffib, ffib0).evaluate(), equals(55));

    // Test max recursions.
    expect(() => e.substituteRecursivly(ffib, ffib0, 0), throwsArgumentError);
    expect(() => e.substituteRecursivly(ffib, ffib0, 9),
        eqlibThrows('reached maximum number of recursions'));

    // Test incorrect recursion.
    expect(
        () => e.substituteRecursivly(
            new Eq.parse('fffib(?n, ?a, ?b) = 0'), ffib0),
        eqlibThrows('recursion ended before terminator was reached'));
  });

  test('Factorial', () {
    final fac = new Eq.parse('fac(?n) = ?n * fac(?n - 1)');
    final fac1 = new Eq.parse('fac(1) = 1');

    var e = new Expr.parse('fac(10)');
    e = e.substituteRecursivly(fac, fac1);
    expect(e.evaluate(), equals(3628800));
  });
}
