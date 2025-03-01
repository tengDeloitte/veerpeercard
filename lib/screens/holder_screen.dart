import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veerpeercard/providers/holder_screen_provider.dart';

class BusinessCard {
  final String name;
  final String title;
  final String company;
  final String phone;
  final String fax;
  final String address;
  final String email;
  final String image;
  final String category; // 分类字段

  BusinessCard({
    required this.name,
    required this.title,
    required this.company,
    required this.phone,
    required this.fax,
    required this.address,
    required this.email,
    required this.image,
    required this.category,
  });
}

class HolderScreen extends ConsumerWidget {
  const HolderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardState = ref.watch(providerHolderState); // 当前卡片状态
    final cardNotifier = ref.read(providerHolderState.notifier); // 状态管理器

// 使用BusinessCard类来创建数据
    final List<BusinessCard> cards = [
      BusinessCard(
        name: "John D. Smith",
        title: "Sales Manager",
        company: "ABC Auto Sales",
        phone: "(555)-555-5551",
        fax: "(555)-555-5552",
        address: "123 Auto Road\nDETROIT, MI 48201",
        email: "john.smith@abcauto.com",
        image: "https://via.placeholder.com/150",
        category: "Auto Sales",
      ),
      BusinessCard(
        name: "Emily D. King",
        title: "Insurance Agent",
        company: "King Insurance Co.",
        phone: "(555)-555-5553",
        fax: "(555)-555-5554",
        address: "456 Insurance Ave\nNEW YORK, NY 10001",
        email: "emily.king@kinginsurance.com",
        image: "https://via.placeholder.com/150",
        category: "Insurance",
      ),
      BusinessCard(
        name: "Jason D. White",
        title: "Real Estate Agent",
        company: "White Realty",
        phone: "(555)-555-5555",
        fax: "(555)-555-5556",
        address: "789 Property St\nLOS ANGELES, CA 90001",
        email: "jason.white@whiterealty.com",
        image: "https://via.placeholder.com/150",
        category: "Real Estate",
      ),
      BusinessCard(
        name: "Sarah Johnson",
        title: "Insurance Broker",
        company: "Johnson Insurance",
        phone: "(555)-555-5557",
        fax: "(555)-555-5558",
        address: "321 Coverage Blvd\nCHICAGO, IL 60601",
        email: "sarah.johnson@johnsoninsurance.com",
        image: "https://via.placeholder.com/150",
        category: "Insurance",
      ),
      BusinessCard(
        name: "Michael Chen",
        title: "Sales Representative",
        company: "Chen Auto Group",
        phone: "(555)-555-5559",
        fax: "(555)-555-5560",
        address: "654 Motor Drive\nHOUSTON, TX 77001",
        email: "michael.chen@chenauto.com",
        image: "https://via.placeholder.com/150",
        category: "Auto Sales",
      ),
    ];

    // 获取所有不重复的分类
    final Set<String> categories = cards.map((card) => card.category).toSet();
    final List<String> sortedCategories = categories.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // title: Text(
        //   'Business Cards',
        //   style: TextStyle(
        //     fontWeight: FontWeight.bold,
        //     letterSpacing: 0.5,
        //     color: Colors.black,
        //   ),
        // ),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 搜索功能
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 添加新名片功能
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: sortedCategories.map((category) {
            // 筛选属于当前类别的卡片
            final categoryCards = cards.where((card) => card.category == category).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类别标题
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${categoryCards.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 该类别下的卡片列表
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: categoryCards.length,
                  itemBuilder: (context, index) {
                    // 找出当前卡片在整个列表中的真实索引，用于状态管理
                    final cardIndex = cards.indexWhere((card) =>
                    card.name == categoryCards[index].name &&
                        card.category == categoryCards[index].category
                    );
                    final card = categoryCards[index];

                    return GestureDetector(
                      onTap: () {
                        // 点击卡片时，显示对话框
                        _showCardDialog(context, ref, card, cardIndex);
                      },
                      child: _buildCollapsedCard(card),
                    );
                  },
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // 显示卡片对话框
  void _showCardDialog(BuildContext context, WidgetRef ref, BusinessCard card, int index) {
    final cardNotifier = ref.read(providerHolderState.notifier);
    cardNotifier.saveState(index, false); // 保存状态但不显示背面

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Consumer(
                  builder: (context, ref, _) {
                    final showBack = ref.watch(providerHolderState.notifier).showBack;
                    return GestureDetector(
                      onTap: () {
                        cardNotifier.toggleCardFace();
                      },
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            final rotate = Tween(begin: pi, end: 0.0).animate(animation);
                            return AnimatedBuilder(
                              animation: rotate,
                              child: child,
                              builder: (context, child) {
                                final isUnder = showBack != (ValueKey('back') == child?.key);
                                final value = isUnder ? min(rotate.value, pi / 2) : rotate.value;
                                return Transform(
                                  transform: Matrix4.rotationY(value),
                                  alignment: Alignment.center,
                                  child: value < pi / 2 ? child : Container(),
                                );
                              },
                            );
                          },
                          child: showBack
                              ? _buildCardBack(card)
                              : _buildCardFront(card),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 底部操作按钮
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      icon: Icons.phone,
                      label: 'Call',
                      color: Colors.green.shade700,
                      onPressed: () {
                        // 打电话功能
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.message,
                      label: 'Message',
                      color: Colors.orange.shade700,
                      onPressed: () {
                        // 发短信功能
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.email,
                      label: 'Email',
                      color: Colors.blue.shade700,
                      onPressed: () {
                        // 发邮件功能
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.close,
                      label: 'Close',
                      color: Colors.grey.shade700,
                      onPressed: () {
                        Navigator.of(context).pop(); // 关闭对话框
                        cardNotifier.resetState(); // 重置状态
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedCard(BusinessCard card) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 左侧边条（可选）
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          // 头像部分
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(card.image),
                radius: 30,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 文字信息部分
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  card.company,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 右侧图标
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(BusinessCard card) {
    return Container(
      key: const ValueKey('front'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // 顶部公司名称栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // 公司名称
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade400, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    card.company.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // 业务信息区域
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 姓名
                Text(
                  card.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                // 装饰分隔线
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),

                // 职位
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // 业务描述标题
                Container(
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        color: Colors.blue.shade400,
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        'Business Description:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 业务描述内容
                Text(
                  '${card.company} specializes in providing premium ${card.category.toLowerCase()} services with over 10 years of industry experience. We focus on customer satisfaction and professional service.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 24),

                // 服务项目标题
                Container(
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        color: Colors.blue.shade400,
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        'Our Services:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 服务项目列表
                _buildServiceItem('Professional Consulting'),
                _buildServiceItem('Premium Products'),
                _buildServiceItem('After-sales Support'),
                _buildServiceItem('Quality Assurance'),

                const SizedBox(height: 20),

                // 底部提示文字
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to view contact details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            service,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(BusinessCard card) {
    return Container(
      key: const ValueKey('back'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // 顶部装饰条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  'CONTACT INFORMATION',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.company.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // 主要内容
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 联系人信息区块
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 联系人名称
                      Text(
                        card.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        card.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 联系方式标题
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      color: Colors.blue.shade400,
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(
                      'HOW TO REACH US',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 联系方式
                _buildContactItem(Icons.phone, card.phone),
                const Divider(height: 1, indent: 60, endIndent: 0),
                _buildContactItem(Icons.fax, card.fax),
                const Divider(height: 1, indent: 60, endIndent: 0),
                _buildContactItem(Icons.location_on, card.address, multiLine: true),
                const Divider(height: 1, indent: 60, endIndent: 0),
                _buildContactItem(Icons.email, card.email),

                const SizedBox(height: 24),

                // 业务时间
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      color: Colors.blue.shade400,
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(
                      'BUSINESS HOURS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBusinessHours('Mon - Fri', '9:00 AM - 6:00 PM'),
                      const SizedBox(height: 6),
                      _buildBusinessHours('Saturday', '10:00 AM - 4:00 PM'),
                      const SizedBox(height: 6),
                      _buildBusinessHours('Sunday', 'Closed'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 底部提示文字
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to see business information',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHours(String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          hours,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text, {bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}