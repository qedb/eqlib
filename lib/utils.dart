// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library eqlib.utils;

/// Object wrapper
class W<T> {
  T v;
  W(T intial) : v = intial;
}

/// Generator function for [generateList].
typedef T ListItemGenerator<T>(int idx);

/// Helper function for creating lists.
List<T> generateList<T>(int n, List<ListItemGenerator<T>> generators) {
  final list = new List<T>(n * generators.length);
  var i = 0;
  for (final generator in generators) {
    for (var j = 0; j < n; j++) {
      list[i++] = generator(j);
    }
  }
  return list;
}

/// Shortcut for retrieving character ID of the first character in the given
/// string.
int char(String str) => str.runes.first;

/// Jenkins one-at-a-time hash
///
/// Copied from:
/// https://github.com/google/quiver-dart/blob/master/lib/src/core/hash.dart

// ignore: parameter_assignments
int jMix(int hash, int value) {
  // ignore: parameter_assignments
  hash = 0x1fffffff & (hash + value);
  // ignore: parameter_assignments
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

// ignore: parameter_assignments
int jPostprocess(int hash) {
  // ignore: parameter_assignments
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  // ignore: parameter_assignments
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

int hashCode2(Object a, Object b) =>
    jPostprocess(jMix(jMix(0, a.hashCode), b.hashCode));

int hashCode3(Object a, Object b, Object c) =>
    jPostprocess(jMix(jMix(jMix(0, a.hashCode), b.hashCode), c.hashCode));

int hashObjects(Iterable objects) =>
    jPostprocess(objects.fold(0, (h, i) => jMix(h, i.hashCode)));
