import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 获取当前用户
  User? get currentUser => _auth.currentUser;

  // 注册
  Future<User?> register(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      // 创建用户资料
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'photoUrl': '',
        'isOnline': true,
        'lastSeen': DateTime.now().toIso8601String(),
      });

      return result.user;
    } catch (e) {
      print('注册错误: $e');
      return null;
    }
  }

  // 登录
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // 更新在线状态
      await _firestore.collection('users').doc(result.user!.uid).update({
        'isOnline': true,
        'lastSeen': DateTime.now().toIso8601String(),
      });

      return result.user;
    } catch (e) {
      print('登录错误: $e');
      return null;
    }
  }

  // 登出
  Future<void> logout() async {
    try {
      // 更新离线状态
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
        });
      }

      await _auth.signOut();
    } catch (e) {
      print('登出错误: $e');
    }
  }
}