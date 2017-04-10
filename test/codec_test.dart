// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';

void main() {
  final ctx = new SimpleExprContext();

  test('Binary codec', () {
    expect(() => ctx.parse('2 * a(?a, ?b, 3.45 - 6 * 7) ^ (a + b)').toBase64(),
        throwsArgumentError);

    final expr = ctx.parse('2 * a(?a, ?b, 3.45 - 6 * 7) ^ (aa + b)');
    expect(new ExprCodecData.decodeHeader(expr.toBinary()).containsFloats(),
        isTrue);
    expect(
        expr.toBase64(),
        equals(
            'AQADAAkAAgCamZmZmZkLQAIAAAAGAAAABwAAAAwAAAANAAAABgAAAAgAAAALAAAABQAAAAQAAAAPAAAADgAAAAAAAgIDAgIAAAIJAwQAAQUMAgoLBgcI'));

    // Check encoding and decoding.
    expect(new Expr.fromBinary(expr.toBinary()), equals(expr));
    expect(new Expr.fromBase64(expr.toBase64()), equals(expr));
  });

  test('Binary codec 255+ function table', () {
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
          // Multiply function, 2 args, content-length: 49
          221356710, 4, id('*'), 2, 49,
          /**/ // Integer with value 2
          /**/ 5, 1, 2,
          /**/ // Power function, 2 args, content-length: 41
          /**/ 783138374, 4, id('^'), 2, 41,
          /****/ // a() function, 3 args, content-length: 25
          /****/ 76988010, 4, id('a'), 3, 25,
          /******/ // Generic ?a
          /******/ 412232228, 3, idg('a'),
          /******/ // Generic ?b
          /******/ 930637808, 3, idg('b'),
          /******/ // Subtract function, 2 args, content-length: 14
          /******/ 265202872, 4, id('-'), 2, 14,
          /********/ // Integer with value 3
          /********/ 7, 1, 3,
          /********/ // Multiply function, 2 args, content-length: 6
          /********/ 453715154, 4, id('*'), 2, 6,
          /**********/ // Integer with value 6
          /**********/ 13, 1, 6,
          /**********/ // Integer with value 7
          /**********/ 15, 1, 7,
          /****/ // Addition function, 2 args, content-length: 6
          /****/ 427513450, 4, id('+'), 2, 6,
          /******/ // Symbol a
          /******/ 331817734, 2, id('a'),
          /******/ // Symbol b
          /******/ 168365960, 2, id('b')
        ]));
    expect(new Expr.fromArray(expr.toArray()), equals(expr));

    // Exceptions
    expect(() => ctx.parse('2 * a(?a, ?b, 3.45 - 6 * 7) ^ (a + b)').toArray(),
        throwsArgumentError);
  });

  test('Array codec integers', () {
    expect(new Expr.fromBase64(ctx.parse('2147483647').toBase64()).toArray()[2],
        equals(2147483647));
  });
}
