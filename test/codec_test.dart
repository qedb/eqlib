// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';

void main() {
  test('Codec test', () {
    final expr = new Expr.parse(
        'mul(2, pow(a(?a, ?b, sub(3.45, mul(6, 7))), add(a, b)))');

    // Check encoder.
    expect(
        expr.toBase64(),
        equals(
            'CQACAAMAAQCamZmZmZkLQEKULgqbgdsAAwAAAAUAAABClC4KAgAAAAEAAABClC4Km4HbAAAAAgIDAgIAAAIGBwIJAwQAAQUMAgoLBgcI'));

    // Check encoding and decoding.
    expect(new Expr.fromBinary(expr.toBinary()), equals(expr));
    expect(new Expr.fromBase64(expr.toBase64()), equals(expr));
  });

  test('256+ function table codec', () {
    final n = 1000;
    final offset = ComputableExpr.values.length + 1;
    final expr = new Expr.parse(
        new List<String>.generate(n, (i) => 'sym${offset + i}').join('+'));

    // Check encoding and decoding.
    expect(new Expr.fromBinary(expr.toBinary()), equals(expr));
    expect(new Expr.fromBase64(expr.toBase64()), equals(expr));
  });

  test('Corrupted data', () {
    final n = 1000;
    final data = new Uint16List.fromList(new List<int>.generate(n, (i) => i));
    expect(() => new Expr.fromBinary(data.buffer), throwsArgumentError);
  });
}
