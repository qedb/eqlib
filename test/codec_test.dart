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
    final id = (String str) => ctx.assignId(str, false);
    final idg = (String str) => ctx.assignId(str, true);

    // Basic functionality.
    final expr = ctx.parse('2 * a(?a, ?b, 3 - 6 * 7) ^ (a + b)');
    expect(
        expr.toArray(),
        equals([
          // Multiply function, 2 args, content-length: 36
          4, id('*'), 2, 36,
          /**/ // Integer with value 2
          /**/ 1, 2,
          /**/ // Power function, 2 args, content-length: 30
          /**/ 4, id('^'), 2, 30,
          /****/ // a() function, 3 args, content-length: 18
          /****/ 4, id('a'), 3, 18,
          /******/ // Generic ?a
          /******/ 3, idg('a'),
          /******/ // Generic ?b
          /******/ 3, idg('b'),
          /******/ // Subtract function, 2 args, content-length: 10
          /******/ 4, id('-'), 2, 10,
          /********/ // Integer with value 3
          /********/ 1, 3,
          /********/ // Multiply function, 2 args, content-length: 4
          /********/ 4, id('*'), 2, 4,
          /**********/ // Integer with value 6
          /**********/ 1, 6,
          /**********/ // Integer with value 7
          /**********/ 1, 7,
          /****/ // Addition function, 2 args, content-length: 4
          /****/ 4, id('+'), 2, 4,
          /******/ // Symbol a
          /******/ 2, id('a'),
          /******/ // Symbol b
          /******/ 2, id('b')
        ]));
    expect(new Expr.fromArray(expr.toArray()), equals(expr));

    // Exceptions
    expect(() => ctx.parse('2 * a(?a, ?b, 3.45 - 6 * 7) ^ (a + b)').toArray(),
        throwsArgumentError);
  });
}
