// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/latex.dart';

import 'dummy_expr.dart';

void main() {
  final ctx = new SimpleExprContext();
  final parser = new LaTeXParser(ctx.labelResolver);
  final printer = new LaTeXPrinter();
  printer.addDefaultEntries(ctx.labelResolver);

  // Helper.
  final ops = new OperatorConfig(0);
  LaTeXParser.setOperators(ops, ctx.assignId);
  final printLaTeX = (dynamic input) => printer.render(
      input is String ? parseExpression(input, ops, ctx.assignId) : input,
      ctx.getLabel,
      ops);

  test('LaTeX dictionary', () async {
    printer.dict[ctx.assignId('lim', false)] = r'\lim_{$0\to$1}$(*2)';

    expect(printLaTeX('lim(x, 0, x ^ 2)'), equals(r'\lim_{x\to0}x^{2}'));
    expect(printLaTeX('lim(x, a, x + 1)'),
        equals(r'\lim_{x\to a}\left(x+1\right)'));

    // Render function with too few arguments (template cannot be resolved).
    expect(() => printLaTeX('lim(x, 0)'), throwsArgumentError);

    // Symbol template.
    printer.dict[ctx.assignId('pi', false)] = r'\pi';
    expect(printLaTeX('pi'), equals(r'\pi'));

    // Print function that has not been defined.
    expect(
        printLaTeX('3 * fn(a, b)'), equals(r'3\text{fn}{\left(a,\,b\right)}'));

    // Expect argument error for custom expression.
    expect(() => printLaTeX(new DummyExpr()), throwsArgumentError);
  });

  test('LaTeX printing', () {
    final id = (String label) => ctx.assignId(label, false);
    printer.dict[id('diff')] = r'\frac{\partial}{\partial$(0*)}$(1*)';
    printer.dict[id('int')] = r'\int_{$0}^{$1}$2~\text{d}$(3*)';
    printer.dict[id('sin')] = r'\sin$(0*)';
    printer.dict[id('delta')] = r'\Delta$(0*)';
    printer.dict[id('celcius')] = r'$(0*)^\circ';

    final tests = {
      '(a + -5) ^ (b * c)': r'\left(a+-5\right)^{bc}',
      '(a / -5) ^ (b * c)': r'\left(\frac{a}{-5}\right)^{bc}',
      '-(1 ^ 2)': r'-\left(1^{2}\right)',
      '(-1)^2': r'-1^{2}',
      '-1 ^ 2': r'-1^{2}',
      '---a': r'---a',
      'a + b + c': r'a+b+c',
      'celcius(10)': r'10^\circ',
      'celcius(a+10)': r'\left(a+10\right)^\circ',
      'delta(1+x)+sin(a)^2': r'\Delta\left(1+x\right)+\left(\sin a\right)^{2}',
      'delta(2x)+sin(2a)^2': r'\Delta2x+\left(\sin2a\right)^{2}',
      'int(0,1,x^2+2x+1,1/x)*2':
          r'\left(\int_{0}^{1}x^{2}+2x+1~\text{d}\frac{1}{x}\right)2',
      'int(0,1,x^2+2x+1,1/x+1)*2':
          r'\left(\int_{0}^{1}x^{2}+2x+1~\text{d}\left(\frac{1}{x}+1\right)\right)2',
      'diff(x+1, x+2)*2':
          r'\left(\frac{\partial}{\partial\left(x+1\right)}\left(x+2\right)\right)2',
      'diff(2x, x+2)': r'\frac{\partial}{\partial2x}\left(x+2\right)'
    };

    tests.forEach((input, output) {
      expect(printLaTeX(input), equals(output));
    });
  });

  test('Parsing', () {
    expect(parser.parse(r'\sin^2\theta', ctx.assignId),
        equals(ctx.parse(r'sin(\theta)^2')));
    expect(parser.parse(r'\frac{d}{dx}x^2', ctx.assignId),
        equals(ctx.parse(r'diff(x^2, x)')));

    expect(printLaTeX(parser.parse('(a_0!+b_0!)/c_0!', ctx.assignId)),
        equals(r'\frac{a_{0}!+b_{0}!}{c_{0}!}'));
  });
}
