// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';

void main() {
  test('Derivation of centripetal acceleration (step 1)', () {
    var pvec = new Eq.parse('pvec = vec2d');
    pvec.sub(new Eq.parse('vec2d = add(mult(x, ihat), mult(y, jhat))'));
    pvec.sub(new Eq.parse('x = px'));
    pvec.sub(new Eq.parse('y = py'));
    pvec.sub(new Eq.parse('px = mult(r, sin(th))'));
    pvec.sub(new Eq.parse('py = mult(r, cos(th))'));
    pvec.sub(new Eq.parse('mult(mult(a, b), c) = mult(a, mult(b, c))'),
        gen: ['a', 'b', 'c']);
    pvec.sub(new Eq.parse('mult(mult(a, b), c) = mult(a, mult(b, c))'),
        gen: ['a', 'b', 'c']);
    pvec.sub(new Eq.parse('add(mult(a, b), mult(a, c)) = mult(a, add(b, c))'),
        gen: ['a', 'b', 'c']);

    // Check
    expect(pvec.toString(),
        equals('pvec=mult(r,add(mult(sin(th),ihat),mult(cos(th),jhat)))'));
  });
}
