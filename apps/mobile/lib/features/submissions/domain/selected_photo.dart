import 'dart:typed_data';

class SelectedPhoto {
  const SelectedPhoto({
    required this.fileName,
    required this.bytes,
    this.sourcePath,
  });

  final String fileName;
  final Uint8List bytes;
  final String? sourcePath;
}
