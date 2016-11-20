// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/inline.dart';
import 'package:eqlib/latex_printer.dart';

void main() {
  test('Simple LaTeX printing tests', () {
    final printer = new LaTeXPrinter();
    printer.addDefaultEntries(dfltExprEngine.resolve);

    // (a + 5)^(b * c)
    expect(
        printer.render(pow(symbol('a') + number(5), symbol('b') * symbol('c')),
            dfltExprEngine.resolveName),
        equals(r'\left({a}+5\right)^{{b}\cdot{c}}'));
  });

  test('LaTeX dictionary', () {
    final printer = new LaTeXPrinter();
    printer.addDefaultEntries(dfltExprEngine.resolve);
    printer.dictReplace(
        -1, dfltExprEngine.resolve('lim'), r'\lim_{$a\to$b}$(c)');

    // lim(x->0, x^2)
    expect(
        printer.render(
            new Expr.parse('lim(x,0,pow(x,2))'), dfltExprEngine.resolveName),
        equals(r'\lim_{{x}\to0}{x}^{2}'));

    // lim(x->0, x+1)
    expect(
        printer.render(
            new Expr.parse('lim(x,0,add(x,1))'), dfltExprEngine.resolveName),
        equals(r'\lim_{{x}\to0}\left({x}+1\right)'));
  });
}
