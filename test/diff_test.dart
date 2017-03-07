// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/inline.dart';

void main() {
  final ctx = inlineCtx;
  final a = symbol('a', generic: true);
  final b = symbol('b', generic: true);

  test('Chain rule', () {
    final sin = fn1('sin');
    final cos = fn1('cos');
    final diff = fn2('diff');
    final fn = fn1('fn', generic: true);
    final x = symbol('x');

    /// Use chain rule to find derivative of sin(x^3)
    final e = eq(symbol('y'), diff(sin(x ^ 3), x));
    final e1 = e.clone();

    e.substitute(eq(diff(fn(a), b), diff(a, b) * diff(fn(a), a)));
    final e2 = e.clone();

    e.substitute(eq(diff(a ^ b, a), b * (a ^ (b - 1))));
    final e3 = e.clone();

    e.substitute(eq(diff(sin(a), a), cos(a)));
    final e4 = e.clone();

    // First step difference
    expect(difference(e1.right, e2.right),
        equals(new TreeDiffResult(diff: new TreeDiff(eq(e1.right, e2.right)))));

    // Second step difference
    expect(
        difference(e2.right, e3.right),
        equals(new TreeDiffResult(
            diff: new TreeDiff(eq(e2.right, e3.right), [
          new TreeDiff(eq(diff(x ^ 3, x), number(3) * (x ^ (number(3) - 1))))
        ]))));

    // Third step difference
    expect(
        difference(e3.right, e4.right),
        equals(new TreeDiffResult(
            diff: new TreeDiff(eq(e3.right, e4.right),
                [new TreeDiff(eq(diff(sin(x ^ 3), x ^ 3), cos(x ^ 3)))]))));
  });

  test('numsNotEqual', () {
    expect(difference(number(1), number(2)),
        equals(new TreeDiffResult(hasDiff: true, numsNotEqual: true)));
    expect(difference(ctx.parse('1 + a'), ctx.parse('2 + a')),
        equals(new TreeDiffResult(diff: new TreeDiff(ctx.parseEq('1+a=2+a')))));
  });
}
