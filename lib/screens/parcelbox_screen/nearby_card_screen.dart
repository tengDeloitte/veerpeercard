import 'package:flutter/material.dart';
import 'package:veerpeercard/services/nearby_card_service.dart';


class NearbyCardsScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const NearbyCardsScreen({
    Key? key,
    required this.userInfo,
  }) : super(key: key);

  @override
  State<NearbyCardsScreen> createState() => _NearbyCardsScreenState();
}

class _NearbyCardsScreenState extends State<NearbyCardsScreen> {
  final NearbyCardService _nearbyService = NearbyCardService();
  List<Map<String, dynamic>> _nearbyUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _nearbyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Business Cards'),
        actions: [
          // 位置可见性开关
          Row(
            children: [
              Text(
                _nearbyService.isVisible ? 'Visible' : 'Hidden',
                style: TextStyle(
                  fontSize: 14,
                  color: _nearbyService.isVisible ? Colors.green : Colors.grey,
                ),
              ),
              Switch(
                value: _nearbyService.isVisible,
                activeColor: Colors.green,
                onChanged: (value) async {
                  setState(() {
                    _isLoading = true;
                  });

                  if (value) {
                    final success = await _nearbyService.enableVisibility(widget.userInfo);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to enable location visibility'),
                        ),
                      );
                    }
                  } else {
                    await _nearbyService.disableVisibility();
                  }

                  setState(() {
                    _isLoading = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索说明卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _nearbyService.isVisible ? Icons.visibility : Icons.visibility_off,
                        color: _nearbyService.isVisible ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _nearbyService.isVisible
                              ? 'Your business card is visible to nearby users'
                              : 'Your business card is not visible to nearby users',
                          style: TextStyle(
                            color: _nearbyService.isVisible ? Colors.green : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enable visibility to appear in nearby search results. '
                        'Search to find business cards around you.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // 搜索按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _searchNearbyCards,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Search Nearby Business Cards'),
            ),
          ),

          // 搜索结果
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildInstructions(),
          ),
        ],
      ),
    );
  }

  // 搜索附近名片
  Future<void> _searchNearbyCards() async {
    setState(() {
      _isLoading = true;
    });

    // 执行搜索
    final results = await _nearbyService.searchNearbyCards();

    setState(() {
      _nearbyUsers = results;
      _isLoading = false;
      _isSearching = true;
    });
  }

  // 构建搜索结果
  Widget _buildSearchResults() {
    if (_nearbyUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No business cards found nearby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try again later or expand your search radius',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _searchNearbyCards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nearbyUsers.length,
        itemBuilder: (context, index) {
          final user = _nearbyUsers[index];
          final card = user['businessCard'];
          final double distanceInMeters = user['distance'];

          // 格式化距离显示
          String distanceText;
          if (distanceInMeters < 1000) {
            distanceText = '${distanceInMeters.round()} m';
          } else {
            final distanceInKm = distanceInMeters / 1000;
            distanceText = '${distanceInKm.toStringAsFixed(1)} km';
          }

          // 构建列表项
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showCardDetails(user),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // 头像
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(card['avatar']),
                    ),
                    const SizedBox(width: 16),

                    // 信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(card['title']),
                          Text(
                            card['companyName'],
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 距离和箭头
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            distanceText,
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 构建初始说明界面
  Widget _buildInstructions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.blue[200]),
          const SizedBox(height: 16),
          Text(
            'Search to discover nearby business cards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Enable visibility to share your card with others nearby. '
                  'Tap the search button to find business cards around you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示名片详情
  void _showCardDetails(Map<String, dynamic> user) {
    final card = user['businessCard'];
    final String userId = user['userId'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(card['avatar']),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    card['title'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      card['companyName'],
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 内容区
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 联系方式
                    const Text(
                      'Contact Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (card.containsKey('contactMethods'))
                      ...(card['contactMethods'] as List).map((method) {
                        return ListTile(
                          leading: Icon(
                            _getIconForContactMethod(method['type']),
                            color: _getColorForContactMethod(method['type']),
                          ),
                          title: Text(method['label']),
                          subtitle: Text(method['value']),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),

                    const Divider(),

                    // 业务描述
                    const Text(
                      'Business Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(card['description'] ?? 'No description provided'),

                    if (card.containsKey('services') &&
                        (card['services'] as List).isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        'Services:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...card['services'].map<Widget>((service) {
                        return Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(service)),
                          ],
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Contact'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddContactDialog(userId, card['name']);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示添加联系人对话框
  void _showAddContactDialog(String userId, String name) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send a request to add this person to your contacts. '
                  'You can include a brief message:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Hi, I found your card nearby...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final message = messageController.text.isEmpty
                  ? 'Hello, I would like to connect with you.'
                  : messageController.text;

              setState(() {
                _isLoading = true;
              });

              final success = await _nearbyService.sendFriendRequest(userId, message);

              setState(() {
                _isLoading = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Contact request sent successfully'
                        : 'Failed to send contact request',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  // 获取联系方式图标
  IconData _getIconForContactMethod(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'website':
        return Icons.language;
      case 'address':
        return Icons.location_on;
      default:
        return Icons.contact_page;
    }
  }

  // 获取联系方式颜色
  Color _getColorForContactMethod(String type) {
    switch (type) {
      case 'phone':
        return Colors.green;
      case 'email':
        return Colors.blue;
      case 'website':
        return Colors.purple;
      case 'address':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}