import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veerpeercard/services/nearby_card_service.dart';

// 创建一个NearbyCardService提供者
final nearbyCardServiceProvider = Provider<NearbyCardService>((ref) {
  return NearbyCardService();
});

// 提供当前用户的业务卡片信息
final userBusinessCardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // 这里应当从本地存储或者服务器获取当前用户的名片信息
  // 这是一个示例实现
  return {
    'companyName': 'CHEN AUTO GROUP',
    'name': 'Michael Chen',
    'title': 'Sales Representative',
    'avatar': 'https://via.placeholder.com/150',
    'description': 'Chen Auto Group specializes in providing premium auto sales services with over 10 years of industry experience.',
    'contactMethods': [
      {
        'label': 'Phone',
        'value': '+1 (555) 123-4567',
        'icon': Icons.phone,
        'color': Colors.green,
        'type': 'phone',
      },
      {
        'label': 'Email',
        'value': 'michael.chen@example.com',
        'icon': Icons.email,
        'color': Colors.blue,
        'type': 'email',
      },
    ],
  };
});

// 表示位置可见性状态的状态提供者
class NearbyVisibilityNotifier extends StateNotifier<bool> {
  final NearbyCardService _nearbyService;
  final Ref _ref;

  NearbyVisibilityNotifier(this._nearbyService, this._ref) : super(false) {
    // 初始化时检查当前状态
    _checkCurrentState();
  }

  Future<void> _checkCurrentState() async {
    state = _nearbyService.isVisible;
  }

  Future<bool> toggleVisibility() async {
    if (state) {
      // 已开启，现在关闭
      await _nearbyService.disableVisibility();
      state = false;
      return false;
    } else {
      // 已关闭，现在开启
      final userCardAsync = await _ref.read(userBusinessCardProvider.future);
      final success = await _nearbyService.enableVisibility(userCardAsync);
      if (success) {
        state = true;
      }
      return success;
    }
  }

  Future<bool> enableVisibility() async {
    if (state) return true; // 已经启用

    final userCardAsync = await _ref.read(userBusinessCardProvider.future);
    final success = await _nearbyService.enableVisibility(userCardAsync);
    if (success) {
      state = true;
    }
    return success;
  }

  Future<void> disableVisibility() async {
    if (!state) return; // 已经禁用

    await _nearbyService.disableVisibility();
    state = false;
  }
}

// 位置可见性提供者定义
final nearbyVisibilityProvider = StateNotifierProvider<NearbyVisibilityNotifier, bool>((ref) {
  final service = ref.watch(nearbyCardServiceProvider);
  return NearbyVisibilityNotifier(service, ref);
});

// 附近用户列表的状态提供者
class NearbyUsersNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final NearbyCardService _nearbyService;
  final Ref _ref;

  NearbyUsersNotifier(this._nearbyService, this._ref) : super(const AsyncValue.loading()) {
    // 初始化为空列表
    state = const AsyncValue.data([]);
  }

  Future<void> searchNearbyUsers() async {
    // 设置为加载状态
    state = const AsyncValue.loading();

    try {
      // 确保位置可见性已启用
      final visibilityNotifier = _ref.read(nearbyVisibilityProvider.notifier);
      if (!_ref.read(nearbyVisibilityProvider)) {
        await visibilityNotifier.enableVisibility();
      }

      // 搜索附近用户
      final results = await _nearbyService.searchNearbyCards();
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// 附近用户提供者定义
final nearbyUsersProvider = StateNotifierProvider<NearbyUsersNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final service = ref.watch(nearbyCardServiceProvider);
  return NearbyUsersNotifier(service, ref);
});

// 好友请求的状态提供者
class FriendRequestsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FriendRequestsNotifier() : super(const AsyncValue.loading()) {
    // 初始化时加载好友请求
    loadFriendRequests();
  }

  Future<void> loadFriendRequests() async {
    // 设置为加载状态
    state = const AsyncValue.loading();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('friendRequests')
            .where('toUserId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .get();

        List<Map<String, dynamic>> requests = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();

          // 获取发送者信息
          final senderSnapshot = await _firestore
              .collection('nearbyUsers')
              .doc(data['fromUserId'])
              .get();

          if (senderSnapshot.exists) {
            final senderData = senderSnapshot.data();

            requests.add({
              'requestId': doc.id,
              'fromUserId': data['fromUserId'],
              'message': data['message'],
              'createdAt': data['createdAt'],
              'senderInfo': senderData?['businessCard'] ?? {},
            });
          }
        }

        state = AsyncValue.data(requests);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> handleFriendRequest(String requestId, bool accept) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .update({
        'status': accept ? 'accepted' : 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (accept) {
        // 如果接受，创建联系人关系
        final requestData = state.asData?.value.firstWhere(
              (req) => req['requestId'] == requestId,
          orElse: () => <String, dynamic>{},
        );

        if (requestData != null && requestData.isNotEmpty) {
          // 获取当前用户ID
          final currentUserId = _auth.currentUser?.uid;
          if (currentUserId != null) {
            // 创建双向联系人关系
            final batch = _firestore.batch();

            // 添加到当前用户的联系人列表
            final currentUserContactRef = _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('contacts')
                .doc(requestData['fromUserId']);

            batch.set(currentUserContactRef, {
              'userId': requestData['fromUserId'],
              'businessCard': requestData['senderInfo'],
              'createdAt': FieldValue.serverTimestamp(),
            });

            // 添加到发送请求用户的联系人列表
            final senderContactRef = _firestore
                .collection('users')
                .doc(requestData['fromUserId'])
                .collection('contacts')
                .doc(currentUserId);

            // 获取当前用户的名片信息
            final currentUserCard = await _firestore
                .collection('nearbyUsers')
                .doc(currentUserId)
                .get();

            if (currentUserCard.exists) {
              batch.set(senderContactRef, {
                'userId': currentUserId,
                'businessCard': currentUserCard.data()?['businessCard'] ?? {},
                'createdAt': FieldValue.serverTimestamp(),
              });

              // 提交批处理
              await batch.commit();
            }
          }
        }
      }

      // 刷新请求列表
      await loadFriendRequests();

      return true;
    } catch (e) {
      print('Error handling friend request: $e');
      return false;
    }
  }
}

// 好友请求提供者定义
final friendRequestsProvider = StateNotifierProvider<FriendRequestsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return FriendRequestsNotifier();
});

// 当前选中标签页的提供者
final selectedTabProvider = StateProvider<int>((ref) => 0);