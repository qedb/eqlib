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
            'AQADAAkAAgCamZmZmZkLQAIAAAAGAAAABwAAAAwAAAANAAAABgAAAAgAAAALAAAABQAAAAQAAAAPAAAADgAAAAAAAAACAAIAAwACAAIAAAAAAAIJAwQAAQUMAgoLBgcI'));

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

  test('Binary codec data overflow', () {
    expect(
        () => new FunctionExpr(
                1, false, new List.generate(65537, (_) => new NumberExpr(1)))
            .toBase64(),
        throwsArgumentError);
    expect(() => new FunctionExpr(4294967296, false, []).toBase64(),
        throwsArgumentError);
    expect(() => new NumberExpr(2147483648).toBase64(), throwsArgumentError);
  });

  test('Array codec', () {
    final id = (String str) => ctx.assignId(str, false);
    final idg = (String str) => ctx.assignId(str, true);
    final binary = (int value) {
      var ret = 0;
      var i = 0;
      while (value > 0) {
        final bit = (value / 10).ceil() > (value / 10).floor() ? 1 : 0;
        value = value ~/ 10;
        ret |= (bit << i);
        i++;
      }
      return ret;
    };

    // Basic functionality.
    final expr = ctx
        .parse('2 * a(?a, ?b, 3 - c(6, -7)) ^ (a + b)')
        .evaluate(ctx.compute);
    expect(
        expr.toArray(),
        equals([
          // Multiply function, 2 args, content-length: 49
          137229168, 4, id('*'), 2, 49,
          /**/ // Integer with value 2
          /**/ binary(1001), 1, 2,
          /**/ // Power function, 2 args, content-length: 41
          /**/ 251831922, 4, id('^'), 2, 41,
          /****/ // a() function, 3 args, content-length: 25
          /****/ 1004447222, 4, id('a'), 3, 25,
          /******/ // Generic ?a
          /******/ 412232228, 3, idg('a'),
          /******/ // Generic ?b
          /******/ 930637808, 3, idg('b'),
          /******/ // Subtract function, 2 args, content-length: 14
          /******/ 975330728, 4, id('-'), 2, 14,
          /********/ // Integer with value 3
          /********/ binary(1101), 1, 3,
          /********/ // Multiply function, 2 args, content-length: 6
          /********/ 747787730, 4, id('c'), 2, 6,
          /**********/ // Integer with value 6
          /**********/ binary(11001), 1, 6,
          /**********/ // Integer with value -7
          /**********/ binary(11111), 1, -7,
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
