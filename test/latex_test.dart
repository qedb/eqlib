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
    printer.addDefaultEntries(standaloneResolve);

    // (a + -5)^(b * c)
    expect(
        printer.render(pow(symbol('a') + -number(5), symbol('b') * symbol('c')),
            standaloneResolveName),
        equals(r'\left({a}+-{5}\right)^{{b}\cdot{c}}'));

    // (a / -5) ^ (b * c)
    expect(
        printer.render(pow(symbol('a') / -number(5), symbol('b') * symbol('c')),
            standaloneResolveName),
        equals(r'\left(\frac{{a}}{-{5}}\right)^{{b}\cdot{c}}'));

    printer.destruct();
  });

  test('LaTeX dictionary', () {
    final printer = new LaTeXPrinter();
    printer.addDefaultEntries(standaloneResolve);
    printer.dictUpdate(standaloneResolve('lim'),
        new LaTeXPrinterEntry(r'\lim_{$a\to$b}$(c)', 2));

    // lim(x->0, x^2)
    expect(
        printer.render(
            new Expr.parse('lim(x,0,pow(x,2))'), standaloneResolveName),
        equals(r'\lim_{{x}\to0}{x}^{2}'));

    // lim(x->0, x+1)
    expect(
        printer.render(
            new Expr.parse('lim(x,0,add(x,1))'), standaloneResolveName),
        equals(r'\lim_{{x}\to0}\left({x}+1\right)'));

    printer.destruct();
  });
}
