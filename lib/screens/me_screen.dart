import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veerpeercard/services/nearby_card_service.dart';
import 'package:veerpeercard/widgets/avatar_picker.dart';
import 'package:veerpeercard/providers/user_profile_provider.dart';

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  Alignment _dragAlignment = Alignment.center;
  final math.Random _random = math.Random();
  final NearbyCardService _nearbyService = NearbyCardService();

  // 个人信息
  Map<String, dynamic> userInfo = {
    'companyName': 'CHEN AUTO GROUP',
    'name': 'Michael Chen',
    'title': 'Sales Representative',
    'avatar': '',  // 这将在 initState 中从 Firebase 获取
    'description':
        'Chen Auto Group specializes in providing premium auto sales services with over 10 years of industry experience. We focus on customer satisfaction and professional service.',
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
      {
        'label': 'Website',
        'value': 'www.chenautogroup.com',
        'icon': Icons.language,
        'color': Colors.purple,
        'type': 'website',
      },
      {
        'label': 'WeChat',
        'value': 'michaelchen2023',
        'icon': Icons.chat,
        'color': Colors.green,
        'type': 'custom',
      },
    ],
  };

  // 获取当前用户头像URL
  String? _getCurrentAvatarUrl() {
    final userProfile = ref.watch(userProfileProvider);
    final user = FirebaseAuth.instance.currentUser;
    
    String? avatarUrl;
    userProfile.whenData((profile) {
      avatarUrl = profile?.avatar;
    });
    
    // 如果 Provider 中没有头像，则使用 Firebase Auth 的头像
    avatarUrl ??= user?.photoURL;
    
    // 确保不返回空字符串
    if (avatarUrl != null && avatarUrl!.isEmpty) {
      avatarUrl = null;
    }
    
    return avatarUrl;
  }

  void _showAddContactMethodDialog(BuildContext context) {
    final labelController = TextEditingController();
    final valueController = TextEditingController();
    IconData selectedIcon = Icons.contact_phone;
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Contact Method'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'e.g. WhatsApp, LinkedIn',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      hintText: 'Enter contact information',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 这里可以添加图标选择器和颜色选择器
                  // 简化版本使用默认值
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (labelController.text.isNotEmpty &&
                      valueController.text.isNotEmpty) {
                    setState(() {
                      if (!userInfo.containsKey('contactMethods')) {
                        userInfo['contactMethods'] = [];
                      }
                      (userInfo['contactMethods'] as List).add({
                        'label': labelController.text,
                        'value': valueController.text,
                        'icon': selectedIcon,
                        'color': selectedColor,
                        'type': 'custom',
                      });
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  // 服务列表
  List<String> services = [
    'Professional Consulting',
    'Premium Products',
    'After-sales Support',
    'Quality Assurance',
  ];

  // 文本内容长度限制
  final int _descriptionCharLimit = 380;
  final int _serviceNameCharLimit = 25;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // 设置较长的动画持续时间，让弹跳效果持续更长
      duration: const Duration(seconds: 10),
    );

    // 初始化时从 Firebase 获取用户头像
    _initializeUserInfo();

    // 自动启用附近可见性
    _enableNearbyVisibility();
  }

  // 初始化用户信息，包括头像
  void _initializeUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        // 更新用户基本信息
        userInfo['name'] = user.displayName ?? userInfo['name'];
        userInfo['avatar'] = user.photoURL ?? '';
        
        // 更新联系方式中的邮箱
        if (userInfo['contactMethods'] != null) {
          final contactMethods = userInfo['contactMethods'] as List;
          for (var method in contactMethods) {
            if (method['type'] == 'email') {
              method['value'] = user.email ?? method['value'];
              break;
            }
          }
        }
      });
    }
  }

  // 启用附近可见性的方法
  Future<void> _enableNearbyVisibility() async {
    if (!_nearbyService.isVisible) {
      await _nearbyService.enableVisibility(userInfo);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 开始随机动画
  void _startRandomAnimation() {
    final size = MediaQuery.of(context).size;
    _runAnimation(
      // 创建极快的随机速度向量
      Offset(
        (_random.nextDouble() * 2 - 1) * 8000,
        (_random.nextDouble() * 2 - 1) * 8000,
      ),
      size,
    );
  }

  // 记录当前动画的速度方向
  Offset _currentVelocity = Offset.zero;

  // 记录边界限制
  double _maxHorizontalAlignment = 0.95;
  double _maxVerticalAlignment = 0.95;

  void _runAnimation(Offset pixelsPerSecond, Size size) {
    // 计算卡片的宽高与屏幕的比例
    final cardWidth = size.width * 0.65;
    final cardHeight = size.height * 0.55;

    // 计算边界限制
    _maxHorizontalAlignment = 0.95 - (cardWidth / size.width);
    _maxVerticalAlignment = 0.95 - (cardHeight / size.height);

    // 计算速度，以屏幕宽高为单位
    final unitsPerSecondX = pixelsPerSecond.dx / size.width * 0.9;
    final unitsPerSecondY = pixelsPerSecond.dy / size.height * 0.9;

    // 保存当前速度方向，用于碰撞检测
    _currentVelocity = Offset(unitsPerSecondX, unitsPerSecondY);

    // 创建自定义动画
    _startBounceAnimation(size);
  }

  void _startBounceAnimation(Size size) {
    // 重置动画控制器
    _controller.reset();

    // 使用Ticker而不是动画控制器来手动更新位置
    double progress = 0.0;
    const stepDuration = Duration(milliseconds: 16); // 约60fps

    // 减速因子
    double dampingFactor = 0.98;

    // 计时器，用于模拟物理运动
    Timer.periodic(stepDuration, (timer) {
      // 如果速度太小或动画被用户停止，停止动画
      if (_currentVelocity.distance < 0.01 || !_controller.isAnimating) {
        timer.cancel();
        return;
      }

      // 计算新位置
      double newX = _dragAlignment.x + _currentVelocity.dx * 0.1;
      double newY = _dragAlignment.y + _currentVelocity.dy * 0.1;

      // 检查是否碰到边界并反弹
      if (newX.abs() > _maxHorizontalAlignment) {
        // 碰到左右边界，X方向速度反转
        _currentVelocity = Offset(
          -_currentVelocity.dx * 0.7,
          _currentVelocity.dy,
        );
        newX = newX.sign * _maxHorizontalAlignment;
      }

      if (newY.abs() > _maxVerticalAlignment) {
        // 碰到上下边界，Y方向速度反转
        _currentVelocity = Offset(
          _currentVelocity.dx,
          -_currentVelocity.dy * 0.7,
        );
        newY = newY.sign * _maxVerticalAlignment;
      }

      // 应用减速
      _currentVelocity = _currentVelocity.scale(dampingFactor, dampingFactor);

      // 更新位置
      setState(() {
        _dragAlignment = Alignment(newX, newY);
      });

      progress += 0.016;

      // 最长运行10秒
      if (progress > 10) {
        timer.cancel();
      }
    });

    // 启动动画控制器，但实际上我们不用它来驱动动画，只是用来标记动画状态
    _controller.forward();
  }

  // 获取随机对齐位置，但保持在屏幕安全范围内
  Alignment _getSafeRandomAlignment(Size size) {
    // 使用与屏幕大小相关的边界计算
    final cardWidth = size.width * 0.65;
    final cardHeight = size.height * 0.55; // 估计卡片高度

    // 允许卡片移动到接近屏幕边缘
    final maxHorizontalAlignment = 0.9 - (cardWidth / size.width) / 2;
    final maxVerticalAlignment = 0.9 - (cardHeight / size.height) / 2;

    // 生成随机位置
    double newX = (_random.nextDouble() * 2 - 1) * maxHorizontalAlignment;
    double newY = (_random.nextDouble() * 2 - 1) * maxVerticalAlignment;

    // 确保新位置在安全区域内
    newX = newX.clamp(-maxHorizontalAlignment, maxHorizontalAlignment);
    newY = newY.clamp(-maxVerticalAlignment, maxVerticalAlignment);

    return Alignment(newX, newY);
  }

  // 对长文本进行截断并添加省略号
  String _truncateWithEllipsis(String text, int maxLength) {
    return text.length <= maxLength
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  // 显示详细信息对话框
  void _showDetailsDialog() {
    // 计算哪些服务需要额外显示
    final List<String> extraServices =
        services.length > 4 ? services.sublist(4) : [];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Contact Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailItem('Company', userInfo['companyName']!),
                  _buildDetailItem('Name', userInfo['name']!),
                  _buildDetailItem('Title', userInfo['title']!),

                  // 添加联系方式部分
                  const SizedBox(height: 10),
                  const Text(
                    'Contact Methods:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  // 使用统一的contactMethods数组显示所有联系方式
                  if (userInfo.containsKey('contactMethods') &&
                      (userInfo['contactMethods'] as List).isNotEmpty)
                    ...(userInfo['contactMethods'] as List).map(
                      (method) => _buildContactDetailItem(
                        icon: method['icon'],
                        label: method['label'],
                        value: method['value'],
                        color: method['color'],
                      ),
                    ),

                  _buildDetailItem('Description', userInfo['description']!),

                  const SizedBox(height: 10),
                  const Text(
                    'Services:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600] ?? Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(service)),
                        ],
                      ),
                    ),
                  ),
                  if (extraServices.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Additional Services:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...extraServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(service)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // 带点击动作的联系方式详情条目
  Widget _buildContactDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
      child: InkWell(
        onTap: () {
          // 根据不同类型的联系方式执行不同的操作
          if (icon == Icons.phone) {
            // launch('tel:$value');
          } else if (icon == Icons.email) {
            // launch('mailto:$value');
          } else if (icon == Icons.language) {
            // launch('https://$value');
          }
        },
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                Text(value, style: TextStyle(fontSize: 14, color: color)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  // 详细信息条目
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  // 显示头像选择器
  void _showAvatarPicker(BuildContext context, Map<String, dynamic> editedInfo) {
    // 获取当前头像URL
    final currentAvatarUrl = _getCurrentAvatarUrl();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Avatar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              AvatarPicker(
                currentAvatarUrl: currentAvatarUrl,
                onAvatarUpdated: (newAvatarUrl) {
                  debugPrint('MeScreen: onAvatarUpdated called with URL: $newAvatarUrl');
                  // 使用Provider更新头像
                  ref.read(userProfileProvider.notifier).updateAvatar(newAvatarUrl);
                  setState(() {
                    userInfo['avatar'] = newAvatarUrl;
                    editedInfo['avatar'] = newAvatarUrl;
                  });
                  
                  // 确保对话框关闭
                  Navigator.of(context).pop();
                  debugPrint('MeScreen: Dialog closed');
                  
                  // 触发随机动画来显示更新效果
                  _startRandomAnimation();
                  
                  // 显示成功消息
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Avatar updated successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示编辑表单
  void _showEditForm() {
    // 创建临时变量来保存编辑值
    final Map<String, dynamic> editedInfo = Map.from(userInfo);
    final List<String> editedServices = List.from(services);
    // 修复：使用空列表作为默认值，而不是尝试访问不存在的customFields
    final List<Map<String, dynamic>> editedContactMethods = List.from(
      userInfo['contactMethods'] ?? [],
    );

    // 创建控制器
    final companyNameController = TextEditingController(
      text: editedInfo['companyName'],
    );
    final nameController = TextEditingController(text: editedInfo['name']);
    final titleController = TextEditingController(text: editedInfo['title']);
    final descriptionController = TextEditingController(
      text: editedInfo['description'],
    );

    // 添加联系方式的控制器
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final websiteController = TextEditingController();

    // 从contactMethods中初始化基本联系方式控制器
    if (editedInfo.containsKey('contactMethods')) {
      for (var method in editedInfo['contactMethods'] as List) {
        switch (method['type']) {
          case 'phone':
            phoneController.text = method['value'];
            break;
          case 'email':
            emailController.text = method['value'];
            break;
          case 'address':
            addressController.text = method['value'];
            break;
          case 'website':
            websiteController.text = method['value'];
            break;
        }
      }
    }

    // 服务项控制器列表 - 为每个服务创建一个控制器
    final List<TextEditingController> serviceControllers =
        editedServices
            .map((service) => TextEditingController(text: service))
            .toList();

    // 自定义字段控制器列表
    final List<Map<String, dynamic>> customFieldControllers = [];

    // 从contactMethods中获取自定义联系方式
    if (editedInfo.containsKey('contactMethods')) {
      for (var method in editedInfo['contactMethods'] as List) {
        if (method['type'] == 'custom') {
          customFieldControllers.add({
            'labelController': TextEditingController(text: method['label']),
            'valueController': TextEditingController(text: method['value']),
            'icon': method['icon'],
            'color': method['color'],
          });
        }
      }
    }

    // 添加一个空的服务项控制器，用于添加新服务
    final newServiceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Edit Profile Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 公司名称
                          _buildFormField(
                            'Business Name/Company Name',
                            companyNameController,
                          ),
                          const SizedBox(height: 16),

                          // 头像和姓名、职位
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 头像
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundImage: () {
                                      final avatarUrl = _getCurrentAvatarUrl();
                                      return (avatarUrl != null && avatarUrl.isNotEmpty) 
                                          ? NetworkImage(avatarUrl) 
                                          : null;
                                    }(),
                                    backgroundColor: Colors.grey.shade300,
                                    child: () {
                                      final avatarUrl = _getCurrentAvatarUrl();
                                      return (avatarUrl == null || avatarUrl.isEmpty)
                                          ? Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Colors.grey.shade600,
                                            )
                                          : null;
                                    }(),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _showAvatarPicker(context, editedInfo);
                                    },
                                    child: const Text('Update Avatar'),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // 姓名和职位
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildFormField('Name', nameController),
                                    const SizedBox(height: 16),
                                    _buildFormField('Title', titleController),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 新增: 联系方式部分
                          const Text(
                            'Contact Methods:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 电话号码
                          _buildContactFormField(
                            label: 'Phone Number',
                            controller: phoneController,
                            icon: Icons.phone,
                            iconColor: Colors.green[700] ?? Colors.green,
                          ),
                          const SizedBox(height: 12),

                          // 邮箱
                          _buildContactFormField(
                            label: 'Email Address',
                            controller: emailController,
                            icon: Icons.email,
                            iconColor: Colors.blue[700] ?? Colors.blue,
                          ),
                          const SizedBox(height: 12),

                          // 地址
                          _buildContactFormField(
                            label: 'Address',
                            controller: addressController,
                            icon: Icons.location_on,
                            iconColor: Colors.orange[800] ?? Colors.blue,
                          ),
                          const SizedBox(height: 12),

                          // 网站
                          _buildContactFormField(
                            label: 'Website',
                            controller: websiteController,
                            icon: Icons.language,
                            iconColor: Colors.purple[700] ?? Colors.purple,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Add your own custom contact methods (e.g. WeChat, WhatsApp, LinkedIn, etc.)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),

                          // 使用StatefulBuilder来管理自定义字段列表
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                children: [
                                  // 现有自定义字段列表
                                  ...List.generate(customFieldControllers.length, (
                                    index,
                                  ) {
                                    final fieldControllers =
                                        customFieldControllers[index];
                                    final labelController =
                                        fieldControllers['labelController']
                                            as TextEditingController;
                                    final valueController =
                                        fieldControllers['valueController']
                                            as TextEditingController;
                                    final IconData icon =
                                        fieldControllers['icon'] as IconData;
                                    final Color color =
                                        fieldControllers['color'] as Color;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 图标选择器 (简化版本)
                                          // Container(
                                          //   padding: const EdgeInsets.all(12),
                                          //   decoration: BoxDecoration(
                                          //     color: color.withOpacity(0.1),
                                          //     borderRadius: BorderRadius.circular(8),
                                          //   ),
                                          //   child: Icon(icon, color: color),
                                          // ),
                                          InkWell(
                                            onTap: () {
                                              _showIconSelectionDialog(
                                                context,
                                                (selectedIcon, selectedColor) {
                                                  setState(() {
                                                    fieldControllers['icon'] =
                                                        selectedIcon;
                                                    fieldControllers['color'] =
                                                        selectedColor;
                                                  });
                                                },
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(icon, color: color),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // 标签和值输入框
                                          Expanded(
                                            child: Column(
                                              children: [
                                                TextField(
                                                  controller: labelController,
                                                  decoration: const InputDecoration(
                                                    labelText:
                                                        'Label (e.g. WeChat)',
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextField(
                                                  controller: valueController,
                                                  decoration: const InputDecoration(
                                                    labelText:
                                                        'Value (e.g. ID or Number)',
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // 删除按钮
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                customFieldControllers.removeAt(
                                                  index,
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  // 添加新自定义字段按钮
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text(
                                      'Add Custom Contact Method',
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        // 添加新的自定义字段，默认使用聊天图标和绿色
                                        customFieldControllers.add({
                                          'labelController':
                                              TextEditingController(),
                                          'valueController':
                                              TextEditingController(),
                                          'icon': Icons.chat_bubble,
                                          'color': Colors.green,
                                        });
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // 业务描述
                          _buildFormField(
                            'Business/Company Description',
                            descriptionController,
                            maxLines: 6,
                          ),
                          const SizedBox(height: 16),

                          const SizedBox(height: 16),

                          // 服务列表
                          const Text(
                            'Services/Skills:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 使用单一StatefulBuilder包裹整个服务列表区域
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                children: [
                                  // 现有服务项列表
                                  ...List.generate(serviceControllers.length, (
                                    index,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  serviceControllers[index],
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                serviceControllers.removeAt(
                                                  index,
                                                );
                                                editedServices.removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  // 添加新服务项
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: newServiceController,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              hintText: 'Add new service',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            onSubmitted: (value) {
                                              if (value.isNotEmpty) {
                                                setState(() {
                                                  editedServices.add(value);
                                                  serviceControllers.add(
                                                    TextEditingController(
                                                      text: value,
                                                    ),
                                                  );
                                                  newServiceController.clear();
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            if (newServiceController
                                                .text
                                                .isNotEmpty) {
                                              setState(() {
                                                editedServices.add(
                                                  newServiceController
                                                      .text,
                                                );
                                                serviceControllers.add(
                                                  TextEditingController(
                                                    text:
                                                        newServiceController
                                                            .text,
                                                  ),
                                                );
                                                newServiceController.clear();
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // 更新信息
                          setState(() {
                            userInfo['companyName'] =
                                companyNameController.text;
                            userInfo['name'] = nameController.text;
                            userInfo['title'] = titleController.text;
                            userInfo['description'] =
                                descriptionController.text;

                            // 更新联系方式列表
                            List<Map<String, dynamic>> updatedContactMethods =
                                [];

                            // 添加基本联系方式
                            if (phoneController.text.isNotEmpty) {
                              updatedContactMethods.add({
                                'label': 'Phone',
                                'value': phoneController.text,
                                'icon': Icons.phone,
                                'color': Colors.green,
                                'type': 'phone',
                              });
                            }

                            if (emailController.text.isNotEmpty) {
                              updatedContactMethods.add({
                                'label': 'Email',
                                'value': emailController.text,
                                'icon': Icons.email,
                                'color': Colors.blue,
                                'type': 'email',
                              });
                            }

                            if (addressController.text.isNotEmpty) {
                              updatedContactMethods.add({
                                'label': 'Address',
                                'value': addressController.text,
                                'icon': Icons.location_on,
                                'color': Colors.orange,
                                'type': 'address',
                              });
                            }


                            if (websiteController.text.isNotEmpty) {
                              updatedContactMethods.add({
                                'label': 'Website',
                                'value': websiteController.text,
                                'icon': Icons.language,
                                'color': Colors.purple,
                                'type': 'website',
                              });
                            }

                            // 更新自定义联系方式
                            for (var controller in customFieldControllers) {
                              final label =
                                  (controller['labelController']
                                          as TextEditingController)
                                      .text;
                              final value =
                                  (controller['valueController']
                                          as TextEditingController)
                                      .text;

                              // 只保存有标签和值的字段
                              if (label.isNotEmpty && value.isNotEmpty) {
                                updatedContactMethods.add({
                                  'label': label,
                                  'value': value,
                                  'icon':
                                      controller['icon'] ?? Icons.contact_phone,
                                  'color': controller['color'] ?? Colors.blue,
                                  'type': 'custom',
                                });
                              }
                            }

                            // 更新联系方式数组
                            userInfo['contactMethods'] = updatedContactMethods;

                            // 更新服务列表
                            services =
                                serviceControllers
                                    .map((controller) => controller.text)
                                    .where((text) => text.isNotEmpty)
                                    .toList();
                          });
                          Navigator.of(context).pop();

                          // 编辑后触发一次随机动画
                          _startRandomAnimation();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showIconSelectionDialog(
    BuildContext context,
    Function(IconData, Color) onSelect,
  ) {
    // 预定义一组常用图标和颜色
    final List<Map<String, dynamic>> icons = [
      {'icon': Icons.phone, 'color': Colors.green[700] ?? Colors.green},
      {'icon': Icons.email, 'color': Colors.blue[700] ?? Colors.blue},
      {'icon': Icons.language, 'color': Colors.purple[700] ?? Colors.purple},
      {'icon': Icons.chat_bubble, 'color': Colors.green[700] ?? Colors.green},
      {'icon': Icons.wechat, 'color': Colors.green[700] ?? Colors.green},
      {'icon': Icons.chat, 'color': Colors.blue[700] ?? Colors.blue},
      {'icon': Icons.sms, 'color': Colors.orange[700] ?? Colors.orange},
      {'icon': Icons.public, 'color': Colors.blue[700] ?? Colors.blue},
      {'icon': Icons.link, 'color': Colors.teal[700] ?? Colors.teal},
      {'icon': Icons.person, 'color': Colors.indigo[700] ?? Colors.indigo},
      {'icon': Icons.business, 'color': Colors.brown[700] ?? Colors.brown},
      {'icon': Icons.facebook, 'color': Colors.blue[800] ?? Colors.blue},
      {'icon': Icons.fax, 'color': Colors.red[800] ?? Colors.blue},
      {'icon': Icons.location_on, 'color': Colors.orange[800] ?? Colors.blue},
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Icon'),
            content: Container(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: icons.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      onSelect(icons[index]['icon'], icons[index]['color']);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: icons[index]['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icons[index]['icon'],
                        color: icons[index]['color'],
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  // 联系方式表单字段
  Widget _buildContactFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 表单字段
  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 保持名片原始尺寸
    final cardWidth = MediaQuery.of(context).size.width * 0.76;

    return Scaffold(
      body: Container(
        color: Colors.grey[50] ?? Colors.grey.shade50,
        child: SafeArea(
          child: Stack(
            children: [
              // 可拖动卡片区域
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 计算可移动的最大边界值 - 增加可移动范围
                    final cardHeight = constraints.maxHeight * 0.55;
                    final maxHorizontalAlignment =
                        0.95 - (cardWidth / constraints.maxWidth) / 2;
                    final maxVerticalAlignment =
                        0.95 - (cardHeight / constraints.maxHeight) / 2;

                    return GestureDetector(
                      onPanDown: (details) {
                        _controller.stop();
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          // 计算新位置，保持适度的速度系数
                          double newX =
                              _dragAlignment.x +
                              4 * details.delta.dx / constraints.maxWidth;
                          double newY =
                              _dragAlignment.y +
                              4 * details.delta.dy / constraints.maxHeight;

                          // 限制在安全区域内，但允许更大范围
                          newX = newX.clamp(
                            -maxHorizontalAlignment,
                            maxHorizontalAlignment,
                          );
                          newY = newY.clamp(
                            -maxVerticalAlignment,
                            maxVerticalAlignment,
                          );

                          _dragAlignment = Alignment(newX, newY);
                        });
                      },
                      onPanEnd: (details) {
                        // 获取手指释放时的速度
                        _runAnimation(
                          details.velocity.pixelsPerSecond,
                          Size(constraints.maxWidth, constraints.maxHeight),
                        );
                      },
                      child: Align(
                        alignment: _dragAlignment,
                        child: Container(
                          width: cardWidth,
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.97,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 3,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Main content area - no longer using Expanded to let it take only the needed space
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min, // Use min to prevent stretching
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Company name
                                      Container(
                                        margin: const EdgeInsets.only(top: 8, bottom: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blue, width: 1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          userInfo['companyName']!,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),

                                      // Name and title
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundImage: () {
                                                final avatarUrl = _getCurrentAvatarUrl();
                                                return (avatarUrl != null && avatarUrl.isNotEmpty) 
                                                    ? NetworkImage(avatarUrl) 
                                                    : null;
                                              }(),
                                              backgroundColor: Colors.grey.shade300,
                                              child: () {
                                                final avatarUrl = _getCurrentAvatarUrl();
                                                return (avatarUrl == null || avatarUrl.isEmpty)
                                                    ? Icon(
                                                        Icons.person,
                                                        size: 30,
                                                        color: Colors.grey.shade600,
                                                      )
                                                    : null;
                                              }(),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userInfo['name']!,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                                  width: 40,
                                                  height: 3,
                                                  color: Colors.blue,
                                                ),
                                                Text(
                                                  userInfo['title']!,
                                                  style: TextStyle(
                                                    color: Colors.grey[600] ?? Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Contact methods
                                      if (userInfo.containsKey('contactMethods') && (userInfo['contactMethods'] as List).isNotEmpty) ...[
                                        _buildSectionTitle('Contact Methods:'),
                                        const SizedBox(height: 2),
                                        // Fixed height container with scrolling for contacts
                                        Flexible(
                                          // height: 135,
                                          flex: 2,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: (userInfo['contactMethods'] as List).map<Widget>((method) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                                  child: Row(
                                                    children: [
                                                      Icon(method['icon'], size: 14, color: method['color']),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              method['label'],
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.grey[800],
                                                              ),
                                                            ),
                                                            Text(
                                                              method['value'],
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[700],
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 4), // Reduced spacing

                                      // Business description
                                      _buildSectionTitle('Business Description:'),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          _truncateWithEllipsis(userInfo['description']!, 250), // Reduced character limit
                                          style: TextStyle(
                                            color: Colors.grey[700] ?? Colors.grey.shade700,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                          textAlign: TextAlign.left,
                                          maxLines: 5, // Reduced max lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      // Services
                                      _buildSectionTitle('Our Services:'),
                                      ...services.take(3).map((service) =>
                                          _buildServiceItem(_truncateWithEllipsis(service, _serviceNameCharLimit))
                                      ),
                                      if (services.length > 3)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 12, right: 12),
                                          child: Text(
                                            '${services.length - 3} more services...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),

                                      // View details button (with reduced margins)
                                      const SizedBox(height: 4), // Small spacing
                                      GestureDetector(
                                        onTap: _showDetailsDialog,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          margin: const EdgeInsets.only(bottom: 2, top: 4), // Reduced margin to bring closer to Edit Profile
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.touch_app, size: 14, color: Colors.blue[600] ?? Colors.blue),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Tap to view full details',
                                                style: TextStyle(
                                                  color: Colors.blue[600] ?? Colors.blue,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: _showEditForm,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 编辑按钮
                                      Expanded(
                                        child: InkWell(
                                          onTap: _showEditForm,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.edit, color: Colors.blue[700], size: 20),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Edit Profile',
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // 垂直分隔线
                                      Container(
                                        height: 24,
                                        width: 1,
                                        color: Colors.grey[300],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12), // 减少水平内边距
      child: Row(
        children: [
          Container(width: 3, height: 14, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String service) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4), // 减少内边距
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600] ?? Colors.green,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              service,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
              overflow: TextOverflow.ellipsis, // 确保文本超出时显示省略号
              maxLines: 1, // 限制为单行
            ),
          ),
        ],
      ),
    );
  }
}
