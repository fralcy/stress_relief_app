import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get user's document reference
  DocumentReference? get _userDoc {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  // Get last synced timestamp from cloud
  Future<DateTime?> _getCloudLastSyncedAt() async {
    if (_userDoc == null) return null;
    
    try {
      final doc = await _userDoc!.get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>?;
      final timestamp = data?['lastSyncedAt'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      print('Error getting cloud timestamp: $e');
      return null;
    }
  }

  // TODO
  Future<void> smartSync() async {
    if (!_authService.isLoggedIn) {
      throw 'Please login first to sync';
    }
    
    print('Smart sync coming soon...');
  }

  // TODO
  Future<void> uploadToCloud() async {
    print('Upload to cloud coming soon...');
  }

  // TODO
  Future<void> downloadFromCloud() async {
    print('Download from cloud coming soon...');
  }
}