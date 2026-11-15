import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Abstraksi berkas gambar yang dipilih dari folder lokal.
class LocalPickedImage {
  final String name;
  final int? sizeBytes;
  final Future<Uint8List> Function() readBytes;

  const LocalPickedImage({
    required this.name,
    this.sizeBytes,
    required this.readBytes,
  });
}

/// Hasil pemilihan gambar foto profil dari folder lokal.
class ProfilePhotoPickResult {
  final Uint8List? bytes;
  final String? fileName;
  final String? errorMessage;
  final bool cancelled;

  const ProfilePhotoPickResult({
    this.bytes,
    this.fileName,
    this.errorMessage,
    this.cancelled = false,
  });

  bool get hasImage => bytes != null && bytes!.isNotEmpty;
}

/// Service lintas platform (Android, Web, Desktop) untuk mengimpor foto
/// profil dari folder lokal perangkat menggunakan [FilePicker].
class ProfilePhotoService {
  static const int maxFileSizeBytes = 15 * 1024 * 1024; // 15 MB

  final Future<LocalPickedImage?> Function() _picker;

  ProfilePhotoService({Future<LocalPickedImage?> Function()? picker})
    : _picker = picker ?? _defaultPicker;

  static Future<LocalPickedImage?> _defaultPicker() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Pilih Foto Profil dari Folder Lokal',
      type: FileType.image,
    );
    if (picked == null) return null;
    return LocalPickedImage(
      name: picked.name,
      sizeBytes: picked.lengthSync(),
      readBytes: picked.readAsBytes,
    );
  }

  /// Membuka pemilih berkas lokal dan membaca bytes gambar dengan aman.
  Future<ProfilePhotoPickResult> pickFromLocalFolder() async {
    try {
      final picked = await _picker();
      if (picked == null) {
        return const ProfilePhotoPickResult(cancelled: true);
      }

      final knownLength = picked.sizeBytes;
      if (knownLength != null && knownLength > maxFileSizeBytes) {
        return const ProfilePhotoPickResult(
          errorMessage: 'Ukuran gambar terlalu besar (maksimal 15 MB).',
        );
      }

      final bytes = await picked.readBytes();
      if (bytes.isEmpty) {
        return const ProfilePhotoPickResult(
          errorMessage: 'Berkas gambar kosong atau tidak dapat dibaca.',
        );
      }
      if (bytes.length > maxFileSizeBytes) {
        return const ProfilePhotoPickResult(
          errorMessage: 'Ukuran gambar terlalu besar (maksimal 15 MB).',
        );
      }

      return ProfilePhotoPickResult(bytes: bytes, fileName: picked.name);
    } catch (_) {
      return const ProfilePhotoPickResult(
        errorMessage:
            'Gagal mengimpor gambar dari folder lokal. Pastikan berkas berformat gambar yang valid.',
      );
    }
  }
}
