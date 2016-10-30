// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

/// TODO:
/// - Store expressions as integers (keep String labels in a Map).
/// - Store numeric values inside the Expr.
/// - Make Expr final, operations ALWAYS produce a new instance.
/// - Provide functions and operators for inline expression building.
/// - Create a plain text format for derivations (to build a library).
library eqlib;

import 'package:quiver/core.dart';

part 'src/resolver.dart';
part 'src/expr.dart';
part 'src/eq.dart';
