// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library eqlib.parser_utils;

/// Class for reading a string character by character.
class StringReader {
  /// UTF16 string data
  final List<int> data;

  /// String element pointer
  int ptr = 0;

  StringReader(String str) : data = str.runes.toList();

  /// Get current character code.
  int get current => data[ptr];

  /// Test if current character is equal to the current character in the given
  /// string.
  bool currentIs(String char) => !eof && current == char.runes.first;

  /// Check if the current character matches the given condition.
  bool checkCurrent(bool condition(int char)) => !eof && condition(current);

  /// Test if the current character is contained in the given array.
  bool currentOneOf(List<int> array) => !eof && array.contains(current);

  /// Skip all characters that match the given condition.
  void skip(bool condition(int char)) {
    while (checkCurrent(condition)) {
      next();
    }
  }

  /// Skip all white spaces.
  void skipWhitespaces() => skip((char) => char == spaceAsciiCode);

  /// Skip all digits.
  void skipDigits() => skip(charIsDigit);

  /// Move to next character.
  int next() {
    assert(!eof);
    return ++ptr;
  }

  /// Shotcut: move to the next position if the given [condition] it true.
  int nextIf(bool condition) {
    return condition ? next() : ptr;
  }

  /// Move to next character and match it against the given string.
  bool nextIs(String char) {
    next();
    return currentIs(char);
  }

  /// Check if the reader is at the end of the input string.
  bool get eof => ptr == data.length;
}

const spaceAsciiCode = 32;
const zeroAsciiCode = 48;
const nineAsciiCode = 57;

/// Test if the given [char] is within the given ASCII range.
bool charIsInRange(int char, int start, int endInclusive) =>
    char >= start && char <= endInclusive;

/// Test if the given [char] is a decimal digit (0-9).
bool charIsDigit(int char) => charIsInRange(char, zeroAsciiCode, nineAsciiCode);
