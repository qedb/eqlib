// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expression ID for implicit multiplication.
final opImplMultiplyId = Expr.opNegateId + 1;

enum Associativity { ltr, rtl }

/// Operator configuration
class OperatorConfig {
  final charToId = new Map<int, int>();
  final idToArgc = new Map<int, int>();
  final idToPrecedence = new Map<int, int>();
  final idToAssociativity = new Map<int, Associativity>();

  OperatorConfig() {
    // Load default settings.
    add(Associativity.ltr, argc: 2, lvl: 1, char: '+', id: Expr.opAddId);
    add(Associativity.ltr, argc: 2, lvl: 1, char: '-', id: Expr.opSubtractId);
    add(Associativity.ltr, argc: 2, lvl: 2, char: '*', id: Expr.opMultiplyId);
    add(Associativity.ltr, argc: 2, lvl: 2, char: '/', id: Expr.opDivideId);
    add(Associativity.rtl, argc: 2, lvl: 3, char: '^', id: Expr.opPowerId);

    /// Implicit multiplication is set to right associativity by default so that
    /// expressions like these can be written: `a^2b` (which would otherwise be
    /// parsed as `(a^2)*b`).
    /// Increasing the precedence level is not an option, this would result in:
    /// `2a^b` => `(2*a)^b`.
    add(Associativity.rtl, argc: 2, lvl: 3, id: opImplMultiplyId);

    add(Associativity.rtl, argc: 1, lvl: 4, id: Expr.opNegateId);
  }

  void add(Associativity associativity,
      {String char: '', int argc: 0, int lvl: 0, int id: 0}) {
    idToArgc[id] = argc;
    idToPrecedence[id] = lvl;
    idToAssociativity[id] = associativity;
    if (char.isNotEmpty) {
      charToId[char.codeUnitAt(0)] = id;
    }
  }
}

/// Expression parser that uses the Shunting-yard algorithm.
/// This is a one-pass, linear-time, linear-space algorithm.
Expr parseExpression(String input,
    {OperatorConfig config: null, ExprResolve resolver: eqlibSAResolve}) {
  if (input.isEmpty) {
    throw new FormatException('input cannot be empty');
  }

  final output = new List<Expr>();
  final stack = new List<_StackElement>();
  final reader = new StringReader(input);

  // Process operator config.
  final ops = config != null ? config : new OperatorConfig();
  final opChars = ops.charToId.keys.toList();
  final specialChars = '(,)? '.codeUnits.toList();
  specialChars.addAll(opChars);

  /// Tokens:
  /// - number
  /// - math operator
  /// - function name (or variable)
  /// - parentheses
  /// - argument separator

  final opDist = new W<int>(2);

  // Distance in tokens between the beginning of the current block + 1
  // (whole equation, argument list argument, parentheses block)
  var blockStartDist = 1;

  while (!reader.eof) {
    reader.skipWhitespaces();

    // Try left parenthesis.
    if (reader.currentIs('(')) {
      _detectImplMul(opDist, blockStartDist, stack, output, ops);

      stack.add(new _StackElement.leftParenthesis());

      // Reset left block start distance.
      blockStartDist = 0;

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
      // If stack is already empty, also throw an error.
      if (stack.isEmpty) {
        throw new FormatException('argument separator but no parenthesis');
      }

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

      // Rest block start distance.
      blockStartDist = 0;

      // Move to next token.
      reader.next();
    }

    // Try math operator.
    else if (reader.currentOneOf(opChars)) {
      // Handle unary minus operator by checking if:
      // * the previous token is also an operator
      // * this is the first token in the current block
      var op = ops.charToId[reader.current];
      if (reader.currentIs('-') && opDist.v == 1 || blockStartDist == 1) {
        // This is an unary minus.
        op = Expr.opNegateId;
      }

      _stackAddOp(op, stack, output, ops);
      opDist.v = 0; // Reset operator distance.

      // Move to next token.
      reader.next();
    }

    // Else try to parse as number and fallback to functions.
    // Note that we have to check for reader.eof here.
    else if (!reader.eof) {
      _detectImplMul(opDist, blockStartDist, stack, output, ops);

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
        var generic = false;
        if (reader.currentIs('?')) {
          generic = true;
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
        final id = resolver(fnName, generic);
        if (isSymbol) {
          output.add(new SymbolExpr(id, generic));
        } else {
          // We initially expect one argument, this will be incremented when we
          // find argument separators.
          stack.add(new _StackElement(id, generic: generic, argc: 1));

          // Add the left parenthesis here.
          stack.add(new _StackElement.leftParenthesis());

          // Reset block start distance.
          blockStartDist = 0;
        }

        // We do NOT have to move the pointer here. By skipping characters
        // untill we encountered a special character we are already at the next
        // token.
      }
    }

    opDist.v++;
    blockStartDist++;
  }

  // Drain stack.
  while (stack.isNotEmpty) {
    _popStack(stack, output);
  }

  // This should always be true. If there is a formatting error it will be
  // detected earlier.
  assert(output.length == 1);

  return output.last;
}

/// Detect implicit multiplication.
void _detectImplMul(W<int> opDist, int blockStartDist,
    List<_StackElement> stack, List<Expr> output, OperatorConfig ops) {
  // Implicit multiplication if all are true:
  // * This is not the first token in the current block
  // * The previous token is not an operator
  if (blockStartDist != 1 && opDist.v != 1) {
    _stackAddOp(opImplMultiplyId, stack, output, ops);

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
void _stackAddOp(
    int op, List<_StackElement> stack, List<Expr> output, OperatorConfig ops) {
  // First drain the stack according the algorithm rules.
  //
  // Note: this boolean statement is partially collapsed into a shorter form:
  // ((opLeftAssoc[id] && opPrecedence[id] <= opPrecedence[stack.last.id])||
  //  (!opLeftAssoc[id] && opPrecedence[id] < opPrecedence[stack.last.id]))
  // Into: opPrecedence[id] < opPrecedence[stack.last.id] +
  //  (opLeftAssoc[id] ? 1 : 0)
  final myPre = ops.idToPrecedence[op];
  final assocAdd = ops.idToAssociativity[op] == Associativity.ltr ? 1 : 0;
  while (stack.isNotEmpty &&
      stack.last.isOperator &&
      myPre < ops.idToPrecedence[stack.last.id] + assocAdd) {
    // Pop operator (it precedes the current one).
    _popStack(stack, output);
  }

  // Add operator to stack.
  stack.add(new _StackElement(op, isOperator: true, argc: ops.idToArgc[op]));
}

/// Pop and process element from the [stack].
/// This function should not be called to remove left parentheses.
/// (if there are still left parentheses left, there is a mismatch)
void _popStack(List<_StackElement> stack, List<Expr> output) {
  final fn = stack.removeLast();

  // Check if arguments are in the stack.
  if (output.length < fn.argc) {
    throw new FormatException(
        'stack function arguments are not in the output queue');
  }

  final args = new List<Expr>.generate(fn.argc, (_) => output.removeLast(),
      growable: false);

  // If this is a negate function, and the argument is a number, we directly
  // apply it.
  final first = args.first;
  if (fn.id == Expr.opNegateId && first is NumberExpr) {
    output.add(new NumberExpr(-first.value));
  } else {
    final id = fn.id == opImplMultiplyId ? Expr.opMultiplyId : fn.id;
    // Note: the argument list is reversed because they have been added to the
    // stack in first in last out order (because of List.removeLast()).
    output.add(new FunctionExpr(id, args.reversed.toList(), fn.generic));
  }
}

/// Element in parsing stack.
class _StackElement {
  static const leftParenthesisId = -1;

  final int id;
  int argc = 0;
  final bool generic, isOperator;

  _StackElement(this.id,
      {this.argc: 0, this.generic: false, this.isOperator: false});

  factory _StackElement.leftParenthesis() =>
      new _StackElement(leftParenthesisId);

  bool get isLeftParenthesis => id == leftParenthesisId;
  bool get isFunction => !isOperator && !isLeftParenthesis;

  //@override
  //String toString() => isLeftParenthesis ? ')' : 'fn#$id';
}
