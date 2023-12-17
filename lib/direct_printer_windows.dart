// lib/direct_printer_windows.dart
library direct_printer_windows;

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class DirectPrinterWindows {
  static void printText(String printerName, String text) {
    final hPrinter = _openPrinter(printerName);

    try {
      final documentName = TEXT('Print Document');
      final data = TEXT(text);

      final docInfo = DOC_INFO_1.allocate()
        ..pDocName = documentName
        ..pOutputFile = nullptr
        ..pDatatype = TEXT('RAW');

      final pData = _stringToPointer(data);

      try {
        StartDocPrinter(hPrinter, 1, docInfo.addressOf);
        StartPagePrinter(hPrinter);

        final bytesWritten = allocate<Uint32>();
        WritePrinter(hPrinter, pData, text.length, bytesWritten);

        EndPagePrinter(hPrinter);
        EndDocPrinter(hPrinter);
      } finally {
        free(pData);
      }
    } finally {
      _closePrinter(hPrinter);
    }
  }

  static IntPtr _openPrinter(String printerName) {
    final printerNamePtr = TEXT(printerName);
    final phPrinter = allocate<IntPtr>();

    if (OpenPrinter(printerNamePtr, phPrinter, nullptr) == 0) {
      throw Exception('Failed to open printer');
    }

    return phPrinter.value;
  }

  static void _closePrinter(IntPtr hPrinter) {
    ClosePrinter(hPrinter);
  }

  static Pointer<Utf16> TEXT(String input) {
    return Utf16.toUtf16(input).cast();
  }

  static Pointer<Utf16> _stringToPointer(String input) {
    final encoded = utf8.encode(input);
    final pString = calloc<Uint8>(encoded.length + 1)..asTypedList(encoded.length).setAll(0, encoded);
    return pString.cast();
  }
}

class DOC_INFO_1 extends Struct {
  @Uint32()
  external int pDocName;
  @Uint32()
  external int pOutputFile;
  @Uint32()
  external int pDatatype;
}

void main() {
  // Example usage
  DirectPrinterWindows.printText('YOUR_PRINTER_NAME', 'Hello, Printer!');
}
