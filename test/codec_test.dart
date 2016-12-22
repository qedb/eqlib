// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';

void main() {
  test('Codec test', () {
    final expr =
        parseExpr('mul(2, pow(a(?a, ?b, sub(3.45, mul(6, 7))), add(a, b)))');

    // Check encoder.
    expect(
        expr.toBase64(),
        equals(
            'CQACAAMAAQCamZmZmZkLQEKULgqbgdsAAwAAAAUAAABClC4KAgAAAAEAAABClC4Km4HbAAAAAgIDAgIAAAIGBwIJAwQAAQUMAgoLBgcI'));

    // Check decoder.
    expect(new Expr.fromBinary(expr.toBinary()), equals(expr));
    expect(new Expr.fromBase64(expr.toBase64()), equals(expr));
  });
}
