// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library eqlib;

import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';
import 'package:eqlib/utils.dart';
import 'package:eqlib/exceptions.dart';
import 'package:collection/collection.dart';

import 'src/parser_utils.dart';

part 'src/expr.dart';
part 'src/subs.dart';
part 'src/number.dart';
part 'src/function.dart';
part 'src/interface.dart';
part 'src/parser.dart';
part 'src/context.dart';
part 'src/expr_mapping.dart';
part 'src/operator_config.dart';
part 'src/simple_context.dart';

part 'src/codec.dart';
part 'src/array_codec.dart';
part 'src/expr_diff.dart';
