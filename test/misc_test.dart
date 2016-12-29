// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:quiver/core.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/inline.dart';
import 'package:eqlib/exceptions.dart';

void main() {
  final a = symbol('a'), b = symbol('b');

  test('Eq.hashCode', () {
    expect(new Eq.parse('100=100').hashCode,
        equals(hash2(hash2(0, 100), hash2(0, 100))));
    expect(new Eq.parse('a * b = b * a').hashCode,
        equals(eq(a * b, b * a).hashCode));
  });

  test('Expr.from', () {
    expect(new Expr.from(new SymbolExpr(100)), equals(new SymbolExpr(100)));
    expect(new Expr.from(100), equals(new NumberExpr(100)));
    expect(() => new Expr.from('a'), throwsArgumentError);
  });

  test('EqLibException', () {
    expect(new EqLibException('abc').toString(), equals('abc'));
    expect(eqlibThrows('abc').describe(new StringDescription()).toString(),
        equals('throws EqLibException:<abc>'));
  });
}
