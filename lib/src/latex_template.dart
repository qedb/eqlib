// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex;

class LaTeXTemplateToken {
  /// Raw LaTeX text
  final String text;

  /// Parameter index
  final int paramIndex;

  /// Parentheses must be added when the precedence level of the argument is
  /// smaller or equal to this value.
  final int parenthesesPriority;

  /// After rendering, this parameter will be the very first/last thing
  /// (visually) on the initial baseline.
  final bool paramLeftBaseline, paramRightBaseline;

  /// Left/right to this parameter is an imposter expression.
  final bool paramImposterLeft, paramImposterRight;

  LaTeXTemplateToken(this.text,
      [this.paramIndex = -1,
      this.parenthesesPriority = -1,
      this.paramLeftBaseline = false,
      this.paramRightBaseline = false,
      this.paramImposterLeft = false,
      this.paramImposterRight = false]);
}

/// A LaTeX function template is parsed from a string. The string is basically
/// a piece of LaTeX with custom syntax for including parameters within the
/// string. Examples are:
/// - `${.0}+${1(+).}`
/// - `$!-${0(^).}`
/// - `\sin${#0(+).}`
///
/// General syntax:
/// - `$!` at the beginning or end of the string means that no parameter, or
///   expression imposter can be added directly before/after this template
///   without first adding parentheses.
/// - `${...}` is a parameter insertion point
///
/// Parameter settings:
/// - Parameter index
/// - A dot `.` can be used to indicated that the parameter is on the baseline
///   (unlike a power for example) and left or right facing in the template
///   after rendering. The side of the dot with respect to the parameter index
///   indicates which side its about.
/// - A `(...)` can be used to specify that the parameter should be surrounded
///   in parentheses if the argument is an operator with a lower or equal
///   precedence than indicated by the operator character in the parentheses.
/// - A `#` can be used to indicate that the parameter is next to an imposter
///   expression. This means that the LaTeX expression left/right to this
///   parameter may appear as an independant expression, and parentheses should
///   be added around this parameter if it has specified a `$!`.
class LaTeXTemplate {
  final List<LaTeXTemplateToken> tokens;

  /// A parameter can never directly be directly before/after this template
  /// (relevant for multiplication).
  final bool noParamBefore, noParamAfter;

  LaTeXTemplate.fromTokens(this.tokens, this.noParamBefore, this.noParamAfter);
}

LaTeXTemplate parseLaTeXTemplate(String input, OperatorConfig ops) {
  final reader = new StringReader(input);
  final tokens = new List<LaTeXTemplateToken>();
  var noParamBefore = false, noParamAfter = false;

  var aggregatePtr = 0;
  while (!reader.eof) {
    // Skip untill first '$'.
    reader.skip((c) => c != char(r'$'));

    // Index where this parameter token starts (if it is one).
    final paramTokenStartIdx = reader.ptr;

    // Check there are still characters left.
    if (!reader.eof) {
      // Skip `$`.
      reader.next();

      // Token to be added in the end.
      LaTeXTemplateToken token;

      // If the current character is an '!', and this token is in the first or
      // last position in the string, set noParamBefore/After.
      if (reader.currentIs('!')) {
        reader.next();
        if (reader.ptr == 2) {
          noParamBefore = true;
        } else if (reader.eof) {
          noParamAfter = true;
        } else {
          continue;
        }
      } else if (reader.currentIs('{')) {
        reader.next();

        // Parse left indicator.
        final paramLeftBaseline = reader.currentIs('.');
        final paramImposterLeft = reader.currentIs(':');
        reader.nextIf(paramLeftBaseline || paramImposterLeft);

        // Try to parse number.
        final paramIndexStartIdx = reader.ptr;
        reader.skipDigits();
        if (reader.ptr - paramIndexStartIdx > 0) {
          final idxStr = new String.fromCharCodes(
              reader.data.sublist(paramIndexStartIdx, reader.ptr));
          final paramIndex = int.parse(idxStr);

          // Try to find parentheses priority.
          var parenthesesPriority = -1;
          if (reader.currentIs('(')) {
            reader.next();
            final opChar = new String.fromCharCode(reader.current);
            if (reader.nextIs(')')) {
              parenthesesPriority = ops.byChar[char(opChar)].precedenceLevel;
              reader.next();
            }
          }

          // Parse right indicator.
          final paramRightBaseline = reader.currentIs('.');
          final paramImposterRight = reader.currentIs(':');
          reader.nextIf(paramRightBaseline || paramImposterRight);

          // Expect a closing '}' here.
          if (!reader.currentIs('}')) {
            continue;
          }
          reader.next();

          // Create parameter token.
          token = new LaTeXTemplateToken(
              '',
              paramIndex,
              parenthesesPriority,
              paramLeftBaseline,
              paramRightBaseline,
              paramImposterLeft,
              paramImposterRight);
        } else {
          continue;
        }
      }

      // When reaching this point it means something appeared (parameter token
      // or $!), so we need to add the text before this as a raw text token
      // first.

      // Add text before this token to tokens.
      if (paramTokenStartIdx - aggregatePtr > 0) {
        tokens.add(new LaTeXTemplateToken(new String.fromCharCodes(
            reader.data.sublist(aggregatePtr, paramTokenStartIdx))));
      }
      aggregatePtr = reader.ptr;

      // If a token was produced, add it after the text token.
      if (token != null) {
        tokens.add(token);
      }
    }
  }

  // Add final text.
  if (reader.ptr - aggregatePtr > 0) {
    tokens.add(new LaTeXTemplateToken(new String.fromCharCodes(
        reader.data.sublist(aggregatePtr, reader.ptr))));
  }

  return new LaTeXTemplate.fromTokens(tokens, noParamBefore, noParamAfter);
}
