// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expression resolver function.
typedef num SingleExprResolver(List<num> args);

/// Expression resolver.
class ExprResolver {
  final _resolvers = new Map<String, SingleExprResolver>();

  void addResolver(String expr, SingleExprResolver fn) {
    if (!_resolvers.containsKey(expr)) {
      _resolvers[expr] = fn;
    }
  }

  bool canResolve(String expr) => _resolvers.containsKey(expr);

  num resolve(String expr, List<num> args) {
    if (_resolvers.containsKey(expr)) {
      return _resolvers[expr](args);
    } else {
      return null;
    }
  }
}
