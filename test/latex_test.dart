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
  final printer = new LaTeXPrinter(ctx.labelResolver.getLabel, ctx.operators);
  printer.addDefaultEntries(ctx.labelResolver.assignId);

  // Helper.
  final ops = new OperatorConfig(0);
  LaTeXParser.setOperators(ops, ctx.assignId);
  int id(String label) => ctx.assignId(label, false);
  String printLaTeX(input) => printer.render(
      input is String ? parseExpression(input, ops, ctx.assignId) : input);

  test('Printing basics', () async {
    printer.addTemplate(id('pi'), r'\pi');
    printer.addTemplate(id('lim'), r'\lim_{${0}\to${1}}${:2(+).}');

    expect(printLaTeX('lim(x, 0, x ^ 2)'), equals(r'\lim_{x\to0}{x}^{2}'));
    expect(printLaTeX('lim(x, a, x + 1)'),
        equals(r'\lim_{x\to a}\left(x+1\right)'));

    // Render function with too few arguments (template cannot be resolved).
    expect(() => printLaTeX('lim(x, 0)'), throwsRangeError);

    // Symbol template.
    expect(printLaTeX('pi'), equals(r'\pi'));

    // Print function that has not been defined.
    expect(
        printLaTeX('3 * fn(a, b)'), equals(r'3\text{fn}{\left(a,\,b\right)}'));

    // Expect argument error for custom expression.
    expect(() => printLaTeX(new DummyExpr()), throwsArgumentError);
  });

  test('Printing extensive', () {
    printer.addTemplate(
        id('diff'), r'\frac{\partial}{\partial${:0(+)}}${:1(+).}');
    printer.addTemplate(id('int'), r'\int_{${0}}^{${1}}${2}~\text{d}${:3(+).}');
    printer.addTemplate(id('sin'), r'\sin${:0(+).}');
    printer.addTemplate(id('delta'), r'\Delta${:0(+).}');
    printer.addTemplate(id('celcius'), r'${.0(^)}^\circ');
    printer.addTemplate(id('hp'), r'${0(+)}+$!');

    final tests = {
      '1 * 2': r'1\left(2\right)',
      '2 * 10^a': r'2\left({10}^{a}\right)',
      '(a + -5) ^ (b * c)': r'{\left(a+-5\right)}^{b c}',
      '(a / -5) ^ (b * c)': r'{\left(\frac{a}{-5}\right)}^{b c}',
      '-(1 ^ 2)': r'-\left({1}^{2}\right)',
      '(-1) ^ 2': r'{-1}^{2}',
      '-1 ^ 2': r'{-1}^{2}',
      '---a': r'---a',
      'a + b + -c': r'a+b+-c',
      'a + b * -c': r'a+b\left(-c\right)',
      'celcius(10)': r'10^\circ',
      'celcius(a+10)': r'\left(a+10\right)^\circ',
      'celcius(10)*2': r'10^\circ2',
      'a*celcius(10)': r'a10^\circ',
      '2*celcius(10)': r'2\left(10^\circ\right)',
      'a*celcius(-10)': r'a\left(-10^\circ\right)',
      '2*celcius(-10)': r'2\left(-10^\circ\right)',
      'delta(2x)+sin(2a)^2': r'\Delta2x+{\left(\sin2a\right)}^{2}',
      'delta(1+x)+sin(a)^2':
          r'\Delta\left(1+x\right)+{\left(\sin a\right)}^{2}',
      '2*sin(a*b)': r'2\sin a b',
      'sin(a*b)*2': r'\left(\sin a b\right)2',
      'sin(a)^2': r'{\left(\sin a\right)}^{2}',
      'sin(a^2)': r'\sin{a}^{2}',
      'hp(10)': r'10+',
      'hp(10)+1': r'10++1',
      'hp(10)*1': r'\left(10+\right)1',

      // Integrals
      '2*int(0,1,x^2+2x+1,1/x)':
          r'2\int_{0}^{1}{x}^{2}+2x+1~\text{d}\frac{1}{x}',
      'int(0,1,x^2+2x+1,1/x)*2':
          r'\left(\int_{0}^{1}{x}^{2}+2x+1~\text{d}\frac{1}{x}\right)2',
      'int(0,1,x^2+2x+1,1/x+1)*2':
          r'\left(\int_{0}^{1}{x}^{2}+2x+1~\text{d}\left(\frac{1}{x}+1\right)\right)2',

      // Derivatives
      'diff(2x, x+2)': r'\frac{\partial}{\partial2x}\left(x+2\right)',
      'diff(x, -a)': r'\frac{\partial}{\partial x}\left(-a\right)',
      'diff(x, -1)': r'\frac{\partial}{\partial x}\left(-1\right)',
      'diff(x, -1*a)': r'\frac{\partial}{\partial x}\left(-1a\right)',
      'diff(-1, -1)*2':
          r'\left(\frac{\partial}{\partial\left(-1\right)}\left(-1\right)\right)2',
      'diff(x+1, x+2)*2':
          r'\left(\frac{\partial}{\partial\left(x+1\right)}\left(x+2\right)\right)2'
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
        equals(r'\frac{{a}_{0}!+{b}_{0}!}{{c}_{0}!}'));
  });

  test('Negative integers', () {
    expect(printLaTeX(new NumberExpr(-10)), equals('-10'));
  });

  test('LaTeX templates', () {
    expect(
        parseLaTeXTemplate(
                r'\int_{${0}}^{${1}}${2}~\text{d}${:3(+).}', ctx.operators)
            .parameterCount,
        equals(4));
  });
}
