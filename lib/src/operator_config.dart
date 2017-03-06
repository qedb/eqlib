// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

enum Associativity { ltr, rtl }

/// Operator configuration
class OperatorConfig {
  // An internal ID has to be assigned to implicit multiplication.
  // This is 0 by default.
  final implicitMultiplyId;

  final opIds = new List<int>();
  final opChars = new List<int>();
  final charToId = new Map<int, int>();
  final idToArgc = new Map<int, int>();
  final idToPrecedence = new Map<int, int>();
  final idToAssociativity = new Map<int, Associativity>();

  OperatorConfig([this.implicitMultiplyId = 0]);

  void add(Associativity associativity,
      {String char: '', int argc: 0, int lvl: 0, int id: 0}) {
    if (opChars.contains(char) || opIds.contains(id)) {
      throw new EqLibException('operator already configured');
    }

    opIds.add(id);
    idToArgc[id] = argc;
    idToPrecedence[id] = lvl;
    idToAssociativity[id] = associativity;
    if (char.isNotEmpty) {
      charToId[char.codeUnitAt(0)] = id;
      opChars.add(char.codeUnitAt(0));
    }
  }

  int id(String char) => charToId[char.codeUnitAt(0)];
}
