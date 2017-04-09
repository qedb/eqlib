// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

class Rule {
  final Expr left, right;
  Rule(this.left, this.right);

  @override
  bool operator ==(dynamic other) =>
      other is Rule && other.left == left && other.right == right;

  @override
  int get hashCode => hashCode2(left, right);
}
