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

/// Jenkins one-at-a-time hash

int jCombine(int hash, int value) {
  // ignore: parameter_assignments
  hash = 0x1fffffff & (hash + value);
  // ignore: parameter_assignments
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int jFinish(int hash) {
  // ignore: parameter_assignments
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  // ignore: parameter_assignments
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}
