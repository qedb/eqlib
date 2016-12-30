// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/latex_printer.dart';

import 'myexpr.dart';

void main() {
  test('Built-in operators', () {
    final printer = new LaTeXPrinter();
    printer.addDefaultEntries();

    expect(printer.render(new Expr.parse('(a + -5) ^ (b * c)')),
        equals(r'\left({a}+-5\right)^{{b}\cdot{c}}'));

    expect(printer.render(new Expr.parse('(a / -5) ^ (b * c)')),
        equals(r'\left(\frac{{a}}{-5}\right)^{{b}\cdot{c}}'));

    // Note: for syntax reasons, the precedence of unary- > power operator.
    expect(printer.render(new Expr.parse('(-1)^2')), equals(r'-1^{2}'));
    expect(printer.render(new Expr.parse('-1 ^ 2')), equals(r'-1^{2}'));
    expect(printer.render(new Expr.parse('-(1 ^ 2)')),
        equals(r'-\left(1^{2}\right)'));

    expect(printer.render(new Expr.parse('---a')), equals(r'---{a}'));

    printer.destruct();
  });

  test('LaTeX dictionary', () async {
    final printer = new LaTeXPrinter();
    printer.addDefaultEntries();
    printer.dictUpdate(eqlibSAResolve('lim'),
        new LaTeXDictEntry(r'\lim_{$a\to$b}$(c)', false, 1));

    expect(printer.render(new Expr.parse('lim(x, 0, x ^ 2)')),
        equals(r'\lim_{{x}\to0}{x}^{2}'));
    expect(printer.render(new Expr.parse('lim(x, 0, x + 1)')),
        equals(r'\lim_{{x}\to0}\left({x}+1\right)'));

    // Render function with too few arguments (template cannot be resolved).
    expect(
        () => printer.render(new Expr.parse('lim(x, 0)')), throwsArgumentError);

    // Test dictUpdate/dictReplace with onDictUpdate.
    bool dictUpdated = false;
    printer.onDictUpdate.listen((_) {
      dictUpdated = true;
    });

    printer.dictUpdate(eqlibSAResolve('pi'), new LaTeXDictEntry(r'\pi'));
    printer.dictReplace(eqlibSAResolve('pi'), eqlibSAResolve('phi'),
        new LaTeXDictEntry(r'\phi'));

    // Print single symbol.
    expect(printer.render(new Expr.parse('pi')), equals(r'{pi}'));
    expect(printer.render(new Expr.parse('phi')), equals(r'{\phi}'));

    // Print function that has not been defined.
    expect(printer.render(new Expr.parse('3 * fn(x)')),
        equals(r'3\cdot\text{fn}\left({x}\right)'));

    // Expect argument error for custom expression.
    expect(() => printer.render(new MyExpr()), throwsArgumentError);

    await printer.destruct();
    expect(dictUpdated, equals(true));
  });
}
