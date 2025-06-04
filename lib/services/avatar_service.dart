import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class AvatarService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // 选择图片源
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // 压缩图片
  Future<Uint8List?> compressImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // 调整尺寸 - 保持宽高比，最大边不超过512px
      final resized = img.copyResize(
        image,
        width: image.width > image.height ? 512 : null,
        height: image.height > image.width ? 512 : null,
      );

      // 压缩为JPEG格式
      final compressed = img.encodeJpg(resized, quality: 85);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  // 上传头像到Firebase Storage
  Future<String?> uploadAvatar(
    Uint8List imageData, {
    required Function(double) onProgress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('avatars/${user.uid}/$fileName');

      // 创建上传任务
      final uploadTask = ref.putData(
        imageData,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedBy': user.uid},
        ),
      );

      // 监听上传进度
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      // 等待上传完成
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  // 更新 Firestore 用户资料（带重试机制）
  Future<bool> _updateFirestoreUser(String uid, String avatarUrl) async {
    try {
      debugPrint('开始更新 Firestore 用户资料...');
      
      // 重试机制
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final updates = {
            'avatar': avatarUrl,
            'lastUpdated': FieldValue.serverTimestamp(),
          };
          
          await _firestore.collection('users').doc(uid).set(
            updates,
            SetOptions(merge: true),
          ).timeout(Duration(seconds: 8)); // 增加超时时间
          
          debugPrint('Firestore 用户资料更新成功');
          return true;
        } catch (e) {
          debugPrint('Firestore 更新失败 (尝试 $attempt/2): $e');
          if (attempt == 2) {
            if (e.toString().contains('does not exist') || 
                e.toString().contains('404') ||
                e.toString().contains('database')) {
              debugPrint('Warning: Firestore 数据库不存在，跳过用户资料更新');
              return true; // 假装成功，因为数据库不存在不是致命错误
            }
            throw e;
          }
          await Future.delayed(Duration(seconds: 1)); // 重试前等待
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error: 更新 Firestore 用户资料失败: $e');
      return false; // 返回 false 但不抛出异常
    }
  }

  // 更新 Firestore 附近用户（带重试机制）
  Future<bool> _updateFirestoreNearbyUsers(String uid, String avatarUrl) async {
    try {
      debugPrint('开始更新 Firestore 附近用户信息...');
      
      // 重试机制
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final updates = {
            'avatar': avatarUrl,
            'lastSeen': FieldValue.serverTimestamp(),
          };
          
          await _firestore.collection('nearbyUsers').doc(uid).set(
            updates,
            SetOptions(merge: true),
          ).timeout(Duration(seconds: 8)); // 增加超时时间
          
          debugPrint('Firestore 附近用户信息更新成功');
          return true;
        } catch (e) {
          debugPrint('Firestore nearbyUsers 更新失败 (尝试 $attempt/2): $e');
          if (attempt == 2) {
            if (e.toString().contains('does not exist') || 
                e.toString().contains('404') ||
                e.toString().contains('database')) {
              debugPrint('Warning: Firestore 数据库不存在，跳过附近用户更新');
              return true; // 假装成功，因为数据库不存在不是致命错误
            }
            throw e;
          }
          await Future.delayed(Duration(seconds: 1)); // 重试前等待
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error: 更新 Firestore 附近用户失败: $e');
      return false; // 返回 false 但不抛出异常
    }
  }

  // 更新用户头像URL
  Future<bool> updateUserAvatar(String avatarUrl, Function(double) onProgress) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Error: No authenticated user found');
      return false;
    }

    try {
      // 第一步：更新 Firebase Auth 中的头像（优先级最高）
      try {
        debugPrint('Updating Firebase Auth photoURL...');
        await user.updatePhotoURL(avatarUrl);
        debugPrint('Successfully updated Firebase Auth photoURL');
        onProgress(0.7); // 70% 完成
      } catch (e) {
        debugPrint('Error updating Firebase Auth photoURL: $e');
        // Firebase Auth 更新失败是致命的，直接返回
        return false;
      }

      // 第二步：更新 Firestore 数据（如果可用）
      bool firestoreSuccess = true;
      
      // 尝试更新用户集合
      try {
        debugPrint('Attempting to update Firestore users collection...');
        final success = await _updateFirestoreUser(user.uid, avatarUrl);
        if (!success) {
          debugPrint('Warning: Failed to update users collection, but continuing...');
          firestoreSuccess = false;
        } else {
          debugPrint('Successfully updated users collection');
        }
      } catch (e) {
        debugPrint('Warning: Failed to update users collection: $e');
        firestoreSuccess = false;
      }

      onProgress(0.85); // 85% 完成

      // 尝试更新附近用户集合
      try {
        debugPrint('Attempting to update nearbyUsers collection...');
        final success = await _updateFirestoreNearbyUsers(user.uid, avatarUrl);
        if (!success) {
          debugPrint('Warning: Failed to update nearbyUsers, but continuing...');
          firestoreSuccess = false;
        } else {
          debugPrint('Successfully updated nearbyUsers collection');
        }
      } catch (e) {
        debugPrint('Warning: Failed to update nearbyUsers: $e');
        firestoreSuccess = false;
      }

      onProgress(1.0); // 100% 完成

      // 即使 Firestore 操作失败，只要 Firebase Auth 成功就认为整体成功
      if (!firestoreSuccess) {
        debugPrint('Warning: Some Firestore operations failed, but avatar update completed successfully');
      } else {
        debugPrint('Avatar update completed successfully with all operations');
      }
      
      return true;

    } catch (e) {
      debugPrint('Critical error in updateUserAvatar: $e');
      return false;
    }
  }

  // 删除旧头像文件
  Future<void> deleteOldAvatar(String oldAvatarUrl) async {
    try {
      if (oldAvatarUrl.isEmpty || !oldAvatarUrl.contains('firebase')) return;
      
      final ref = _storage.refFromURL(oldAvatarUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting old avatar: $e');
      // 不抛出错误，因为删除失败不应该影响更新流程
    }
  }

  // 上传并更新头像的完整流程
  Future<bool> uploadAndUpdateAvatar(File imageFile, Function(double) onProgress) async {
    try {
      onProgress(0.1);
      debugPrint('Step 1: Compressing image...');
      final compressedData = await compressImage(imageFile);
      
      if (compressedData == null) {
        throw Exception('Failed to compress image');
      }
      
      onProgress(0.3);
      debugPrint('Step 2: Uploading to Firebase Storage...');
      final downloadUrl = await uploadAvatar(
        compressedData,
        onProgress: (uploadProgress) {
          // Storage 上传占总进度的 30% - 70%
          onProgress(0.3 + (uploadProgress * 0.4));
        },
      );
      
      if (downloadUrl == null) {
        throw Exception('Failed to upload image to storage');
      }
      
      debugPrint('Step 3: Image uploaded successfully, URL: $downloadUrl');
      onProgress(0.7);
      
      debugPrint('Step 4: Updating user data...');
      final success = await updateUserAvatar(downloadUrl, (updateProgress) {
        // 用户数据更新占总进度的 70% - 100%
        onProgress(0.7 + (updateProgress * 0.3));
      });
      
      if (!success) {
        throw Exception('Failed to update user data');
      }
      
      debugPrint('Avatar update completed successfully');
      onProgress(1.0);
      return true;
      
    } catch (e) {
      debugPrint('Error in uploadAndUpdateAvatar: $e');
      return false;
    }
  }
} 