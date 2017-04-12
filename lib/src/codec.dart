// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Codec data
/// Note: functions can have no more than 255 arguments.
///
/// The expression numbering system has the following order:
/// generic functions < functions < integers < floating points.
class ExprCodecData {
  int genericCount;
  final List<double> floatingPoints;
  final List<int> integers;
  final List<int> functionIds;
  final List<int> functionArgcs;
  final List<int> expression;

  ExprCodecData(this.genericCount, this.floatingPoints, this.integers,
      this.functionIds, this.functionArgcs, this.expression);

  factory ExprCodecData.empty() => new ExprCodecData(0, new List<double>(),
      new List<int>(), new List<int>(), new List<int>(), new List<int>());

  factory ExprCodecData.decodeHeader(ByteBuffer buffer) {
    final headerDimensions = new Uint16List.view(buffer, 0, 4);

    // Header parameters
    final floatCount = headerDimensions[0]; // Number of 64bit floats
    final integerCount = headerDimensions[1]; // Number of 32bit integers
    final functionCount = headerDimensions[2]; // Number of functions
    final genericCount = headerDimensions[3]; // Number of generic functions

    // Data views
    var offset = 8;
    final floatView = new Float64List.view(buffer, offset, floatCount);
    offset += floatView.lengthInBytes;
    final integerView = new Int32List.view(buffer, offset, integerCount);
    offset += integerView.lengthInBytes;
    final functionIdView = new Uint32List.view(buffer, offset, functionCount);
    offset += functionIdView.lengthInBytes;
    final functionArgcView = new Uint16List.view(buffer, offset, functionCount);
    offset += functionArgcView.lengthInBytes;

    List<int> dataView;
    if (floatCount + integerCount + functionCount > 255) {
      // Note: because we use uint16 for the argument count the reading frame
      // is already aligned.
      dataView = new Uint16List.view(buffer, offset); // Use 16 bit decoding.
    } else {
      dataView = new Uint8List.view(buffer, offset); // Use 8 bit decoding.
    }

    return new ExprCodecData(genericCount, floatView, integerView,
        functionIdView, functionArgcView, dataView);
  }

  bool containsFloats() => floatingPoints.isNotEmpty;

  int get floatCount => floatingPoints.length;
  int get integerCount => integers.length;
  int get functionCount => functionIds.length;

  ByteBuffer writeToBuffer() {
    // Compute buffer length.
    final headerSize = 4 * Uint16List.BYTES_PER_ELEMENT +
        floatCount * Float64List.BYTES_PER_ELEMENT +
        integerCount * Int32List.BYTES_PER_ELEMENT +
        functionIds.length * Uint32List.BYTES_PER_ELEMENT +
        functionArgcs.length * Uint16List.BYTES_PER_ELEMENT;

    // Allocate buffer.
    final u16 = floatCount + integerCount + functionCount > 255;
    final buffer =
        new ByteData(headerSize + expression.length * (u16 ? 2 : 1)).buffer;

    // Copy all data into buffer using views.
    final headerDimensions = new Uint16List.view(buffer, 0, 4);
    headerDimensions[0] = floatCount;
    headerDimensions[1] = integerCount;
    headerDimensions[2] = functionCount;
    headerDimensions[3] = genericCount;

    var offset = 8;
    final floatView = new Float64List.view(buffer, offset, floatCount);
    floatView.setAll(0, floatingPoints);
    offset += floatView.lengthInBytes;
    final integerView = new Int32List.view(buffer, offset, integerCount);
    integerView.setAll(0, integers);
    offset += integerView.lengthInBytes;
    final functionIdView = new Uint32List.view(buffer, offset, functionCount);
    functionIdView.setAll(0, functionIds);
    offset += functionIdView.lengthInBytes;
    final functionArgcView = new Uint16List.view(buffer, offset, functionCount);
    functionArgcView.setAll(0, functionArgcs);

    final dataView = u16
        ? new Uint16List.view(buffer, headerSize)
        : new Uint8List.view(buffer, headerSize);
    dataView.setAll(0, expression);

    return buffer;
  }

  void storeNumber(num value) {
    if (value is int) {
      if (value < -2147483648 || value > 2147483647) {
        throw new ArgumentError.value(
            value, 'value', 'must be [-2147483648, 2147483647]');
      }
      if (!integers.contains(value)) {
        integers.add(value);
      }
    } else {
      if (!floatingPoints.contains(value)) {
        floatingPoints.add(value);
      }
    }
  }

  int getNumberRef(num value) {
    if (value is int) {
      return functionCount + integers.indexOf(value);
    } else {
      return functionCount + integerCount + floatingPoints.indexOf(value);
    }
  }

  void storeFunction(int id, int argc, bool generic) {
    if (id < 0 || id > 4294967295) {
      throw new ArgumentError.value(id, 'id', 'must be [0, 4294967295]');
    } else if (argc > 65536) {
      throw new ArgumentError.value(argc, 'argc', 'must be [0, 65536]');
    } else if (getFunctionRef(id, argc, generic) == -1) {
      if (generic) {
        functionIds.insert(genericCount, id);
        functionArgcs.insert(genericCount, argc);
        genericCount++;
      } else {
        functionIds.add(id);
        functionArgcs.add(argc);
      }
    }
  }

  int getFunctionRef(int id, int argc, bool generic) {
    final idx = functionIds.indexOf(id);
    if (idx != -1 &&
        (functionArgcs[idx] != argc || generic != (idx < genericCount))) {
      throw new ArgumentError('same function ID has different parameters');
    }
    return idx;
  }

  /// Check if the given index points to a function.
  bool inFunctionRange(int index) => index < functionCount;

  /// Check if the given index points to a generic function.
  bool inGenericRange(int index) => index < genericCount;
}

ExprCodecData exprCodecEncode(Expr expr) {
  final data = new ExprCodecData.empty();
  _exprCodecEncodePass1(data, expr);
  _exprCodecEncodePass2(data, expr);
  return data;
}

void _exprCodecEncodePass1(ExprCodecData data, Expr expr) {
  if (expr is NumberExpr) {
    data.storeNumber(expr.value);
  } else if (expr is FunctionExpr) {
    data.storeFunction(expr.id, expr.arguments.length, expr.isGeneric);
    for (final arg in expr.arguments) {
      _exprCodecEncodePass1(data, arg);
    }
  }
}

/// Note: this cannot be done in one pass since the ID if non-generic functions
/// is not known. It would be possible to adapt the retrieval process (two
/// function indices instead of one), but two passes seems an ok solution.
void _exprCodecEncodePass2(ExprCodecData data, Expr expr) {
  if (expr is NumberExpr) {
    data.expression.add(data.getNumberRef(expr.value));
  } else if (expr is FunctionExpr) {
    data.expression.add(
        data.getFunctionRef(expr.id, expr.arguments.length, expr.isGeneric));
    for (final arg in expr.arguments) {
      _exprCodecEncodePass2(data, arg);
    }
  }
}

/// Decode byte buffer into expression object. Expects a data object with an
/// already decoded header.
Expr exprCodecDecode(ExprCodecData data) =>
    _exprCodecDecode(new W<int>(0), data);

/// Note: this function does not perform sanity checks, and is unsafe on corrupt
/// data arrays.
Expr _exprCodecDecode(W<int> ptr, ExprCodecData data) {
  int value = data.expression[ptr.v++];
  if (data.inFunctionRange(value)) {
    final id = data.functionIds[value];
    final generic = data.inGenericRange(value);

    // If there are function arguments, collect those first.
    final argc = data.functionArgcs[value];
    if (argc > 0) {
      final args = new List<Expr>.generate(
          argc, (i) => _exprCodecDecode(ptr, data),
          growable: false);
      return new FunctionExpr(id, generic, args);
    } else {
      return new FunctionExpr(id, generic, []);
    }
  }

  value -= data.functionCount;
  if (value < data.integerCount) {
    return new NumberExpr(data.integers[value]);
  }
  value -= data.integerCount;
  if (value < data.floatCount) {
    return new NumberExpr(data.floatingPoints[value]);
  }

  // Illegal value: it is not within the frame of the given input tables.
  throw new ArgumentError('codec input buffer data is corrupted');
}
