// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/inline.dart';
import 'package:eqlib/exceptions.dart';

void main() {
  final ctx = inlineExprContext;

  test('Product rule through limits', () {
    final lim = fn3('lim');
    final diff = fn2('diff');
    final fn = fn1('fn', generic: true);
    final x = symbol('x');
    final genx = generic('x');
    final d = fn1('d');
    final a = fn1('a', generic: true);
    final b = fn1('b', generic: true);

    final productRule = subs(diff(fn(genx), genx),
        lim(d(x), 0, (fn(genx + d(genx)) - fn(genx)) / d(genx)));
    final input = diff(a(x) * b(x), x);
    expect(input.substitute(productRule),
        equals(lim(d(x), 0, (a(x + d(x)) * b(x + d(x)) - a(x) * b(x)) / d(x))));
  });

  test('Generic function argument inference exceptions', () {
    expect(
        () =>
            ctx.parse('f(x)+g(x)').substitute(ctx.parseSubs('?a(?b)+?a(?c)=d')),
        eqlibThrows('generic functions must have the same arguments'));

    expect(() => ctx.parse('a*c').substitute(ctx.parseSubs('?a(c)=d')),
        eqlibThrows('dependant variables must be generic symbols'));

    expect(
        () => ctx.parse('a(b)').substitute(ctx.parseSubs('?a(?b)=?a(?b,?c)')),
        eqlibThrows(
            'dependant variable count does not match the target substitutions'));

    expect(
        () => ctx.parse('a(b,c)').substitute(ctx.parseSubs('?a(?b,?c)=d')),
        eqlibThrows(
            'in strict mode multiple dependant variables are not allowed'));

    expect(
        ctx.str(ctx
            .parse('fn(b/2, b)')
            .substitute(ctx.parseSubs('fn(?a(?b), ?b)=?a(?b+1)+?b'))),
        equals('(b+1)/2+b'));

    expect(
        () => ctx
            .parse('fn(b/c, b)')
            .substitute(ctx.parseSubs('fn(?a(?b), ?b)=?a(?b+1)+?b')),
        eqlibThrows(
            'in strict mode the generic substitute can only depend on the variable that is remapped'));

    expect(
        () => ctx.parse('diff(x^2, x^2)').substitute(ctx.parseSubs(
            'diff(?f(?x), ?x) = lim(d(?x), 0 (?f(?x+d(?x))-?f(?x))/d(x))')),
        eqlibThrows('generic function inner mapping must map from a symbol'));
  });
}
