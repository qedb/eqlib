// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/latex.dart';

import 'myexpr.dart';

void main() {
  final ctx = new SimpleExprContext();
  final parser = new LaTeXParser(ctx.labelResolver);
  final printer = new LaTeXPrinter();
  printer.addDefaultEntries(ctx.labelResolver);

  test('Printing', () {
    final tests = {
      '(a + -5) ^ (b * c)': r'\left({a}+-5\right)^{{b}\cdot{c}}',
      '(a / -5) ^ (b * c)': r'\left(\frac{{a}}{-5}\right)^{{b}\cdot{c}}',
      '-(1 ^ 2)': r'-\left(1^{2}\right)',
      '(-1)^2': r'-1^{2}',
      '-1 ^ 2': r'-1^{2}',
      '---a': r'---{a}'
    };

    tests.forEach((input, output) {
      expect(printer.render(ctx.parse(input), ctx.getLabel), equals(output));
    });
  });

  test('Parsing', () {
    expect(parser.parse(r'\sin^2\theta', ctx.assignId),
        equals(ctx.parse(r'sin(\theta)^2')));
    expect(parser.parse(r'\frac{d}{dx}x^2', ctx.assignId),
        equals(ctx.parse(r'diff(x^2, x)')));

    expect(
        printer.render(
            parser.parse('(a_0!+b_0!)/c_0!', ctx.assignId), ctx.getLabel),
        equals(r'\frac{{a}_0!+{b}_0!}{{c}_0!}'));
  });

  test('LaTeX dictionary', () async {
    printer.addDictEntry(ctx.assignId('lim', false),
        new LaTeXDictEntry(r'\lim_{$0\to$1}$(2)', false, 1));

    expect(printer.render(ctx.parse('lim(x, 0, x ^ 2)'), ctx.getLabel),
        equals(r'\lim_{{x}\to0}{x}^{2}'));
    expect(printer.render(ctx.parse('lim(x, 0, x + 1)'), ctx.getLabel),
        equals(r'\lim_{{x}\to0}\left({x}+1\right)'));

    // Render function with too few arguments (template cannot be resolved).
    expect(() => printer.render(ctx.parse('lim(x, 0)'), ctx.getLabel),
        throwsArgumentError);

    // Symbol template.
    printer.addDictEntry(ctx.assignId('pi', false), new LaTeXDictEntry(r'\pi'));
    expect(printer.render(ctx.parse('pi'), ctx.getLabel), equals(r'{\pi}'));

    // Print function that has not been defined.
    expect(printer.render(ctx.parse('3 * fn(x)'), ctx.getLabel),
        equals(r'3\cdot\text{fn}\left({x}\right)'));

    // Expect argument error for custom expression.
    expect(
        () => printer.render(new MyExpr(), ctx.getLabel), throwsArgumentError);
  });
}
