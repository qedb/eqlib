// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

enum Associativity { ltr, rtl }
enum OperatorType { prefix, infix, postfix }

class Operator {
  final int id;
  final int char;
  final int precedenceLevel;
  final Associativity associativity;
  final OperatorType operatorType;

  const Operator(this.id, this.precedenceLevel, this.associativity,
      [this.char = -1, this.operatorType = OperatorType.infix]);
}

/// Operator configuration
class OperatorConfig {
  // An internal ID has to be assigned to implicit multiplication.
  // This is 0 by default.
  final implicitMultiplyId;

  final byId = new Map<int, Operator>();
  final byChar = new Map<int, Operator>();

  OperatorConfig([this.implicitMultiplyId = 0]);

  void add(Operator op) {
    byId[op.id] = op;
    if (op.char != -1) {
      byChar[op.char] = op;
    }
  }

  int id(String str) => byChar[char(str)].id;
}
