import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 新增导入
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:veerpeercard/utils/logger.dart';

class UserSettingsScreen extends StatefulWidget {  // 改为StatefulWidget
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

// 新增State类
class _UserSettingsScreenState extends State<UserSettingsScreen> {
  File? _imageFile;
  bool _isUploading = false;

  // 获取用户当前头像URL
  String? get _userPhotoURL => FirebaseAuth.instance.currentUser?.photoURL;

  // 选择图片
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // 自动开始上传
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 创建存储引用 - 确保路径一致性
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_avatars') // 确保这个路径在其他地方也是一致的
          .child('${user.uid}.jpg');

      // 检查是否有权限问题
      try {
        // 尝试删除旧文件，如果存在的话（这可以解决引用问题）
        await storageRef.delete().catchError((error) {
          // 修改: 使用明确的变量名并检查错误类型
          if (error is FirebaseException && error.code != 'object-not-found') {
            throw error;
          }
          // 其他错误类型也抛出
          if (error is! FirebaseException) {
            throw error;
          }
          return null;
        });
      } catch (e) {
        // 修改: 使用logger替代print
        logger.w('Warning when trying to delete old image', e, StackTrace.current);
        // 继续上传新文件
      }

      // 上传文件
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded_by': user.uid},
      );
      await storageRef.putFile(_imageFile!, metadata);

      // 获取下载URL
      final downloadURL = await storageRef.getDownloadURL();

      // 更新用户资料
      await user.updatePhotoURL(downloadURL);

      // 更新Firestore中的用户资料（如果您使用Firestore存储用户数据）
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'photoURL': downloadURL,
        });
      } catch (e) {
        // 修改: 使用logger替代print
        logger.w('Warning: Could not update Firestore profile', e, StackTrace.current);
        // 继续，因为主要的Firebase Auth更新已完成
      }

      // 刷新用户
      await user.reload();

      // 通知UI更新
      setState(() {});

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      // 修改: 使用logger替代print
      logger.e('Detailed error info', e, StackTrace.current);

      // 显示更友好的错误消息
      String errorMessage = 'Error updating profile picture';
      if (e.toString().contains('not-found')) {
        errorMessage += ': Storage location not found';
      } else if (e.toString().contains('unauthorized')) {
        errorMessage += ': Permission denied';
      } else if (e.toString().contains('network')) {
        errorMessage += ': Network error';
      } else {
        errorMessage += ': ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // 用户头像和邮箱
          Center(
            child: Column(
              children: [
                // 修改的头像部分
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _userPhotoURL != null
                            ? NetworkImage(_userPhotoURL!)
                            : null,
                        child: _userPhotoURL == null
                            ? Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 32),
                        )
                            : null,
                      ),
                    ),
                    // 上传指示器
                    if (_isUploading)
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(red: 255, green: 255, blue: 255, alpha: 179), // 0.7 * 255 ≈ 179
                          ),
                        ),
                      ),
                    // 编辑图标
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(  // 添加手势检测器
                        onTap: _isUploading ? null : _pickImage,  // 添加点击处理
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(user?.email ?? 'Unknown User'),
                // 添加提示文本
                const SizedBox(height: 5),
                Text(
                  'Tap avatar to change',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 登出按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}