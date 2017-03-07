// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/latex.dart';

void main() {
  final ctx = new SimpleExprContext();

  test('Built-in operators', () {
    final printer = new LaTeXPrinter();
    printer.addDefaultEntries(ctx.operators);

    expect(printer.render(ctx.parse('(a + -5) ^ (b * c)'), ctx.getLabel),
        equals(r'\left({a}+-5\right)^{{b}\cdot{c}}'));

    expect(printer.render(ctx.parse('(a / -5) ^ (b * c)'), ctx.getLabel),
        equals(r'\left(\frac{{a}}{-5}\right)^{{b}\cdot{c}}'));

    // Note: for syntax reasons, the precedence of unary- > power operator.
    expect(
        printer.render(ctx.parse('(-1)^2'), ctx.getLabel), equals(r'-1^{2}'));
    expect(
        printer.render(ctx.parse('-1 ^ 2'), ctx.getLabel), equals(r'-1^{2}'));
    expect(printer.render(ctx.parse('-(1 ^ 2)'), ctx.getLabel),
        equals(r'-\left(1^{2}\right)'));

    expect(printer.render(ctx.parse('---a'), ctx.getLabel), equals(r'---{a}'));
  });
}
