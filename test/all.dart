// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'parse_test.dart' as parse_test;
import 'inline_test.dart' as inline_test;
import 'recursive_test.dart' as recursive_test;
import 'codec_test.dart' as codec_test;
import 'latex_test.dart' as latex_test;
import 'diff_test.dart' as diff_test;

void main() {
  group('Expression parsing', parse_test.main);
  group('Inline expression API', inline_test.main);
  group('Recursive substitutions', recursive_test.main);
  group('Binary codec', codec_test.main);
  group('LaTeX printer', latex_test.main);
  group('Tree-Diff', diff_test.main);
}
