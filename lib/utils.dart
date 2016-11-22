// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library eqlib.utils;

/// Object wrapper
class W<T> {
  T v;
  W(T intial) : v = intial;
}

/// Indexed version of [Iterable.every] for [List].
bool ifEvery(List a, List b, bool test(dynamic a, dynamic b)) {
  assert(a.length == b.length);
  for (var i = 0; i < a.length; i++) {
    if (!test(a[i], b[i])) {
      return false;
    }
  }
  return true;
}
