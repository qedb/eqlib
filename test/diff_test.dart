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
    expect(
        buildEqDiff(e1.right, e2.right),
        equals(
            new EqDiffResult(diff: new EqDiffBranch(eq(e1.right, e2.right)))));

    // Second step difference
    expect(
        buildEqDiff(e2.right, e3.right),
        equals(new EqDiffResult(
            diff: new EqDiffBranch(eq(e2.right, e3.right), [
          new EqDiffBranch(
              eq(diff(x ^ 3, x), number(3) * (x ^ (number(3) - 1))))
        ]))));

    // Third step difference
    final step3diff = buildEqDiff(e3.right, e4.right);
    final step3diffExpect = new EqDiffResult(
        diff: new EqDiffBranch(eq(e3.right, e4.right),
            [new EqDiffBranch(eq(diff(sin(x ^ 3), x ^ 3), cos(x ^ 3)))]));

    expect(step3diff, equals(step3diffExpect));

    // Compare hash codes in third step difference.
    expect(step3diff.hashCode, equals(step3diffExpect.hashCode));
    expect(step3diff.diff.hashCode, equals(step3diffExpect.diff.hashCode));
  });

  test('Numeric inequality', () {
    expect(buildEqDiff(number(1), number(2)),
        equals(new EqDiffResult(hasDiff: true, numericInequality: true)));
    expect(
        buildEqDiff(ctx.parse('1 + a'), ctx.parse('2 + a')),
        equals(
            new EqDiffResult(diff: new EqDiffBranch(ctx.parseEq('1+a=2+a')))));
  });
}
