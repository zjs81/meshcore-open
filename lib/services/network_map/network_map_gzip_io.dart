import 'dart:io';

List<int>? gzipEncode(List<int> bytes) => gzip.encode(bytes);
