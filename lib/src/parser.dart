// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expression parser that uses the Shunting-yard algorithm.
/// This is a one-pass, linear-time, linear-space algorithm.
Expr parseExpression(String input, [ExprResolve resolver = eqlibSAResolve]) {
  final output = new List<Expr>();
  final stack = new List<_StackElement>();
  final reader = new _StringReader(input);

  final specialChars = '+-*/^(,)? '.codeUnits;
  final ops = '+-*/^'.codeUnits;
  final opIds = {
    ops[0]: Expr.opAddId,
    ops[1]: Expr.opSubId,
    ops[2]: Expr.opMulId,
    ops[3]: Expr.opDivId,
    ops[4]: Expr.opPowId
  };

  /// Tokens:
  /// - number
  /// - math operator
  /// - function name (or variable)
  /// - parentheses
  /// - argument separator

  final opDist = new W<int>(2);
  var leftPDist = 2, count = 0;
  while (!reader.eof) {
    reader.skipWhitespaces();

    // Try left parenthesis.
    if (reader.currentIs('(')) {
      _detectImplMul(count, opDist, stack, output);

      stack.add(new _StackElement.leftParenthesis());

      // Reset left parenthesis distance.
      leftPDist = 0;

      // Move to next token.
      reader.next();
    }

    // Try right parenthesis.
    else if (reader.currentIs(')')) {
      if (stack.isEmpty) {
        // The stack already ran out without finding a parentheses.
        throw new FormatException('mismatched parentheses');
      }

      // Pop all remaining stack elements.
      while (!stack.last.isLeftParenthesis) {
        _popStack(stack, output);
        if (stack.isEmpty) {
          // If the stack runs out without finding a left parentheses...
          throw new FormatException('mismatched parentheses');
        }
      }

      // Pop the left parenthesis.
      stack.removeLast();

      // If the last element in the stack is a function, pop it.
      if (stack.isNotEmpty && stack.last.isFunction) {
        _popStack(stack, output);
      }

      // Move to next token.
      reader.next();
    }

    // Try argument separator (comma).
    else if (reader.currentIs(',')) {
      // Pop operators.
      while (!stack.last.isLeftParenthesis) {
        _popStack(stack, output);
        if (stack.isEmpty) {
          throw new FormatException('argument separator but no parenthesis');
        }
      }

      // At the top of the stack there should now be a parenthesis, we can
      // increment the argc of the function before it.
      if (stack.length >= 2 && stack.last.isLeftParenthesis) {
        stack[stack.length - 2].argc++;
      } else {
        throw new FormatException('argument separators outside function');
      }

      // Move to next token.
      reader.next();
    }

    // Try math operator.
    else if (reader.currentOneOf(ops)) {
      // Handle unary minus operator by checking if:
      // * the previous token is also an operator
      // * the previous token is a left parenthesis
      // * this is the first token in the string
      var op = opIds[reader.current];
      if (reader.currentIs('-') && opDist.v == 1 ||
          leftPDist == 1 ||
          count == 0) {
        // This is an unary minus.
        op = Expr.opNegId;
      }

      _stackAddOp(op, stack, output);
      opDist.v = 0; // Reset operator distance.

      // Move to next token.
      reader.next();
    }

    // Else try to parse as number and fallback to functions.
    // Note that we have to check for reader.eof here.
    else if (!reader.eof) {
      _detectImplMul(count, opDist, stack, output);

      // Find number token.
      var startPtr = reader.ptr;
      var nonDigits = 0;

      // Note that there can not be a negate sign here, since that would have
      // been parsed as minus operator, or as an unary minus.

      reader.skipDigits(); // Take any number of digits.

      // If this is a decimal point, skip it and any numbers following it.
      if (reader.currentIs('.')) {
        nonDigits++;
        reader.next();
        reader.skipDigits();
      }

      // The number is terminated here, check if a number was consumed:
      // The difference between the current pointer and the start position must
      // be at least one digit.
      if (reader.ptr - startPtr - nonDigits > 0) {
        // We could parse a scientific notation here.

        // Create string from number segment, and parse.
        final number = num.parse(new String.fromCharCodes(
            reader.data.sublist(startPtr, reader.ptr)));

        // Push to output queue.
        output.add(new NumberExpr(number));

        // Note that we do NOT have to move the pointer here. This is because
        // by skipping digits, we have already moved past this token.
      } else {
        // Interpret as function.
        // If the current character is a question mark, this is a generic symbol
        // or function. We move the startPtr forward to cut it off the token.
        var isGeneric = false;
        if (reader.currentIs('?')) {
          isGeneric = true;
          reader.next();
          startPtr++;
        }

        // Find name termination.
        while (!reader.eof && !reader.currentOneOf(specialChars)) {
          reader.next();
        }
        final fnName =
            new String.fromCharCodes(reader.data.sublist(startPtr, reader.ptr));

        // Note: this is not the most efficient route, but an attempt to make it
        // a bit simpler.
        var isSymbol = true;
        if (reader.currentOneOf(' ('.codeUnits)) {
          reader.skipWhitespaces();
          if (reader.currentIs('(')) {
            reader.skipWhitespaces();
            if (!reader.currentIs(')')) {
              // This is defenitely a function with arguments.
              isSymbol = false;

              // Move to next token (we already moved beyond the left
              // parenthesis token to see if there are function arguments,
              // therefore we have to handle it here).
              reader.next();
            }
          }
        }

        // Process token.
        final id = resolver(fnName);
        if (isSymbol) {
          output.add(new SymbolExpr(id, isGeneric));
        } else {
          // We initially expect one argument, this will be incremented when we
          // find argument separators.
          stack.add(new _StackElement(id, isGeneric: isGeneric, argc: 1));

          // Add the left parenthesis here.
          stack.add(new _StackElement.leftParenthesis());

          // Reset left parenthesis distance.
          leftPDist = 0;
        }

        // We do NOT have to move the pointer here. By skipping characters
        // untill we encountered a special character we are already at the next
        // token.
      }
    }

    count++;
    opDist.v++;
    leftPDist++;
  }

  // Drain stack.
  while (stack.isNotEmpty) {
    _popStack(stack, output);
  }

  if (output.length > 1) {
    throw new FormatException('stack mismatch: ${output.join(', ')}');
  }
  return output.last;
}

final _opImplMulId = Expr.opNegId + 1;
final _opArgc = {
  Expr.opAddId: 2,
  Expr.opSubId: 2,
  Expr.opMulId: 2,
  Expr.opDivId: 2,
  Expr.opPowId: 2,
  Expr.opNegId: 1,
  _opImplMulId: 2
};
final _opPrecedence = {
  Expr.opAddId: 1,
  Expr.opSubId: 1,
  Expr.opMulId: 2,
  Expr.opDivId: 2,
  Expr.opPowId: 3,
  Expr.opNegId: 4,
  _opImplMulId: 3
};
final _opLeftAssoc = {
  Expr.opAddId: true,
  Expr.opSubId: true,
  Expr.opMulId: true,
  Expr.opDivId: true,
  Expr.opPowId: false,
  Expr.opNegId: false,
  _opImplMulId: false
};

/// Detect implicit multiplication.
void _detectImplMul(
    int count, W<int> opDist, List<_StackElement> stack, List<Expr> output) {
  // Implicit multiplication if all are true:
  // * This is not the first token
  // * The previous token is not an operator
  // * The last element in the stack is not a left parenthesis
  if (count > 0 &&
      opDist.v != 1 &&
      (stack.isEmpty || !stack.last.isLeftParenthesis)) {
    _stackAddOp(_opImplMulId, stack, output);

    // Note that we do NOT have to set the operator distance here. We
    // can set it to 1: since we have added an operator and are already
    // processing the next token, the distance is equal to 1.
    // However, this is not neccesary since opDist is only used to check
    // if the distance is not equal to one, and once it leaves this loop
    // it will be incremented to 2. It is not possible for the operator
    // distance to be 0 at this point.
    opDist.v = 1; // Clean, but currently unnecessary.
  }
}

/// Add operator to the [stack].
void _stackAddOp(int op, List<_StackElement> stack, List<Expr> output) {
  // First drain the stack according the algorithm rules.
  //
  // Note: this boolean statement is partially collapsed into a shorter form:
  // ((opLeftAssoc[id] && opPrecedence[id] <= opPrecedence[stack.last.id])||
  //  (!opLeftAssoc[id] && opPrecedence[id] < opPrecedence[stack.last.id]))
  // Into: opPrecedence[id] < opPrecedence[stack.last.id] +
  //  (opLeftAssoc[id] ? 1 : 0)
  final myPre = _opPrecedence[op];
  final assocAdd = _opLeftAssoc[op] ? 1 : 0;
  while (stack.isNotEmpty &&
      stack.last.isOperator &&
      myPre < _opPrecedence[stack.last.id] + assocAdd) {
    // Pop operator (it precedes the current one).
    _popStack(stack, output);
  }

  // Add operator to stack.
  stack.add(new _StackElement(op, isOperator: true, argc: _opArgc[op]));
}

/// Pop and process element from the [stack].
/// This function should not be called to remove left parentheses.
/// (if there are still left parentheses left, there is a mismatch)
void _popStack(List<_StackElement> stack, List<Expr> output) {
  final fn = stack.removeLast();
  final args = new List<Expr>.generate(fn.argc, (_) => output.removeLast(),
      growable: false);

  // If this is a negate function, and the argument is a number, we directly
  // apply it.
  final first = args.first;
  if (fn.id == Expr.opNegId && first is NumberExpr) {
    output.add(new NumberExpr(-first.value));
  } else {
    final id = fn.id == _opImplMulId ? Expr.opMulId : fn.id;
    // Note: the argument list is reversed because they have been added to the
    // stack in first in last out order (because of List.removeLast()).
    output.add(new FunctionExpr(id, args.reversed.toList(), fn.isGeneric));
  }
}

/// Utility for [parseExpression].
class _StringReader {
  static const zeroAsciiCode = 48;
  static const nineAsciiCode = 57;

  /// UTF16 string data
  final List<int> data;

  /// String element pointer
  int ptr = 0;

  _StringReader(String str) : data = str.codeUnits;

  /// Get current character code.
  int get current => data[ptr];

  /// Test if current character is equal to the current character in the given
  /// string.
  bool currentIs(String char) => !eof && current == char.codeUnitAt(0);

  /// Test if the current character is a decimal digit (0-9).
  bool currentIsDigit() =>
      !eof && current >= zeroAsciiCode && current <= nineAsciiCode;

  /// Test if the current character is contained in the given array.
  bool currentOneOf(List<int> array) => !eof && array.contains(current);

  /// Skip all white spaces.
  int skipWhitespaces() {
    var i = 0;
    while (currentIs(' ')) {
      next();
      i++;
    }
    return i;
  }

  /// Proceed while current is a digit.
  void skipDigits() {
    while (currentIsDigit()) {
      next();
    }
  }

  /// Move to next character.
  int next() {
    assert(!eof);
    return ++ptr;
  }

  /// Check if the reader is at the end of the input string.
  bool get eof => ptr == data.length;
}

/// Element in parsing stack.
class _StackElement {
  static const leftParenthesisId = -1;

  final int id;
  int argc = 0;
  final bool isGeneric, isOperator;

  _StackElement(this.id,
      {this.argc: 0, this.isGeneric: false, this.isOperator: false});

  factory _StackElement.leftParenthesis() =>
      new _StackElement(leftParenthesisId);

  bool get isLeftParenthesis => id == leftParenthesisId;
  bool get isFunction => !isOperator && !isLeftParenthesis;

  @override
  String toString() => isLeftParenthesis ? ')' : 'fn#$id';
}
