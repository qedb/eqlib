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
        printer.format(pow(symbol('a') + number(5), symbol('b') * symbol('c')),
            dfltExprEngine.resolveName),
        equals('{\\left({a}+5\\right)}^{{b}\\cdot{c}}'));
  });
}
