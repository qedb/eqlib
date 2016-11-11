// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

/// TODO:
/// - Put notebook in separate repository.
/// - Implement optimized classes for numeric expressions.
/// - Implement generic function mapping.
library eqlib;

import 'package:quiver/core.dart';
import 'package:eqlib/utils.dart';
import 'package:eqlib/default.dart';
import 'package:petitparser/petitparser.dart';

part 'src/eq.dart';
part 'src/expr.dart';
part 'src/parser_simple.dart';
part 'src/parser_petitparser.dart';
