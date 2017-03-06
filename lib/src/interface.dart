// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Function to assign an ID to an expression label.
typedef int ExprAssignId(String label, bool generic);

/// Function to retrieve the expression label for the given ID.
typedef String ExprGetLabel(int id);

/// Function to should compute a numeric value for the given expression ID
/// and arguments.
typedef num ExprCompute(int id, List<num> args);

/// Function to generate a human readable string from the given expression.
typedef String ExprToString(Expr expr);
