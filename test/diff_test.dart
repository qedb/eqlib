// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/inline.dart';

void main() {
  final ctx = inlineExprContext;
  final a = symbol('a', generic: true);
  final b = symbol('b', generic: true);
  final rearrangeableIds = [ctx.operators.id('+'), ctx.operators.id('*')];

  final getDiff = (String left, String right) =>
      getExpressionDiff(ctx.parse(left), ctx.parse(right), rearrangeableIds);

  test('Chain rule', () {
    final sin = fn1('sin');
    final cos = fn1('cos');
    final diff = fn2('diff');
    final fn = fn1('fn', generic: true);
    final x = symbol('x');

    /// Use chain rule to find derivative of sin(x^3)
    var e = diff(sin(x ^ 3), x);
    final e1 = e.clone();

    e = e.substitute(rule(diff(fn(a), b), diff(a, b) * diff(fn(a), a)));
    final e2 = e.clone();

    e = e.substitute(rule(diff(a ^ b, a), b * (a ^ (b - 1))));
    final e3 = e.clone();

    e = e.substitute(rule(diff(sin(a), a), cos(a)));
    final e4 = e.clone();

    // First step difference
    expect(getExpressionDiff(e1, e2, rearrangeableIds),
        equals(new ExprDiffResult(branch: new ExprDiffBranch(0, e1, e2))));

    // Second step difference
    final step2diff = getExpressionDiff(e2, e3, rearrangeableIds);
    final step2diffExpect = new ExprDiffResult(
        branch: new ExprDiffBranch(0, e2, e3, argumentDifference: [
      new ExprDiffBranch(1, diff(x ^ 3, x), ctx.parse('3*x^(3-1)')),
      new ExprDiffBranch(6, diff(sin(x ^ 3), x ^ 3), diff(sin(x ^ 3), x ^ 3))
    ]));
    //print(ctx.str(fn2('=')(e2, e3)));
    expect(step2diff.branch.argumentDifference.last.isDifferent, isFalse);
    expect(step2diff, equals(step2diffExpect));

    // Third step difference
    final step3diff = getExpressionDiff(e3, e4, rearrangeableIds);
    final step3diffExpect = new ExprDiffResult(
        branch: new ExprDiffBranch(0, e3, e4, argumentDifference: [
      new ExprDiffBranch(1, ctx.parse('3*x^(3-1)'), ctx.parse('3*x^(3-1)')),
      new ExprDiffBranch(8, diff(sin(x ^ 3), x ^ 3), cos(x ^ 3))
    ]));
    //print(ctx.str(fn2('=')(e3, e4)));
    expect(step3diff.branch.argumentDifference.first.isDifferent, isFalse);
    expect(step3diff, equals(step3diffExpect));

    // Compare hash codes in third step difference.
    expect(step3diff.hashCode, equals(step3diffExpect.hashCode));
    expect(step3diff.branch.hashCode, equals(step3diffExpect.branch.hashCode));
  });

  test('Numeric inequality', () {
    final one = number(1), two = number(2);
    expect(getExpressionDiff(one, one, rearrangeableIds),
        equals(new ExprDiffResult(branch: new ExprDiffBranch(0, one, one))));
    expect(getExpressionDiff(one, two, rearrangeableIds),
        equals(new ExprDiffResult(numericInequality: true)));
    expect(
        getDiff('1 + a', '2 + a'),
        equals(new ExprDiffResult(
            branch:
                new ExprDiffBranch(0, ctx.parse('1+a'), ctx.parse('2+a')))));
  });

  test('Rearrange expressions', () {
    final diff1 = //
        getDiff('a * b * (c * (d + e + f))', 'b * (c * ((f + (e + d)) * a))');
    final diff2 = //
        getDiff('a * (b * c * (d + e + f))', 'a * (c * ((f + (e + d)) * b))');
    final diff3 = //
        getDiff('?b * ?a + ?c * ?a', '?a * ?b + ?a * ?c');
    final diff4 = //
        getDiff('?b * ?a + ?c * ?a * ?d * ?e', '?a * ?b + ?e * ?d * ?a * ?c');

    expect(
        diff1.branch.rearrangements,
        equals([
          // [0:d, 1:e, 2:f] => [f:2, [e:1, d:0]]
          new Rearrangement.at(6, [2, 1, 0, -1]),
          // [0:a, 1:b, 2:c, 3:def] => [b:1, [c:2, [def:3, a:0]]]
          new Rearrangement.at(0, [1, 2, 3, 0, -1, -1])
        ]));
    expect(
        diff2.branch.rearrangements,
        equals([
          // [0:d, 1:e, 2:f] => [f:2, [e:1, d:0]]
          new Rearrangement.at(6, [2, 1, 0, -1]),
          // [0:b, 1:c, 2:def] => [c:1, [def:2, b:0]]
          new Rearrangement.at(2, [1, 2, 0, -1])
        ]));
    expect(
        diff3.branch.rearrangements,
        equals([
          new Rearrangement.at(1, [1, 0]),
          new Rearrangement.at(4, [1, 0]),
          new Rearrangement.at(0, [0, 1])
        ]));
    expect(
        diff4.branch.rearrangements,
        equals([
          new Rearrangement.at(1, [1, 0]),
          // [c:0, a:1, d:2, e:3] => [[[e:3, d:2], a:1], c:0]
          new Rearrangement.at(4, [3, 2, -1, 1, -1, 0]),
          new Rearrangement.at(0, [0, 1])
        ]));

    final shouldFail =
        getDiff('a * b * c * ((d + e) + f)', 'b * f * (c + e + d) * a');
    expect(shouldFail.branch.rearrangements, equals([]));

    // Just to test Rearrangement.hashCode.
    expect(diff1.branch.rearrangements.first.hashCode,
        equals(new Rearrangement.at(6, [2, 1, 0, -1]).hashCode));
    expect(new Rearrangement.at(6, [2, 1, 0, -1]).hashCode,
        isNot(new Rearrangement.at(6, [1, 2, 0, -1]).hashCode));
    expect(new Rearrangement.at(6, [2, 1, 0, -1]).hashCode,
        isNot(new Rearrangement.at(7, [2, 1, 0, -1]).hashCode));

    // Rearrangement into fewer children should fail (this was a bug).
    expect(getDiff('?a*?b*?c', '?a*?b').branch.rearrangements, equals([]));
  });
}
