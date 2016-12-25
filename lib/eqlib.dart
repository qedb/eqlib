// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

/// TODO:
/// - Recursive/conditional substitution
library eqlib;

import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:quiver/core.dart';
import 'package:eqlib/utils.dart';

part 'src/eq.dart';
part 'src/expr.dart';
part 'src/expr_num.dart';
part 'src/expr_sym.dart';
part 'src/expr_fun.dart';
part 'src/expr_codec.dart';
part 'src/interface.dart';
part 'src/standalone.dart';
part 'src/parser.dart';
part 'src/tree_diff.dart';
