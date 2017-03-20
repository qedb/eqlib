// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/inline.dart';
import 'package:eqlib/exceptions.dart';

void main() {
  final ctx = inlineCtx;

  test('Product rule through limits', () {
    final lim = fn3('lim');
    final diff = fn2('diff');
    final fn = fn1('fn', generic: true);
    final x = symbol('x');
    final genx = generic('x');
    final d = fn1('d');
    final a = fn1('a', generic: true);
    final b = fn1('b', generic: true);

    final rule = eq(diff(fn(genx), genx),
        lim(d(x), 0, (fn(genx + d(genx)) - fn(genx)) / d(genx)));
    final input = diff(a(x) * b(x), x);
    expect(input.substitute(rule),
        equals(lim(d(x), 0, (a(x + d(x)) * b(x + d(x)) - a(x) * b(x)) / d(x))));
  });

  test('Various staments related to generic function argument inference', () {
    // Generic functions can only have a single argument.
    expect(() => ctx.parse('?a(b,c)').substitute(ctx.parseEq('?a(b,c)=d')),
        eqlibThrows('generic functions can only have a single argument'));
    expect(
        () => ctx
            .parse('?a(b,c)')
            .remap({ctx.assignId('a', true): symbol('d')}, {}),
        eqlibThrows('generic functions can only have a single argument'));

    // Generic functions must all be equal.
    expect(() => ctx.parse('?a(b(c))').substitute(ctx.parseEq('?a(?a(b))=d')),
        eqlibThrows('generic functions must all be equal'));
  });

  test('Nested generic functions', () {
    expect(
        ctx.parse('diff(x, sqrt(x^2))').substitute(ctx.parseEq(
            'diff(?x, ?f(?g(?x))) = diff(?x, ?g(?x))*diff(?g(?x), ?f(?g(?x)))')),
        equals(ctx.parse('diff(x,x^2)*diff(x^2,sqrt(x^2))')));
  });
}
