// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';

void main() {
  final ctx = new SimpleExprContext();

  test('Binary codec', () {
    final expr = ctx.parse('2 * a(?a, ?b, 3.45 - 6 * 7) ^ (a + b)');

    // Check encoder.
    expect(
        expr.toBase64(),
        equals(
            'CQACAAMAAQCamZmZmZkLQAwAAAANAAAABgAAAAgAAAALAAAABQAAAAQAAAALAAAADgAAAAAAAgIDAgIAAAIGBwIJAwQAAQUMAgoLBgcI'));

    // Check encoding and decoding.
    expect(new Expr.fromBinary(expr.toBinary()), equals(expr));
    expect(new Expr.fromBase64(expr.toBase64()), equals(expr));
  });

  test('Binary codec 256+ function table', () {
    final n = 1000;
    final expr =
        ctx.parse(new List<String>.generate(n, (i) => 'symbol$i').join('+'));

    // Check encoding and decoding.
    expect(new Expr.fromBinary(expr.toBinary()), equals(expr));
    expect(new Expr.fromBase64(expr.toBase64()), equals(expr));
  });

  test('Binary codec corrupted data', () {
    final n = 1000;
    final data = new Uint16List.fromList(new List<int>.generate(n, (i) => i));
    expect(() => new Expr.fromBinary(data.buffer), throwsArgumentError);
  });

  test('Array codec', () {
    // Basic functionality.
    final expr = ctx.parse('2 * a(?a, ?b, 3 - 6 * 7) ^ (a + b)');
    expect(
        expr.toArray(),
        equals([
          //
          4, 6, 2, 36, 1, 2, 4, 8, 2, 30, 4, 11, 3, 18, 3, 12, 3, 13, 4, 5,
          //
          2, 10, 1, 3, 4, 6, 2, 4, 1, 6, 1, 7, 4, 4, 2, 4, 2, 11, 2, 14
        ]));
    expect(new Expr.fromArray(expr.toArray()), equals(expr));

    // Exceptions
    expect(() => ctx.parse('2 * a(?a, ?b, 3.45 - 6 * 7) ^ (a + b)').toArray(),
        throwsArgumentError);
  });
}
