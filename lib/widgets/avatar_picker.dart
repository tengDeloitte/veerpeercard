import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veerpeercard/services/avatar_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvatarPicker extends StatefulWidget {
  final String? currentAvatarUrl;
  final Function(String) onAvatarUpdated;

  const AvatarPicker({
    Key? key,
    this.currentAvatarUrl,
    required this.onAvatarUpdated,
  }) : super(key: key);

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final AvatarService _avatarService = AvatarService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  XFile? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 当前头像显示
        _buildCurrentAvatar(),
        
        const SizedBox(height: 16),
        
        // 上传进度指示器
        if (_isUploading) _buildUploadProgress(),
        
        // 选择图片按钮
        if (!_isUploading) _buildImageSourceButtons(),
        
        // 预览和确认区域
        if (_selectedImage != null && !_isUploading) _buildPreviewArea(),
      ],
    );
  }

  // 构建当前头像显示
  Widget _buildCurrentAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 3,
        ),
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.isNotEmpty) 
            ? NetworkImage(widget.currentAvatarUrl!)
            : null,
        child: (widget.currentAvatarUrl == null || widget.currentAvatarUrl!.isEmpty)
            ? Icon(
                Icons.person,
                size: 60,
                color: Colors.grey.shade600,
              )
            : null,
      ),
    );
  }

  // 构建上传进度指示器
  Widget _buildUploadProgress() {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Uploading... ${(_uploadProgress * 100).toInt()}%',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 构建图片源选择按钮
  Widget _buildImageSourceButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSourceButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            _buildSourceButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
        if (widget.currentAvatarUrl != null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: _removeAvatar,
            child: Text(
              'Remove Photo',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ],
    );
  }

  // 构建图片源按钮
  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // 构建预览区域
  Widget _buildPreviewArea() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Preview:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        
        // 预览图片
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: ClipOval(
            child: Image.file(
              File(_selectedImage!.path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 操作按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _uploadSelectedImage,
              child: const Text('Upload'),
            ),
          ],
        ),
      ],
    );
  }

  // 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _avatarService.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  // 上传选中的图片
  Future<void> _uploadSelectedImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      debugPrint('AvatarPicker: Starting upload process...');
      final success = await _avatarService.uploadAndUpdateAvatar(
        File(_selectedImage!.path),
        (progress) {
          debugPrint('AvatarPicker: Progress update: ${(progress * 100).toStringAsFixed(1)}%');
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (success) {
        debugPrint('AvatarPicker: Upload successful, calling onAvatarUpdated');
        // 从 Firebase Auth 获取最新的头像URL
        final user = FirebaseAuth.instance.currentUser;
        final newAvatarUrl = user?.photoURL ?? '';
        widget.onAvatarUpdated(newAvatarUrl);
        _showSuccessSnackBar('Avatar updated successfully!');
        setState(() {
          _selectedImage = null;
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      debugPrint('AvatarPicker: Upload failed with error: $e');
      _showErrorSnackBar('Failed to update avatar: ${e.toString()}');
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // 移除头像
  Future<void> _removeAvatar() async {
    final confirmed = await _showConfirmDialog(
      'Remove Photo',
      'Are you sure you want to remove your profile photo?',
    );

    if (confirmed) {
      setState(() {
        _isUploading = true;
      });

      try {
        // 更新为默认头像URL - 使用Firebase默认或null
        final success = await _avatarService.updateUserAvatar('', (progress) {
          // 移除操作通常很快，可以不显示进度
        });

        if (success) {
          widget.onAvatarUpdated('');
          _showSuccessSnackBar('Profile photo removed');
        } else {
          _showErrorSnackBar('Failed to remove photo');
        }
      } catch (e) {
        _showErrorSnackBar('Error removing photo: $e');
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // 显示确认对话框
  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // 显示成功消息
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 显示错误消息
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 