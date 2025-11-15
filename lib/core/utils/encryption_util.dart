import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// Utility class for encrypting and decrypting sensitive data
class EncryptionUtil {
  static EncryptionUtil? _instance;
  static EncryptionUtil get instance => _instance ??= EncryptionUtil._();
  
  EncryptionUtil._();
  
  Encrypter? _encrypter;
  IV? _iv;
  Key? _key;
  
  /// Initialize encryption with a secure key
  /// Should be called once at app startup
  void initialize({String? customKey}) {
    _key = customKey != null 
        ? Key.fromBase64(customKey)
        : _generateKey();
    
    _encrypter = Encrypter(AES(_key!));
    _iv = IV.fromSecureRandom(16);
  }
  
  /// Generate a secure random key for AES encryption
  Key _generateKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(32); // 256-bit key
    for (int i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return Key(keyBytes);
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