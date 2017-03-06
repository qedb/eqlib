// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:eqlib/eqlib.dart';

/// New Expr type for testing
class MyExpr extends Expr {
  MyExpr();

  @override
  MyExpr clone() => new MyExpr();

  @override
  bool equals(other) => other is MyExpr;

  @override
  int get expressionHash => 0;

  @override
  bool get isGeneric => true;

  @override
  ExprMatchResult matchSuperset(superset) => new ExprMatchResult.exactMatch();

  @override
  Expr remap(mapping, genericFunctions) => clone();

  @override
  num evaluateInternal(compute) => double.NAN;
}
