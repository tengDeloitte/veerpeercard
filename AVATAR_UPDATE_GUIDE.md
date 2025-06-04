# Avatar Update 功能使用指南

## 功能概述

新增的头像更新功能允许用户：
- 从相册选择图片
- 使用相机拍摄新照片
- 自动压缩和优化图片
- 实时显示上传进度
- 预览选中的图片
- 移除当前头像

## 技术实现

### 1. 后端配置

#### Firebase Storage
- 已配置存储规则，允许用户上传头像到 `avatars/{userId}/` 路径
- 限制文件大小为10MB以内
- 只允许图片格式文件

#### Firestore
- 用户头像URL存储在 `users/{userId}` 文档中
- 同时更新 `nearbyUsers/{userId}` 中的业务卡片信息

### 2. 核心组件

#### AvatarService (`lib/services/avatar_service.dart`)
- `pickImage()`: 选择图片（相册/相机）
- `compressImage()`: 压缩图片到512px最大边长
- `uploadAvatar()`: 上传到Firebase Storage
- `updateUserAvatar()`: 更新Firestore和Firebase Auth
- `updateAvatarComplete()`: 完整的更新流程

#### AvatarPicker Widget (`lib/widgets/avatar_picker.dart`)
- 显示当前头像
- 提供相册/相机选择按钮
- 实时上传进度条
- 图片预览功能
- 移除头像选项

#### UserProfileProvider (`lib/providers/user_profile_provider.dart`)
- 管理用户资料状态
- 监听认证状态变化
- 同步头像更新到所有界面

### 3. 使用方法

#### 在Me Screen中更新头像
1. 点击"Edit Profile"按钮
2. 在头像区域点击"Update Avatar"按钮
3. 选择图片来源（相册或相机）
4. 预览选中的图片
5. 点击"Upload"开始上传
6. 等待上传完成

#### 头像同步
- 头像更新后会自动同步到：
  - 主界面的用户头像
  - Me Screen的名片头像
  - 附近用户功能中的业务卡片
  - Firebase Auth的photoURL

## 权限要求

### iOS
在 `ios/Runner/Info.plist` 中需要添加：
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take profile photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select profile photos</string>
```

### Android
在 `android/app/src/main/AndroidManifest.xml` 中需要添加：
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## 错误处理

- 网络连接失败：显示错误提示
- 图片格式不支持：自动转换为JPEG
- 文件过大：自动压缩
- 权限被拒绝：显示权限请求提示
- 上传失败：显示重试选项

## 性能优化

- 图片自动压缩到合适尺寸
- 使用JPEG格式减少文件大小
- 异步上传不阻塞UI
- 旧头像文件自动清理

## 安全性

- 只有认证用户可以上传头像
- 用户只能修改自己的头像
- 文件类型和大小限制
- 存储路径按用户ID隔离

## 故障排除

### 上传失败
1. 检查网络连接
2. 确认Firebase配置正确
3. 验证Storage规则已部署
4. 检查用户认证状态

### 头像不显示
1. 检查图片URL是否有效
2. 确认网络权限
3. 验证Firebase Storage规则
4. 检查缓存问题

### 权限问题
1. 确认已添加必要的权限声明
2. 检查用户是否授予了权限
3. 重新安装应用重置权限 