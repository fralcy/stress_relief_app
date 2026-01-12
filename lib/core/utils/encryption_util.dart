import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// Utility class for encrypting and decrypting sensitive data
/// Uses UID-derived keys for multi-device sync compatibility
class EncryptionUtil {
  static EncryptionUtil? _instance;
  static EncryptionUtil get instance => _instance ??= EncryptionUtil._();

  EncryptionUtil._();

  Encrypter? _encrypter;
  IV? _iv;
  Key? _key;

  /// Initialize encryption with UID-derived key
  /// Should be called once at app startup with user's Firebase UID
  /// For guest users, pass 'guest' as userId
  void initialize({String? userId}) {
    final uid = userId ?? 'guest';
    _key = _deriveKeyFromUID(uid);
    _iv = _deriveIVFromUID(uid);
    _encrypter = Encrypter(AES(_key!));
  }

  /// Derive deterministic 256-bit key from user ID
  /// Same UID always produces same key (multi-device compatibility)
  Key _deriveKeyFromUID(String userId) {
    // PBKDF2-like derivation with app-specific salt
    const salt = 'stress-relief-app-v1-encryption-salt';
    const iterations = 10000;

    final input = utf8.encode(userId + salt);
    List<int> hash = input;

    // Simple PBKDF2 implementation
    for (int i = 0; i < iterations; i++) {
      hash = sha256.convert(hash).bytes;
    }

    return Key(Uint8List.fromList(hash.sublist(0, 32)));
  }

  /// Derive deterministic IV from user ID
  IV _deriveIVFromUID(String userId) {
    const salt = 'stress-relief-app-v1-iv-salt';
    final input = utf8.encode(userId + salt);
    final hash = sha256.convert(input).bytes;
    return IV(Uint8List.fromList(hash.sublist(0, 16)));
  }

  /// Encrypt a string and return base64 encoded result
  String encryptString(String plainText) {
    _ensureInitialized();
    try {
      if (plainText.isEmpty) return '';

      final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      throw EncryptionException('Failed to encrypt string: $e');
    }
  }

  /// Decrypt a base64 encoded string
  String decryptString(String encryptedData) {
    _ensureInitialized();
    try {
      if (encryptedData.isEmpty) return '';

      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter!.decrypt(encrypted, iv: _iv!);
    } catch (e) {
      throw EncryptionException('Failed to decrypt string: $e');
    }
  }

  /// Ensure encryption is initialized
  void _ensureInitialized() {
    if (!isInitialized) {
      throw EncryptionException('EncryptionUtil not initialized. Call initialize() first.');
    }
  }

  /// Encrypt a JSON object
  String encryptJson(Map<String, dynamic> jsonData) {
    try {
      final jsonString = json.encode(jsonData);
      return encryptString(jsonString);
    } catch (e) {
      throw EncryptionException('Failed to encrypt JSON: $e');
    }
  }

  /// Decrypt to JSON object
  Map<String, dynamic> decryptJson(String encryptedData) {
    try {
      final jsonString = decryptString(encryptedData);
      if (jsonString.isEmpty) return {};

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw EncryptionException('Failed to decrypt JSON: $e');
    }
  }

  /// Encrypt a list of objects that can be serialized to JSON
  String encryptList(List<dynamic> listData) {
    try {
      final jsonString = json.encode(listData);
      return encryptString(jsonString);
    } catch (e) {
      throw EncryptionException('Failed to encrypt list: $e');
    }
  }

  /// Decrypt to list of objects
  List<dynamic> decryptList(String encryptedData) {
    try {
      final jsonString = decryptString(encryptedData);
      if (jsonString.isEmpty) return [];

      return json.decode(jsonString) as List<dynamic>;
    } catch (e) {
      throw EncryptionException('Failed to decrypt list: $e');
    }
  }

  /// Generate a hash of the data for integrity verification
  String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify data integrity using hash
  bool verifyHash(String data, String expectedHash) {
    final actualHash = generateHash(data);
    return actualHash == expectedHash;
  }

  /// Get encryption key as base64 string for backup/restore
  String getKeyAsBase64() {
    _ensureInitialized();
    return _key!.base64;
  }

  /// Get IV as base64 string for backup/restore
  String getIVAsBase64() {
    _ensureInitialized();
    return _iv!.base64;
  }

  /// Initialize with existing key and IV (for restore)
  void initializeWithKeyAndIV(String keyBase64, String ivBase64) {
    _key = Key.fromBase64(keyBase64);
    _iv = IV.fromBase64(ivBase64);
    _encrypter = Encrypter(AES(_key!));
  }

  /// Check if encryption is initialized
  bool get isInitialized {
    return _encrypter != null && _iv != null && _key != null;
  }
}

/// Custom exception for encryption errors
class EncryptionException implements Exception {
  final String message;

  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
