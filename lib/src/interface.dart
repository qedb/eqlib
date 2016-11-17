// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Function that resolves an expression string into an expression ID.
typedef int ExprResolve(String name);

/// Function taht returns the expression name for the given expression ID.
typedef String ExprResolveName(int id);

/// Function that should compute a numeric value for the given expression ID
/// and arguments.
typedef num ExprCompute(int id, List<num> args);

/// Function that can lookup whether a given expression can be computed.
typedef bool ExprCanCompute(int id);

/// String printing entry function.
typedef String ExprPrint(Expr expr);
