import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

// 附近名片服务类
class NearbyCardService {
  // 单例模式
  static final NearbyCardService _instance = NearbyCardService._internal();
  factory NearbyCardService() => _instance;
  NearbyCardService._internal();

  // Firebase实例
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 控制变量
  bool _isVisible = false;

  // 储存位置更新订阅
  StreamSubscription<Position>? _locationSubscription;

  // 当前位置
  Position? _currentPosition;

  // 最后更新时间
  DateTime? _lastLocationUpdateTime;

  // 默认搜索半径（米）
  int _searchRadius = 5000; // 5公里, 约3.1英里

  // 位置更新间隔（毫秒）
  final int _updateInterval = 300000; // 5分钟更新一次

  // 活跃超时时间（小时）
  final int _activeTimeout = 24; // 24小时未更新位置视为不活跃

  // 获取当前服务状态
  bool get isVisible => _isVisible;

  // 设置搜索半径
  set searchRadius(int radius) => _searchRadius = radius;

  // 初始化服务并开启位置可见性
  Future<bool> enableVisibility(Map<String, dynamic> userData) async {
    if (_isVisible) return true; // 已经启用

    try {
      // 请求位置权限
      final permission = await _requestLocationPermission();
      if (!permission) {
        return false;
      }

      // 获取当前位置
      final position = await _getCurrentLocation();
      if (position == null) {
        return false;
      }

      _currentPosition = position;

      // 上传位置到Firestore
      await _updateLocationInFirebase(userData);

      // 启动定期位置更新
      _startLocationUpdates(userData);

      _isVisible = true;
      return true;

    } catch (e) {
      print('Error enabling nearby visibility: $e');
      return false;
    }
  }

  // 关闭位置可见性
  Future<void> disableVisibility() async {
    if (!_isVisible) return; // 已经禁用

    try {
      // 取消位置更新订阅
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // 从Firebase移除或标记为不可见
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('nearbyUsers').doc(user.uid).update({
          'isVisible': false,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      _isVisible = false;

    } catch (e) {
      print('Error disabling nearby visibility: $e');
    }
  }

  // 请求位置权限
  Future<bool> _requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // 获取当前位置
  Future<Position?> _getCurrentLocation() async {
    try {
      // 先检查位置服务是否启用
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // 位置服务未启用，尝试提示用户
        return null;
      }

      // 然后检查权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 权限被拒绝
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // 权限被永久拒绝
        return null;
      }

      // 获取位置
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // 开始定期位置更新
  void _startLocationUpdates(Map<String, dynamic> userData) {
    // 取消现有订阅
    _locationSubscription?.cancel();

    // 设置位置更新选项
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // 移动100米更新一次
    );

    // 订阅位置更新
    _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings
    ).listen((Position position) {
      // 检查是否需要更新位置信息
      final now = DateTime.now();
      if (_lastLocationUpdateTime == null ||
          now.difference(_lastLocationUpdateTime!).inMilliseconds > _updateInterval) {
        _currentPosition = position;
        _updateLocationInFirebase(userData);
        _lastLocationUpdateTime = now;
      }
    });
  }

  // 更新位置到Firebase
  Future<void> _updateLocationInFirebase(Map<String, dynamic> userData) async {
    if (_currentPosition == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('nearbyUsers').doc(user.uid).set({
        'userId': user.uid,
        'businessCard': userData,
        'location': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isVisible': true,
      }, SetOptions(merge: true));

      print('Location updated in Firebase');

    } catch (e) {
      print('Error updating location in Firebase: $e');
    }
  }

  // 搜索附近的名片
  Future<List<Map<String, dynamic>>> searchNearbyCards() async {
    if (_currentPosition == null) {
      // 如果没有当前位置，尝试获取
      _currentPosition = await _getCurrentLocation();
      if (_currentPosition == null) {
        return [];
      }
    }

    try {
      // 计算活跃时间阈值
      final activeThreshold = DateTime.now().subtract(Duration(hours: _activeTimeout));
      final timestamp = Timestamp.fromDate(activeThreshold);

      // 查询在指定范围内的活跃用户
      // 注意：Firestore不支持GeoQuery，这里用一个简化的方法
      // 实际应用中应使用Firebase实时数据库的GeoFire或专门的地理位置服务

      // 将搜索半径转换为经纬度范围(近似计算)
      // 1度纬度约等于111公里
      final latDelta = _searchRadius / 111000.0;
      // 1度经度在赤道约等于111公里，但随着纬度增加而减少
      final lngDelta = _searchRadius / (111000.0 *
          math.cos(_currentPosition!.latitude * (math.pi / 180)));

      final minLat = _currentPosition!.latitude - latDelta;
      final maxLat = _currentPosition!.latitude + latDelta;
      final minLng = _currentPosition!.longitude - lngDelta;
      final maxLng = _currentPosition!.longitude + lngDelta;

      // 获取当前用户ID
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // 查询满足位置条件的用户
      final snapshot = await _firestore.collection('nearbyUsers')
          .where('isVisible', isEqualTo: true)
          .where('lastUpdated', isGreaterThan: timestamp)
          .where('location.latitude', isGreaterThanOrEqualTo: minLat)
          .where('location.latitude', isLessThanOrEqualTo: maxLat)
          .get();

      List<Map<String, dynamic>> nearbyUsers = [];

      // 过滤并处理结果
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // 跳过自己
        if (doc.id == currentUserId) continue;

        final GeoPoint location = data['location'];

        // 进一步过滤经度范围(Firestore无法同时查询两个范围字段)
        if (location.longitude >= minLng && location.longitude <= maxLng) {
          // 计算精确距离(米)
          final distanceInMeters = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              location.latitude,
              location.longitude
          );

          // 检查是否在搜索半径内
          if (distanceInMeters <= _searchRadius) {
            nearbyUsers.add({
              'userId': doc.id,
              'businessCard': data['businessCard'],
              'distance': distanceInMeters,
              'lastUpdated': data['lastUpdated'],
            });
          }
        }
      }

      // 按距离排序
      nearbyUsers.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double)
      );

      return nearbyUsers;

    } catch (e) {
      print('Error searching nearby cards: $e');
      return [];
    }
  }

  // 发送添加好友请求
  Future<bool> sendFriendRequest(String targetUserId, String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // 创建好友请求记录
      await _firestore.collection('friendRequests').add({
        'fromUserId': currentUser.uid,
        'toUserId': targetUserId,
        'message': message,
        'status': 'pending', // pending, accepted, rejected
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  // 销毁服务资源
  void dispose() {
    disableVisibility();
  }
}