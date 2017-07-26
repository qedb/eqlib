// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:eqlib/eqlib.dart';

/// New Expr type for testing
class DummyExpr extends Expr {
  DummyExpr();

  @override
  DummyExpr clone() => new DummyExpr();

  @override
  bool equals(other) => other is DummyExpr;

  @override
  int get expressionHash => 0;

  @override
  bool get isGeneric => true;

  @override
  List<Expr> flatten() => [this];

  @override
  void getFunctionIds(target) {}

  @override
  Expr remap(mapping) => clone();

  @override
  Expr substituteAt(equation, position, [mapping]) => clone();

  @override
  Expr evaluate(compute) => clone();
}
