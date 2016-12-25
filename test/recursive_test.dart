// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';

void main() {
  test('Fibonacci', () {
    new Expr.parse('ffib(?n - 1, ?a + ?b, ?a)');
    final fib = new Eq.parse('fib(?n) = ffib(?n, 1, 0)');
    final ffib = new Eq.parse('ffib(?n, ?a, ?b) = ffib(?n - 1, ?a + ?b, ?a)');
    final ffib0 = new Eq.parse('ffib(0, ?a, ?b) = ?b');

    var e = new Expr.parse('fib(10)');
    e = e.subs(fib);
    e = e.subsRecursive(ffib, ffib0);
    expect(e.eval(), equals(55));
  });
}
