import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  Alignment _dragAlignment = Alignment.center;
  final math.Random _random = math.Random();

  // 个人信息
  Map<String, String> userInfo = {
    'companyName': 'CHEN AUTO GROUP',
    'name': 'Michael Chen',
    'title': 'Sales Representative',
    'avatar': 'https://via.placeholder.com/150',
    'description': 'Chen Auto Group specializes in providing premium auto sales services with over 10 years of industry experience. We focus on customer satisfaction and professional service.',
  };

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
    _maxHorizontalAlignment = 0.95 - (cardWidth / size.width) / 2;
    _maxVerticalAlignment = 0.95 - (cardHeight / size.height) / 2;

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
        _currentVelocity = Offset(-_currentVelocity.dx * 0.7, _currentVelocity.dy);
        newX = newX.sign * _maxHorizontalAlignment;
      }

      if (newY.abs() > _maxVerticalAlignment) {
        // 碰到上下边界，Y方向速度反转
        _currentVelocity = Offset(_currentVelocity.dx, -_currentVelocity.dy * 0.7);
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
    final List<String> extraServices = services.length > 4
        ? services.sublist(4)
        : [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Company', userInfo['companyName']!),
              _buildDetailItem('Name', userInfo['name']!),
              _buildDetailItem('Title', userInfo['title']!),
              _buildDetailItem('Description', userInfo['description']!),
              const SizedBox(height: 10),
              const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...services.map((service) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Row(
                  children: [
                    Icon(
                        Icons.check_circle,
                        color: Colors.green[600] ?? Colors.green,
                        size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(service)),
                  ],
                ),
              )),
              if (extraServices.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Additional Services:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...extraServices.map((service) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(service)),
                    ],
                  ),
                )),
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

  // 显示编辑表单
  void _showEditForm() {
    // 创建临时变量来保存编辑值
    final Map<String, String> editedInfo = Map.from(userInfo);
    final List<String> editedServices = List.from(services);

    // 创建控制器
    final companyNameController = TextEditingController(text: editedInfo['companyName']);
    final nameController = TextEditingController(text: editedInfo['name']);
    final titleController = TextEditingController(text: editedInfo['title']);
    final descriptionController = TextEditingController(text: editedInfo['description']);

    // 服务项控制器列表 - 为每个服务创建一个控制器
    final List<TextEditingController> serviceControllers = editedServices
        .map((service) => TextEditingController(text: service))
        .toList();

    // 添加一个空的服务项控制器，用于添加新服务
    final newServiceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 公司名称
                          _buildFormField('Business Name/Company Name', companyNameController),
                          const SizedBox(height: 16),

                          // 头像和姓名、职位
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 头像
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(editedInfo['avatar']!),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      // 这里添加选择头像的功能
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

                          // 业务描述
                          _buildFormField('Business/Company Description', descriptionController, maxLines: 10),
                          const SizedBox(height: 16),

                          // 服务列表
                          const Text(
                            'Services/Skills:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // 使用单一StatefulBuilder包裹整个服务列表区域
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                children: [
                                  // 现有服务项列表
                                  ...List.generate(serviceControllers.length, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: serviceControllers[index],
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                serviceControllers.removeAt(index);
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
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            onSubmitted: (value) {
                                              if (value.isNotEmpty) {
                                                setState(() {
                                                  editedServices.add(value);
                                                  serviceControllers.add(TextEditingController(text: value));
                                                  newServiceController.clear();
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Colors.green),
                                          onPressed: () {
                                            if (newServiceController.text.isNotEmpty) {
                                              setState(() {
                                                editedServices.add(newServiceController.text);
                                                serviceControllers.add(TextEditingController(text: newServiceController.text));
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
                            userInfo['companyName'] = companyNameController.text;
                            userInfo['name'] = nameController.text;
                            userInfo['title'] = titleController.text;
                            userInfo['description'] = descriptionController.text;

                            // 更新服务列表
                            services = serviceControllers
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

  // 表单字段
  Widget _buildFormField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
    final cardWidth = size.width * 0.67;

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
                    final maxHorizontalAlignment = 0.95 - (cardWidth / constraints.maxWidth) / 2;
                    final maxVerticalAlignment = 0.95 - (cardHeight / constraints.maxHeight) / 2;

                    return GestureDetector(
                      onPanDown: (details) {
                        _controller.stop();
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          // 计算新位置，保持适度的速度系数
                          double newX = _dragAlignment.x + 4 * details.delta.dx / constraints.maxWidth;
                          double newY = _dragAlignment.y + 4 * details.delta.dy / constraints.maxHeight;

                          // 限制在安全区域内，但允许更大范围
                          newX = newX.clamp(-maxHorizontalAlignment, maxHorizontalAlignment);
                          newY = newY.clamp(-maxVerticalAlignment, maxVerticalAlignment);

                          _dragAlignment = Alignment(newX, newY);
                        });
                      },
                      onPanEnd: (details) {
                        // 获取手指释放时的速度
                        _runAnimation(
                            details.velocity.pixelsPerSecond,
                            Size(constraints.maxWidth, constraints.maxHeight)
                        );
                      },
                      child: Align(
                        alignment: _dragAlignment,
                        child: Container(
                          width: cardWidth,
                          // 不设置固定高度，让内容决定高度
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
                            mainAxisSize: MainAxisSize.min, // 关键：让Column根据内容调整大小
                            children: [
                              // 卡片内容区域 - 减少内部padding
                              Padding(
                                padding: const EdgeInsets.all(8), // 减少内边距
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 公司名称
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

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8), // 减少水平内边距
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // 头像
                                          CircleAvatar(
                                            radius: 25,
                                            backgroundImage: NetworkImage(userInfo['avatar']!),
                                          ),
                                          const SizedBox(width: 12),
                                          // 姓名、职位和装饰线在同一列
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
                                              // 装饰线
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

                                    const SizedBox(height: 8), // 减少垂直间距

                                    // 业务描述标题
                                    _buildSectionTitle('Business Description:'),

                                    const SizedBox(height: 2), // 减少垂直间距

                                    // 业务描述内容 - 使用截断的文本
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12), // 减少水平内边距
                                      child: Text(
                                        _truncateWithEllipsis(userInfo['description']!, _descriptionCharLimit),
                                        style: TextStyle(
                                          color: Colors.grey[700] ?? Colors.grey.shade700,
                                          fontSize: 12,
                                          height: 1.3, // 减少行高
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),

                                    const SizedBox(height: 6), // 减少垂直间距

                                    // 服务标题
                                    _buildSectionTitle('Our Services:'),

                                    const SizedBox(height: 2), // 减少垂直间距

                                    // 服务列表 - 只显示前4个，并且每个服务项使用截断的文本
                                    ...services.take(4).map((service) =>
                                        _buildServiceItem(_truncateWithEllipsis(service, _serviceNameCharLimit))
                                    ),

                                    const SizedBox(height: 4), // 减少垂直间距

                                    // 查看联系方式提示 - 添加点击事件
                                    GestureDetector(
                                      onTap: _showDetailsDialog,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        margin: const EdgeInsets.only(top: 2, bottom: 4), // 调整边距
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

                              // 底部操作按钮
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8), // 减少垂直内边距
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.call,
                                      label: 'Call',
                                      color: Colors.green[700] ?? Colors.green,
                                      onPressed: () {},
                                    ),
                                    _buildActionButton(
                                      icon: Icons.message,
                                      label: 'Message',
                                      color: Colors.orange[700] ?? Colors.orange,
                                      onPressed: () {},
                                    ),
                                    _buildActionButton(
                                      icon: Icons.email,
                                      label: 'Email',
                                      color: Colors.blue[700] ?? Colors.blue,
                                      onPressed: () {},
                                    ),
                                    _buildActionButton(
                                      icon: Icons.edit,
                                      label: 'Edit',
                                      color: Colors.blue[700] ?? Colors.blue,
                                      onPressed: _showEditForm,
                                    ),
                                  ],
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12), // 减少水平内边距
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            color: Colors.blue,
          ),
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
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis, // 确保文本超出时显示省略号
              maxLines: 1, // 限制为单行
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2), // 减少垂直间距
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/physics.dart';
//
// class MeScreen extends StatefulWidget {
//   const MeScreen({super.key});
//
//   @override
//   State<MeScreen> createState() => _MeScreenState();
// }
//
// class _MeScreenState extends State<MeScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Alignment> _animation;
//   Alignment _dragAlignment = Alignment.center;
//
//   // 个人信息
//   Map<String, String> userInfo = {
//     'companyName': 'CHEN AUTO GROUP',
//     'name': 'Michael Chen',
//     'title': 'Sales Representative',
//     'avatar': 'https://via.placeholder.com/150',
//     'description': 'Chen Auto Group specializes in providing premium auto sales services with over 10 years of industry experience. We focus on customer satisfaction and professional service.',
//   };
//
//   // 服务列表
//   List<String> services = [
//     'Professional Consulting',
//     'Premium Products',
//     'After-sales Support',
//     'Quality Assurance',
//   ];
//
//   // 文本内容长度限制
//   final int _descriptionCharLimit = 380;
//   final int _serviceNameCharLimit = 25;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     );
//
//     _controller.addListener(() {
//       setState(() {
//         _dragAlignment = _animation.value;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _runAnimation(Offset pixelsPerSecond, Size size) {
//     // 计算速度
//     final unitsPerSecondX = pixelsPerSecond.dx / size.width;
//     final unitsPerSecondY = pixelsPerSecond.dy / size.height;
//     final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
//     final unitVelocity = unitsPerSecond.distance;
//
//     // 创建一个弹簧模拟
//     const spring = SpringDescription(
//       mass: 10,
//       stiffness: 1,
//       damping: 1,
//     );
//
//     final simulation = SpringSimulation(spring, 0, 1, -unitVelocity);
//
//     // 动画从当前位置到随机位置，但限制在安全区域内
//     final Alignment endAlignment = _getSafeRandomAlignment(size);
//
//     _animation = _controller.drive(
//       AlignmentTween(
//         begin: _dragAlignment,
//         end: endAlignment,
//       ),
//     );
//
//     _controller.reset();
//     _controller.forward();
//   }
//
//   // 获取随机对齐位置，但保持在屏幕安全范围内
//   Alignment _getSafeRandomAlignment(Size size) {
//     // 使用与屏幕大小相关的边界计算
//     final cardWidth = size.width * 0.65;
//     final cardHeight = size.height * 0.55; // 估计卡片高度
//
//     // 允许卡片移动到接近屏幕边缘
//     final maxHorizontalAlignment = 0.9 - (cardWidth / size.width) / 2;
//     final maxVerticalAlignment = 0.9 - (cardHeight / size.height) / 2;
//
//     // 获取带有随机偏移的新位置
//     double newX = _dragAlignment.x + (_dragAlignment.x.abs() < 0.4 ? 0.4 : -0.4);
//     double newY = _dragAlignment.y + (_dragAlignment.y.abs() < 0.4 ? 0.4 : -0.4);
//
//     // 确保新位置在安全区域内
//     newX = newX.clamp(-maxHorizontalAlignment, maxHorizontalAlignment);
//     newY = newY.clamp(-maxVerticalAlignment, maxVerticalAlignment);
//
//     return Alignment(newX, newY);
//   }
//
//   // 对长文本进行截断并添加省略号
//   String _truncateWithEllipsis(String text, int maxLength) {
//     return text.length <= maxLength
//         ? text
//         : '${text.substring(0, maxLength)}...';
//   }
//
//   // 显示详细信息对话框
//   void _showDetailsDialog() {
//     // 计算哪些服务需要额外显示
//     final List<String> extraServices = services.length > 4
//         ? services.sublist(4)
//         : [];
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Contact Details'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildDetailItem('Company', userInfo['companyName']!),
//               _buildDetailItem('Name', userInfo['name']!),
//               _buildDetailItem('Title', userInfo['title']!),
//               _buildDetailItem('Description', userInfo['description']!),
//               const SizedBox(height: 10),
//               const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
//               ...services.map((service) => Padding(
//                 padding: const EdgeInsets.only(left: 8.0, top: 4.0),
//                 child: Row(
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.green[600], size: 16),
//                     const SizedBox(width: 8),
//                     Expanded(child: Text(service)),
//                   ],
//                 ),
//               )),
//               if (extraServices.isNotEmpty) ...[
//                 const SizedBox(height: 10),
//                 const Text('Additional Services:', style: TextStyle(fontWeight: FontWeight.bold)),
//                 ...extraServices.map((service) => Padding(
//                   padding: const EdgeInsets.only(left: 8.0, top: 4.0),
//                   child: Row(
//                     children: [
//                       Icon(Icons.check_circle, color: Colors.green[600], size: 16),
//                       const SizedBox(width: 8),
//                       Expanded(child: Text(service)),
//                     ],
//                   ),
//                 )),
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 详细信息条目
//   Widget _buildDetailItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 4),
//           Text(value),
//         ],
//       ),
//     );
//   }
//
//   // 显示编辑表单
//   void _showEditForm() {
//     // 创建临时变量来保存编辑值
//     final Map<String, String> editedInfo = Map.from(userInfo);
//     final List<String> editedServices = List.from(services);
//
//     // 创建控制器
//     final companyNameController = TextEditingController(text: editedInfo['companyName']);
//     final nameController = TextEditingController(text: editedInfo['name']);
//     final titleController = TextEditingController(text: editedInfo['title']);
//     final descriptionController = TextEditingController(text: editedInfo['description']);
//
//     // 服务项控制器列表 - 为每个服务创建一个控制器
//     final List<TextEditingController> serviceControllers = editedServices
//         .map((service) => TextEditingController(text: service))
//         .toList();
//
//     // 添加一个空的服务项控制器，用于添加新服务
//     final newServiceController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//           child: Container(
//             constraints: BoxConstraints(
//               maxHeight: MediaQuery.of(context).size.height * 0.8,
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   const Text(
//                     'Edit Profile Information',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // 公司名称
//                           _buildFormField('Business Name/Company Name', companyNameController),
//                           const SizedBox(height: 16),
//
//                           // 头像和姓名、职位
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // 头像
//                               Column(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 30,
//                                     backgroundImage: NetworkImage(editedInfo['avatar']!),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   TextButton(
//                                     onPressed: () {
//                                       // 这里添加选择头像的功能
//                                     },
//                                     child: const Text('Update Avatar'),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(width: 16),
//                               // 姓名和职位
//                               Expanded(
//                                 child: Column(
//                                   children: [
//                                     _buildFormField('Name', nameController),
//                                     const SizedBox(height: 16),
//                                     _buildFormField('Title', titleController),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//
//                           // 业务描述
//                           _buildFormField('Business/Company Description', descriptionController, maxLines: 10),
//                           const SizedBox(height: 16),
//
//                           // 服务列表
//                           const Text(
//                             'Services/Skills:',
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 8),
//
//                           // 使用单一StatefulBuilder包裹整个服务列表区域
//                           StatefulBuilder(
//                             builder: (context, setState) {
//                               return Column(
//                                 children: [
//                                   // 现有服务项列表
//                                   ...List.generate(serviceControllers.length, (index) {
//                                     return Padding(
//                                       padding: const EdgeInsets.only(bottom: 8.0),
//                                       child: Row(
//                                         children: [
//                                           Expanded(
//                                             child: TextField(
//                                               controller: serviceControllers[index],
//                                               decoration: const InputDecoration(
//                                                 border: OutlineInputBorder(),
//                                                 contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                               ),
//                                             ),
//                                           ),
//                                           IconButton(
//                                             icon: const Icon(Icons.delete, color: Colors.red),
//                                             onPressed: () {
//                                               setState(() {
//                                                 serviceControllers.removeAt(index);
//                                                 editedServices.removeAt(index);
//                                               });
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   }),
//
//                                   // 添加新服务项
//                                   Padding(
//                                     padding: const EdgeInsets.only(top: 8.0),
//                                     child: Row(
//                                       children: [
//                                         Expanded(
//                                           child: TextField(
//                                             controller: newServiceController,
//                                             decoration: const InputDecoration(
//                                               border: OutlineInputBorder(),
//                                               hintText: 'Add new service',
//                                               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                             ),
//                                             onSubmitted: (value) {
//                                               if (value.isNotEmpty) {
//                                                 setState(() {
//                                                   editedServices.add(value);
//                                                   serviceControllers.add(TextEditingController(text: value));
//                                                   newServiceController.clear();
//                                                 });
//                                               }
//                                             },
//                                           ),
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.add, color: Colors.green),
//                                           onPressed: () {
//                                             if (newServiceController.text.isNotEmpty) {
//                                               setState(() {
//                                                 editedServices.add(newServiceController.text);
//                                                 serviceControllers.add(TextEditingController(text: newServiceController.text));
//                                                 newServiceController.clear();
//                                               });
//                                             }
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         child: const Text('Cancel'),
//                       ),
//                       ElevatedButton(
//                         onPressed: () {
//                           // 更新信息
//                           setState(() {
//                             userInfo['companyName'] = companyNameController.text;
//                             userInfo['name'] = nameController.text;
//                             userInfo['title'] = titleController.text;
//                             userInfo['description'] = descriptionController.text;
//
//                             // 更新服务列表
//                             services = serviceControllers
//                                 .map((controller) => controller.text)
//                                 .where((text) => text.isNotEmpty)
//                                 .toList();
//                           });
//                           Navigator.of(context).pop();
//                         },
//                         child: const Text('Save'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // 表单字段
//   Widget _buildFormField(String label, TextEditingController controller, {int maxLines = 1}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           maxLines: maxLines,
//           decoration: const InputDecoration(
//             border: OutlineInputBorder(),
//             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     // 保持名片原始尺寸
//     final cardWidth = size.width * 0.67;
//
//     return Scaffold(
//       body: Container(
//         color: Colors.grey[50],
//         child: SafeArea(
//           child: Stack(
//             children: [
//               // 可拖动卡片区域 - 减少顶部和底部的边距
//               Positioned.fill(
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     // 计算可移动的最大边界值 - 增加可移动范围
//                     final cardHeight = constraints.maxHeight * 0.55;
//                     final maxHorizontalAlignment = 0.9 - (cardWidth / constraints.maxWidth) / 2;
//                     final maxVerticalAlignment = 0.9 - (cardHeight / constraints.maxHeight) / 2;
//
//                     return GestureDetector(
//                       onPanDown: (details) {
//                         _controller.stop();
//                       },
//                       onPanUpdate: (details) {
//                         setState(() {
//                           // 计算新位置
//                           double newX = _dragAlignment.x + 2 * details.delta.dx / constraints.maxWidth;
//                           double newY = _dragAlignment.y + 2 * details.delta.dy / constraints.maxHeight;
//
//                           // 限制在安全区域内，但允许更大范围
//                           newX = newX.clamp(-maxHorizontalAlignment, maxHorizontalAlignment);
//                           newY = newY.clamp(-maxVerticalAlignment, maxVerticalAlignment);
//
//                           _dragAlignment = Alignment(newX, newY);
//                         });
//                       },
//                       onPanEnd: (details) {
//                         _runAnimation(details.velocity.pixelsPerSecond, Size(constraints.maxWidth, constraints.maxHeight));
//                       },
//                       child: Align(
//                         alignment: _dragAlignment,
//                         child: Container(
//                           width: cardWidth,
//                           // 不设置固定高度，让内容决定高度
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.grey.withOpacity(0.3),
//                                 spreadRadius: 3,
//                                 blurRadius: 7,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min, // 关键：让Column根据内容调整大小
//                             children: [
//                               // 卡片内容区域 - 减少内部padding
//                               Padding(
//                                 padding: const EdgeInsets.all(8), // 减少内边距
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     // 公司名称
//                                     Container(
//                                       margin: const EdgeInsets.only(top: 8, bottom: 12),
//                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                                       decoration: BoxDecoration(
//                                         border: Border.all(color: Colors.blue, width: 1),
//                                         borderRadius: BorderRadius.circular(4),
//                                       ),
//                                       child: Text(
//                                         userInfo['companyName']!,
//                                         style: const TextStyle(
//                                           color: Colors.blue,
//                                           fontWeight: FontWeight.w500,
//                                           fontSize: 14,
//                                         ),
//                                       ),
//                                     ),
//
//                                     Padding(
//                                       padding: const EdgeInsets.symmetric(horizontal: 8), // 减少水平内边距
//                                       child: Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           // 头像
//                                           CircleAvatar(
//                                             radius: 25,
//                                             backgroundImage: NetworkImage(userInfo['avatar']!),
//                                           ),
//                                           const SizedBox(width: 12),
//                                           // 姓名、职位和装饰线在同一列
//                                           Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 userInfo['name']!,
//                                                 style: const TextStyle(
//                                                   color: Colors.black87,
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 16,
//                                                 ),
//                                               ),
//                                               // 装饰线
//                                               Container(
//                                                 margin: const EdgeInsets.symmetric(vertical: 4),
//                                                 width: 40,
//                                                 height: 3,
//                                                 color: Colors.blue,
//                                               ),
//                                               Text(
//                                                 userInfo['title']!,
//                                                 style: TextStyle(
//                                                   color: Colors.grey[600],
//                                                   fontSize: 12,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//
//                                     const SizedBox(height: 8), // 减少垂直间距
//
//                                     // 业务描述标题
//                                     _buildSectionTitle('Business Description:'),
//
//                                     const SizedBox(height: 2), // 减少垂直间距
//
//                                     // 业务描述内容 - 使用截断的文本
//                                     Padding(
//                                       padding: const EdgeInsets.symmetric(horizontal: 12), // 减少水平内边距
//                                       child: Text(
//                                         _truncateWithEllipsis(userInfo['description']!, _descriptionCharLimit),
//                                         style: TextStyle(
//                                           color: Colors.grey[700],
//                                           fontSize: 12,
//                                           height: 1.3, // 减少行高
//                                         ),
//                                         textAlign: TextAlign.left,
//                                       ),
//                                     ),
//
//                                     const SizedBox(height: 6), // 减少垂直间距
//
//                                     // 服务标题
//                                     _buildSectionTitle('Our Services:'),
//
//                                     const SizedBox(height: 2), // 减少垂直间距
//
//                                     // 服务列表 - 只显示前4个，并且每个服务项使用截断的文本
//                                     ...services.take(4).map((service) =>
//                                         _buildServiceItem(_truncateWithEllipsis(service, _serviceNameCharLimit))
//                                     ),
//
//                                     const SizedBox(height: 4), // 减少垂直间距
//
//                                     // 查看联系方式提示 - 添加点击事件
//                                     GestureDetector(
//                                       onTap: _showDetailsDialog,
//                                       child: Container(
//                                         width: double.infinity,
//                                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                         margin: const EdgeInsets.only(top: 2, bottom: 4), // 调整边距
//                                         decoration: BoxDecoration(
//                                           color: Colors.blue.withOpacity(0.1),
//                                           borderRadius: BorderRadius.circular(20),
//                                         ),
//                                         child: Row(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             Icon(Icons.touch_app, size: 14, color: Colors.blue[600]),
//                                             const SizedBox(width: 6),
//                                             Text(
//                                               'Tap to view full details',
//                                               style: TextStyle(
//                                                 color: Colors.blue[600],
//                                                 fontSize: 12,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//
//                               // 底部操作按钮
//                               Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.symmetric(vertical: 8), // 减少垂直内边距
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[200],
//                                   borderRadius: const BorderRadius.only(
//                                     bottomLeft: Radius.circular(16),
//                                     bottomRight: Radius.circular(16),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                   children: [
//                                     _buildActionButton(
//                                       icon: Icons.call,
//                                       label: 'Call',
//                                       color: Colors.green[700]!,
//                                       onPressed: () {},
//                                     ),
//                                     _buildActionButton(
//                                       icon: Icons.message,
//                                       label: 'Message',
//                                       color: Colors.orange[700]!,
//                                       onPressed: () {},
//                                     ),
//                                     _buildActionButton(
//                                       icon: Icons.email,
//                                       label: 'Email',
//                                       color: Colors.blue[700]!,
//                                       onPressed: () {},
//                                     ),
//                                     _buildActionButton(
//                                       icon: Icons.edit,
//                                       label: 'Edit',
//                                       color: Colors.blue[700]!,
//                                       onPressed: _showEditForm,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12), // 减少水平内边距
//       child: Row(
//         children: [
//           Container(
//             width: 3,
//             height: 14,
//             color: Colors.blue,
//           ),
//           const SizedBox(width: 6),
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.black87,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildServiceItem(String service) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4), // 减少内边距
//       child: Row(
//         children: [
//           Icon(
//             Icons.check_circle,
//             color: Colors.green[600],
//             size: 14,
//           ),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Text(
//               service,
//               style: TextStyle(
//                 color: Colors.grey[700],
//                 fontSize: 12,
//               ),
//               overflow: TextOverflow.ellipsis, // 确保文本超出时显示省略号
//               maxLines: 1, // 限制为单行
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onPressed,
//   }) {
//     return InkWell(
//       onTap: onPressed,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(height: 2), // 减少垂直间距
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }