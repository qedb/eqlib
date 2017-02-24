// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';

class EqLibException implements Exception {
  final String message;
  const EqLibException(this.message);

  @override
  String toString() => message;
}

class _EqLibExceptionMatcher extends TypeMatcher {
  final String message;
  const _EqLibExceptionMatcher(this.message) : super('EqLibException');

  @override
  bool matches(item, matchState) =>
      item is EqLibException && item.message == message;

  @override
  Description describe(Description description) =>
      description..add('EqLibException:<$message>');
}

Matcher eqlibThrows([String message = '']) {
  return throwsA(new _EqLibExceptionMatcher(message));
}
