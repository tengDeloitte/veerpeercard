import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  Alignment _dragAlignment = Alignment.center;

  // 个人信息
  final Map<String, String> userInfo = {
    'companyName': 'CHEN AUTO GROUP',
    'name': 'Michael Chen',
    'title': 'Sales Representative',
    'avatar': 'https://via.placeholder.com/150',
    'description': 'Chen Auto Group specializes in providing premium auto sales services with over 10 years of industry experience. We focus on customer satisfaction and professional service.',
  };

  // 服务列表
  final List<String> services = [
    'Professional Consulting',
    'Premium Products',
    'After-sales Support',
    'Quality Assurance',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _controller.addListener(() {
      setState(() {
        _dragAlignment = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runAnimation(Offset pixelsPerSecond, Size size) {
    // 计算速度
    final unitsPerSecondX = pixelsPerSecond.dx / size.width;
    final unitsPerSecondY = pixelsPerSecond.dy / size.height;
    final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
    final unitVelocity = unitsPerSecond.distance;

    // 创建一个弹簧模拟
    const spring = SpringDescription(
      mass: 30,
      stiffness: 1,
      damping: 1,
    );

    final simulation = SpringSimulation(spring, 0, 1, -unitVelocity);

    // 动画从当前位置到随机位置，但限制在安全区域内
    final Alignment endAlignment = _getSafeRandomAlignment(size);

    _animation = _controller.drive(
      AlignmentTween(
        begin: _dragAlignment,
        end: endAlignment,
      ),
    );

    _controller.reset();
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

    // 获取带有随机偏移的新位置
    double newX = _dragAlignment.x + (_dragAlignment.x.abs() < 0.4 ? 0.4 : -0.4);
    double newY = _dragAlignment.y + (_dragAlignment.y.abs() < 0.4 ? 0.4 : -0.4);

    // 确保新位置在安全区域内
    newX = newX.clamp(-maxHorizontalAlignment, maxHorizontalAlignment);
    newY = newY.clamp(-maxVerticalAlignment, maxVerticalAlignment);

    return Alignment(newX, newY);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 保持名片原始尺寸
    final cardWidth = size.width * 0.67;

    return Scaffold(
      body: Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: Stack(
            children: [
              // 可拖动卡片区域 - 减少顶部和底部的边距
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 计算可移动的最大边界值 - 增加可移动范围
                    final cardHeight = constraints.maxHeight * 0.55;
                    final maxHorizontalAlignment = 0.9 - (cardWidth / constraints.maxWidth) / 2;
                    final maxVerticalAlignment = 0.9 - (cardHeight / constraints.maxHeight) / 2;

                    return GestureDetector(
                      onPanDown: (details) {
                        _controller.stop();
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          // 计算新位置
                          double newX = _dragAlignment.x + 2 * details.delta.dx / constraints.maxWidth;
                          double newY = _dragAlignment.y + 2 * details.delta.dy / constraints.maxHeight;

                          // 限制在安全区域内，但允许更大范围
                          newX = newX.clamp(-maxHorizontalAlignment, maxHorizontalAlignment);
                          newY = newY.clamp(-maxVerticalAlignment, maxVerticalAlignment);

                          _dragAlignment = Alignment(newX, newY);
                        });
                      },
                      onPanEnd: (details) {
                        _runAnimation(details.velocity.pixelsPerSecond, Size(constraints.maxWidth, constraints.maxHeight));
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
                                                  color: Colors.grey[600],
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

                                    // 业务描述内容
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12), // 减少水平内边距
                                      child: Text(
                                        userInfo['description']!,
                                        style: TextStyle(
                                          color: Colors.grey[700],
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

                                    // 服务列表
                                    ...services.map((service) => _buildServiceItem(service)),

                                    const SizedBox(height: 4), // 减少垂直间距

                                    // 查看联系方式提示
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      margin: const EdgeInsets.only(bottom: 4), // 减少下边距
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.touch_app, size: 12, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Tap to view contact details',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
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
                                      color: Colors.green[700]!,
                                      onPressed: () {},
                                    ),
                                    _buildActionButton(
                                      icon: Icons.message,
                                      label: 'Message',
                                      color: Colors.orange[700]!,
                                      onPressed: () {},
                                    ),
                                    _buildActionButton(
                                      icon: Icons.email,
                                      label: 'Email',
                                      color: Colors.blue[700]!,
                                      onPressed: () {},
                                    ),
                                    _buildActionButton(
                                      icon: Icons.close,
                                      label: 'Close',
                                      color: Colors.grey[700]!,
                                      onPressed: () {},
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
            color: Colors.green[600],
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            service,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
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
