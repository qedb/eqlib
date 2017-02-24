// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/latex.dart';

void main() {
  test('Basic LaTeX parsing', () {
    final parser = new LaTeXParser();

    expect(parser.parse(r'\sin^2\theta'),
        equals(new Expr.parse(r'sin(\theta)^2')));
    expect(parser.parse(r'\frac{d}{dx}x^2'),
        equals(new Expr.parse(r'diff(x^2, x)')));
  });
}
