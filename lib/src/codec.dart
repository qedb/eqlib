// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Codec data
/// Note: function argument lists are limited to uint8 storage.
class ExprCodecData {
  int genericCount;
  final List<double> float64List;
  final List<int> functionId;
  final List<int> functionArgc;
  final List<int> int8List;
  final List<int> data;

  ExprCodecData(this.genericCount, this.float64List, this.functionId,
      this.functionArgc, this.int8List, this.data);

  factory ExprCodecData.empty() => new ExprCodecData(0, new List<double>(),
      new List<int>(), new List<int>(), new List<int>(), new List<int>());

  factory ExprCodecData.decodeHeader(ByteBuffer buffer) {
    final headerView = new Uint16List.view(buffer, 0, 4);

    // Header parameters
    final functionCount = headerView[0]; // Number of functions
    final genericCount = headerView[1]; // Number of functions that are generic
    final int8Count = headerView[2]; // Number of 8bit ints
    final float64Count = headerView[3]; // Number of 64bit floats

    // Data views
    var offset = 8;
    final float64View = new Float64List.view(buffer, offset, float64Count);
    offset += float64View.lengthInBytes;
    final functionIdView = new Uint32List.view(buffer, offset, functionCount);
    offset += functionIdView.lengthInBytes;
    final functionArgcView = new Uint8List.view(buffer, offset, functionCount);
    offset += functionArgcView.lengthInBytes;
    final int8View = new Int8List.view(buffer, offset, int8Count);
    offset += int8View.lengthInBytes;

    List<int> dataView;
    if (functionCount + int8Count + float64Count > 256) {
      // Allign offset with 16 bit reading frame.
      if (offset % 2 != 0) {
        offset++;
      }

      dataView = new Uint16List.view(buffer, offset); // Use 16 bit decoding.
    } else {
      dataView = new Uint8List.view(buffer, offset); // Use 8 bit decoding.
    }

    return new ExprCodecData(genericCount, float64View, functionIdView,
        functionArgcView, int8View, dataView);
  }

  int get functionCount => functionId.length;
  int get int8Count => int8List.length;
  int get float64Count => float64List.length;

  ByteBuffer writeToBuffer() {
    // Compute buffer length.
    var dataOffset = 4 * Uint16List.BYTES_PER_ELEMENT +
        float64Count * Float64List.BYTES_PER_ELEMENT +
        functionCount *
            (Uint32List.BYTES_PER_ELEMENT + Uint8List.BYTES_PER_ELEMENT) +
        int8Count * Int8List.BYTES_PER_ELEMENT;
    final u16 = functionCount + int8Count + float64Count > 256;
    if (u16 && dataOffset % 2 != 0) {
      dataOffset++;
    }

    // Allocate buffer.
    final buffer =
        new ByteData(dataOffset + data.length * (u16 ? 2 : 1)).buffer;

    // Copy all data into buffer using views.
    final headerView = new Uint16List.view(buffer, 0, 4);
    headerView[0] = functionCount;
    headerView[1] = genericCount;
    headerView[2] = int8Count;
    headerView[3] = float64Count;

    var offset = 8;
    final float64View = new Float64List.view(buffer, offset, float64Count);
    float64View.setAll(0, float64List);
    offset += float64View.lengthInBytes;
    final functionIdView = new Uint32List.view(buffer, offset, functionCount);
    functionIdView.setAll(0, functionId);
    offset += functionIdView.lengthInBytes;
    final functionArgcView = new Uint8List.view(buffer, offset, functionCount);
    functionArgcView.setAll(0, functionArgc);
    offset += functionArgcView.lengthInBytes;
    final int8View = new Int8List.view(buffer, offset, int8Count);
    int8View.setAll(0, int8List);

    final dataView = u16
        ? new Uint16List.view(buffer, dataOffset)
        : new Uint8List.view(buffer, dataOffset);
    dataView.setAll(0, data);

    // Return buffer.
    return buffer;
  }

  void storeNumber(num value) {
    if (value is int && value >= -128 && value < 128) {
      // Store in Int8List.
      if (!int8List.contains(value)) {
        int8List.add(value);
      }
    } else {
      // Store in Float64List
      if (!float64List.contains(value)) {
        float64List.add(value);
      }
    }
  }

  int getNumberRef(num value) {
    if (value is int && value >= -128 && value < 128) {
      return functionCount + int8List.indexOf(value);
    } else {
      return functionCount + int8Count + float64List.indexOf(value);
    }
  }

  void storeFunction(int id, int argCount, bool generic) {
    if (getFunctionRef(id, argCount, generic) == -1) {
      if (generic) {
        functionId.insert(genericCount, id);
        functionArgc.insert(genericCount, argCount);
        genericCount++;
      } else {
        functionId.add(id);
        functionArgc.add(argCount);
      }
    }
  }

  int getFunctionRef(int id, int argCount, bool generic) {
    var idx = (generic ? 0 : genericCount) - 1;
    do {
      // Advance offset to new starting point.
      final offset = idx + 1;
      if (idx >= (generic ? genericCount : functionCount) - 1) {
        return -1;
      }

      idx = functionId.indexOf(id, offset);

      // No element found
      if (idx == -1) {
        return -1;
      }
    } while (functionArgc[idx] != argCount);
    return idx;
  }

  void add(int id) => data.add(id);

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

void _exprCodecEncodePass2(ExprCodecData data, Expr expr) {
  if (expr is NumberExpr) {
    data.add(data.getNumberRef(expr.value));
  } else if (expr is FunctionExpr) {
    data.add(
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
  int value = data.data[ptr.v++];
  if (data.inFunctionRange(value)) {
    final generic = data.inGenericRange(value);

    // If there are function arguments, collect those first.
    final argCount = data.functionArgc[value];
    if (argCount > 0) {
      final args = new List<Expr>.generate(
          argCount, (i) => _exprCodecDecode(ptr, data),
          growable: false);
      return new FunctionExpr(data.functionId[value], generic, args);
    } else {
      return new FunctionExpr(data.functionId[value], generic, []);
    }
  }

  value -= data.functionCount;
  if (value < data.int8Count) {
    return new NumberExpr(data.int8List[value]);
  }
  value -= data.int8Count;
  if (value < data.float64Count) {
    return new NumberExpr(data.float64List[value]);
  }

  // Illegal value: it is not within the frame of the given input tables.
  throw new ArgumentError('codec input buffer data is corrupted');
}
