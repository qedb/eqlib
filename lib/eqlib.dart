// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

/// TODO:
/// - Store numeric values inside the Expr.
/// - Make Expr final, operations ALWAYS produce a new instance.
/// - Provide functions and operators for inline expression building.
/// - Create a binary format for dense expression storage.
library eqlib;

import 'package:quiver/core.dart';
import 'package:eqlib/compute.dart';
import 'package:eqlib/utils.dart';

part 'src/expr.dart';
part 'src/eq.dart';
