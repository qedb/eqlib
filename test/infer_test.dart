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
    expect(() => ctx.parse('?a(b,c)').substitute(ctx.parseEq('?a(?b,c)=d')),
        eqlibThrows('dependant variables must be generic symbols'));

    // Generic functions must have the same arguments.
    expect(
        () => ctx.parse('f(x)+g(x)').substitute(ctx.parseEq('?a(?b)+?a(?c)=d')),
        eqlibThrows('generic functions must have the same arguments'));
  });
}
