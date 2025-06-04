import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 用户资料数据模型
class UserProfile {
  final String uid;
  final String? avatar;
  final String? displayName;
  final String? email;
  final Map<String, dynamic>? businessCard;
  final DateTime? lastUpdated;

  UserProfile({
    required this.uid,
    this.avatar,
    this.displayName,
    this.email,
    this.businessCard,
    this.lastUpdated,
  });

  UserProfile copyWith({
    String? avatar,
    String? displayName,
    String? email,
    Map<String, dynamic>? businessCard,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      uid: uid,
      avatar: avatar ?? this.avatar,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      businessCard: businessCard ?? this.businessCard,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory UserProfile.fromFirebaseUser(User user) {
    return UserProfile(
      uid: user.uid,
      avatar: user.photoURL,
      displayName: user.displayName,
      email: user.email,
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserProfile(
      uid: doc.id,
      avatar: data?['avatar'],
      displayName: data?['displayName'],
      email: data?['email'],
      businessCard: data?['businessCard'],
      lastUpdated: (data?['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// 用户资料状态管理器
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfileNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // 监听认证状态变化
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserProfile(user);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadUserProfile(User user) async {
    try {
      // 从Firestore获取用户资料
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      UserProfile profile;
      if (doc.exists) {
        // 如果Firestore中有数据，合并Firebase Auth和Firestore的信息
        final firestoreData = doc.data() as Map<String, dynamic>;
        profile = UserProfile(
          uid: user.uid,
          // 优先使用Firebase Auth的头像，如果没有则使用Firestore的
          avatar: user.photoURL ?? firestoreData['avatar'],
          // 优先使用Firebase Auth的显示名称
          displayName: user.displayName ?? firestoreData['displayName'],
          // 优先使用Firebase Auth的邮箱
          email: user.email ?? firestoreData['email'],
          businessCard: firestoreData['businessCard'],
          lastUpdated: (firestoreData['updatedAt'] as Timestamp?)?.toDate(),
        );
      } else {
        // 如果Firestore中没有用户资料，使用Firebase Auth的信息
        profile = UserProfile.fromFirebaseUser(user);
      }
      
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // 更新头像
  Future<bool> updateAvatar(String avatarUrl) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // 更新Firestore
      await _firestore.collection('users').doc(currentUser.uid).set({
        'avatar': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 更新Firebase Auth
      await currentUser.updatePhotoURL(avatarUrl);

      // 更新本地状态
      final currentState = state;
      if (currentState is AsyncData<UserProfile?>) {
        final currentProfile = currentState.value;
        if (currentProfile != null) {
          state = AsyncValue.data(currentProfile.copyWith(
            avatar: avatarUrl,
            lastUpdated: DateTime.now(),
          ));
        } else {
          // 如果当前没有profile，创建一个新的
          state = AsyncValue.data(UserProfile(
            uid: currentUser.uid,
            avatar: avatarUrl,
            displayName: currentUser.displayName,
            email: currentUser.email,
            lastUpdated: DateTime.now(),
          ));
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // 更新用户资料
  Future<bool> updateProfile({
    String? displayName,
    String? email,
    Map<String, dynamic>? businessCard,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (email != null) updateData['email'] = email;
      if (businessCard != null) updateData['businessCard'] = businessCard;

      // 更新Firestore
      await _firestore.collection('users').doc(currentUser.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      // 更新Firebase Auth（如果需要）
      if (displayName != null) {
        await currentUser.updateDisplayName(displayName);
      }

      // 更新本地状态
      state.whenData((profile) {
        if (profile != null) {
          state = AsyncValue.data(profile.copyWith(
            displayName: displayName,
            email: email,
            businessCard: businessCard,
            lastUpdated: DateTime.now(),
          ));
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}

// Provider定义
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return UserProfileNotifier();
}); 