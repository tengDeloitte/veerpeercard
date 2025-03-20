import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veerpeercard/providers/parcelbox_screen_provider.dart';


class ParcelboxScreen extends ConsumerStatefulWidget {
  const ParcelboxScreen({super.key});

  @override
  ConsumerState<ParcelboxScreen> createState() => _ParcelboxScreenState();
}

class _ParcelboxScreenState extends ConsumerState<ParcelboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 监听标签变化，更新provider
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(selectedTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听选中的标签索引
    final selectedTab = ref.watch(selectedTabProvider);

    // 确保TabController与当前选中的标签保持同步
    if (_tabController.index != selectedTab) {
      _tabController.index = selectedTab;
    }

    // 监听位置可见性状态
    final isNearbyEnabled = ref.watch(nearbyVisibilityProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // 切换位置可见性
          Row(
            children: [
              Text(
                isNearbyEnabled ? 'Visible' : 'Hidden',
                style: TextStyle(
                  fontSize: 14,
                  color: isNearbyEnabled ? Colors.green : Colors.grey,
                ),
              ),
              Switch(
                value: isNearbyEnabled,
                activeColor: Colors.green,
                onChanged: (value) async {
                  if (value) {
                    await ref.read(nearbyVisibilityProvider.notifier).enableVisibility();
                  } else {
                    await ref.read(nearbyVisibilityProvider.notifier).disableVisibility();
                  }
                },
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.0,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              tabs: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 16),
                      SizedBox(width: 6),
                      Text('Nearby Cards'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 16),
                      SizedBox(width: 6),
                      Text('Friend Requests'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 附近名片标签页
          const _NearbyCardsTab(),

          // 好友请求标签页
          const _FriendRequestsTab(),
        ],
      ),
      floatingActionButton: selectedTab == 0
          ? FloatingActionButton(
        onPressed: () {
          ref.read(nearbyUsersProvider.notifier).searchNearbyUsers();
        },
        tooltip: 'Search for nearby cards',
        child: const Icon(Icons.search),
      )
          : null,
    );
  }
}

// 附近名片标签页
class _NearbyCardsTab extends ConsumerWidget {
  const _NearbyCardsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听附近用户列表状态
    final nearbyUsersAsync = ref.watch(nearbyUsersProvider);

    return nearbyUsersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading nearby cards',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      data: (nearbyUsers) {
        if (nearbyUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 64, color: Colors.blue[200]),
                const SizedBox(height: 16),
                Text(
                  'Discover business cards nearby',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Press the search button to find business cards around you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(nearbyUsersProvider.notifier).searchNearbyUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: nearbyUsers.length,
            itemBuilder: (context, index) {
              final user = nearbyUsers[index];
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

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _showCardDetails(context, ref, user),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 头像
                        CircleAvatar(
                          radius: 32,
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
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card['title'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card['companyName'],
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.place,
                                          size: 14,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          distanceText,
                                          style: TextStyle(
                                            color: Colors.green[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 右侧图标
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 显示名片详情
  void _showCardDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    final card = user['businessCard'];
    final String userId = user['userId'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                      radius: 40,
                      backgroundImage: NetworkImage(card['avatar']),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card['name'],
                      style: const TextStyle(
                        fontSize: 22,
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
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Contact'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddContactDialog(context, ref, userId, card['name']);
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

  // 显示添加联系人对话框
  void _showAddContactDialog(BuildContext context, WidgetRef ref, String userId, String name) {
    final messageController = TextEditingController();
    final nearbyService = ref.read(nearbyCardServiceProvider);

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

              // 显示加载指示器
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sending request...'),
                  duration: Duration(seconds: 1),
                ),
              );

              final success = await nearbyService.sendFriendRequest(userId, message);

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

// 好友请求标签页
class _FriendRequestsTab extends ConsumerWidget {
  const _FriendRequestsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听好友请求列表状态
    final friendRequestsAsync = ref.watch(friendRequestsProvider);

    return friendRequestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
    const SizedBox(height: 16),
          Text(
            'Error loading friend requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
        ),
        ),
      data: (friendRequests) {
        if (friendRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_disabled, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No pending friend requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When someone wants to connect, you\'ll see their request here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friendRequests.length,
          itemBuilder: (context, index) {
            final request = friendRequests[index];
            final senderInfo = request['senderInfo'];
            final message = request['message'];
            final Timestamp? createdAt = request['createdAt'];

            // 格式化时间
            String timeText = 'Recently';
            if (createdAt != null) {
              final date = createdAt.toDate();
              final now = DateTime.now();
              final difference = now.difference(date);

              if (difference.inMinutes < 60) {
                timeText = '${difference.inMinutes} min ago';
              } else if (difference.inHours < 24) {
                timeText = '${difference.inHours} hours ago';
              } else {
                timeText = '${difference.inDays} days ago';
              }
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(senderInfo['avatar']),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                senderInfo['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                senderInfo['title'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeText,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // 公司名
                    Padding(
                      padding: const EdgeInsets.only(left: 60),
                      child: Text(
                        senderInfo['companyName'],
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // 消息内容
                    if (message != null && message.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // 按钮行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            ref.read(friendRequestsProvider.notifier).handleFriendRequest(
                              request['requestId'],
                              false, // 拒绝
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(friendRequestsProvider.notifier).handleFriendRequest(
                              request['requestId'],
                              true, // 接受
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:veerpeercard/services/nearby_card_service.dart';
//
// class ParcelboxScreen extends StatefulWidget {
//   const ParcelboxScreen({super.key});
//
//   @override
//   State<ParcelboxScreen> createState() => _ParcelboxScreenState();
// }
//
// class _ParcelboxScreenState extends State<ParcelboxScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final NearbyCardService _nearbyService = NearbyCardService();
//
//   List<Map<String, dynamic>> _nearbyUsers = [];
//   List<Map<String, dynamic>> _friendRequests = [];
//
//   bool _isLoading = false;
//   bool _isNearbyEnabled = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _checkNearbyStatus();
//     _loadFriendRequests();
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   // 检查附近功能状态
//   Future<void> _checkNearbyStatus() async {
//     setState(() {
//       _isNearbyEnabled = _nearbyService.isVisible;
//     });
//   }
//
//   // 加载好友请求
//   Future<void> _loadFriendRequests() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final snapshot = await _firestore
//             .collection('friendRequests')
//             .where('toUserId', isEqualTo: user.uid)
//             .where('status', isEqualTo: 'pending')
//             .orderBy('createdAt', descending: true)
//             .get();
//
//         List<Map<String, dynamic>> requests = [];
//
//         for (var doc in snapshot.docs) {
//           final data = doc.data();
//
//           // 获取发送者信息
//           final senderSnapshot = await _firestore
//               .collection('nearbyUsers')
//               .doc(data['fromUserId'])
//               .get();
//
//           if (senderSnapshot.exists) {
//             final senderData = senderSnapshot.data();
//
//             requests.add({
//               'requestId': doc.id,
//               'fromUserId': data['fromUserId'],
//               'message': data['message'],
//               'createdAt': data['createdAt'],
//               'senderInfo': senderData?['businessCard'] ?? {},
//             });
//           }
//         }
//
//         setState(() {
//           _friendRequests = requests;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading friend requests: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   // 搜索附近用户
//   Future<void> _searchNearbyUsers() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       // 获取当前用户信息
//       final userInfo = await _getUserBusinessCard();
//
//       // 如果需要，启用位置可见性
//       if (!_isNearbyEnabled) {
//         final success = await _nearbyService.enableVisibility(userInfo);
//         if (success) {
//           setState(() {
//             _isNearbyEnabled = true;
//           });
//         }
//       }
//
//       // 搜索附近用户
//       final nearbyUsers = await _nearbyService.searchNearbyCards();
//
//       setState(() {
//         _nearbyUsers = nearbyUsers;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error searching nearby users: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   // 获取用户名片信息
//   Future<Map<String, dynamic>> _getUserBusinessCard() async {
//     // 这里是示例数据，实际中你需要从数据库或本地存储获取
//     return {
//       'companyName': 'CHEN AUTO GROUP',
//       'name': 'Michael Chen',
//       'title': 'Sales Representative',
//       'avatar': 'https://via.placeholder.com/150',
//       'description': 'Chen Auto Group specializes in providing premium auto sales services with over 10 years of industry experience.',
//       'contactMethods': [
//         {
//           'label': 'Phone',
//           'value': '+1 (555) 123-4567',
//           'icon': Icons.phone,
//           'color': Colors.green,
//           'type': 'phone',
//         },
//         {
//           'label': 'Email',
//           'value': 'michael.chen@example.com',
//           'icon': Icons.email,
//           'color': Colors.blue,
//           'type': 'email',
//         },
//       ],
//     };
//   }
//
//   // 处理好友请求
//   Future<void> _handleFriendRequest(String requestId, bool accept) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       await _firestore
//           .collection('friendRequests')
//           .doc(requestId)
//           .update({
//         'status': accept ? 'accepted' : 'rejected',
//         'processedAt': FieldValue.serverTimestamp(),
//       });
//
//       if (accept) {
//         // 如果接受，创建联系人关系
//         final request = _friendRequests.firstWhere((req) => req['requestId'] == requestId);
//
//         // 获取当前用户ID
//         final currentUserId = _auth.currentUser?.uid;
//         if (currentUserId != null) {
//           // 创建双向联系人关系
//           final batch = _firestore.batch();
//
//           // 添加到当前用户的联系人列表
//           final currentUserContactRef = _firestore
//               .collection('users')
//               .doc(currentUserId)
//               .collection('contacts')
//               .doc(request['fromUserId']);
//
//           batch.set(currentUserContactRef, {
//             'userId': request['fromUserId'],
//             'businessCard': request['senderInfo'],
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//
//           // 添加到发送请求用户的联系人列表
//           final senderContactRef = _firestore
//               .collection('users')
//               .doc(request['fromUserId'])
//               .collection('contacts')
//               .doc(currentUserId);
//
//           // 获取当前用户的名片信息
//           final currentUserCard = await _getUserBusinessCard();
//
//           batch.set(senderContactRef, {
//             'userId': currentUserId,
//             'businessCard': currentUserCard,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//
//           // 提交批处理
//           await batch.commit();
//         }
//       }
//
//       // 刷新请求列表
//       await _loadFriendRequests();
//
//       // 显示成功消息
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(accept ? 'Contact added successfully!' : 'Request rejected'),
//           backgroundColor: accept ? Colors.green : Colors.grey,
//         ),
//       );
//     } catch (e) {
//       print('Error handling friend request: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error processing request: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(48.0),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(
//                 bottom: BorderSide(
//                   color: Colors.grey.shade200,
//                   width: 1.0,
//                 ),
//               ),
//             ),
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.blue,
//               indicatorWeight: 3.0,
//               indicatorSize: TabBarIndicatorSize.label,
//               labelColor: Colors.blue.shade700,
//               unselectedLabelColor: Colors.grey.shade500,
//               labelStyle: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 15,
//               ),
//               unselectedLabelStyle: const TextStyle(
//                 fontWeight: FontWeight.w500,
//                 fontSize: 15,
//               ),
//               tabs: const [
//                 Padding(
//                   padding: EdgeInsets.symmetric(vertical: 12.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.location_on, size: 16),
//                       SizedBox(width: 6),
//                       Text('Nearby Cards'),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.symmetric(vertical: 12.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.person_add, size: 16),
//                       SizedBox(width: 6),
//                       Text('Friend Requests'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           // 切换位置可见性
//           Row(
//             children: [
//               Text(
//                 _isNearbyEnabled ? 'Visible' : 'Hidden',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: _isNearbyEnabled ? Colors.green : Colors.grey,
//                 ),
//               ),
//               Switch(
//                 value: _isNearbyEnabled,
//                 activeColor: Colors.green,
//                 onChanged: (value) async {
//                   if (value) {
//                     final userInfo = await _getUserBusinessCard();
//                     final success = await _nearbyService.enableVisibility(userInfo);
//                     if (success) {
//                       setState(() {
//                         _isNearbyEnabled = true;
//                       });
//                     }
//                   } else {
//                     await _nearbyService.disableVisibility();
//                     setState(() {
//                       _isNearbyEnabled = false;
//                     });
//                   }
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : TabBarView(
//         controller: _tabController,
//         children: [
//           // 附近名片标签页
//           _buildNearbyCardsTab(),
//
//           // 好友请求标签页
//           _buildFriendRequestsTab(),
//         ],
//       ),
//     );
//   }
//
//   // 构建附近名片标签页
//   Widget _buildNearbyCardsTab() {
//     if (_nearbyUsers.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.location_on, size: 64, color: Colors.blue[200]),
//             const SizedBox(height: 16),
//             Text(
//               'Discover business cards nearby',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 'Press the search button to find business cards around you',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return RefreshIndicator(
//       onRefresh: _searchNearbyUsers,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: _nearbyUsers.length,
//         itemBuilder: (context, index) {
//           final user = _nearbyUsers[index];
//           final card = user['businessCard'];
//           final double distanceInMeters = user['distance'];
//
//           // 格式化距离显示
//           String distanceText;
//           if (distanceInMeters < 1000) {
//             distanceText = '${distanceInMeters.round()} m';
//           } else {
//             final distanceInKm = distanceInMeters / 1000;
//             distanceText = '${distanceInKm.toStringAsFixed(1)} km';
//           }
//
//           return Card(
//             elevation: 2,
//             margin: const EdgeInsets.only(bottom: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: InkWell(
//               onTap: () => _showCardDetails(user),
//               borderRadius: BorderRadius.circular(12),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // 头像
//                     CircleAvatar(
//                       radius: 32,
//                       backgroundImage: NetworkImage(card['avatar']),
//                     ),
//                     const SizedBox(width: 16),
//
//                     // 信息
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             card['name'],
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             card['title'],
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             card['companyName'],
//                             style: TextStyle(
//                               color: Colors.blue[700],
//                               fontWeight: FontWeight.w500,
//                               fontSize: 15,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.green[50],
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(color: Colors.green.shade200),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Icon(
//                                       Icons.place,
//                                       size: 14,
//                                       color: Colors.green[700],
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       distanceText,
//                                       style: TextStyle(
//                                         color: Colors.green[800],
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // 右侧图标
//                     Icon(
//                       Icons.arrow_forward_ios,
//                       size: 16,
//                       color: Colors.grey[400],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // 构建好友请求标签页
//   Widget _buildFriendRequestsTab() {
//     if (_friendRequests.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.person_add_disabled, size: 64, color: Colors.grey[300]),
//             const SizedBox(height: 16),
//             Text(
//               'No pending friend requests',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'When someone wants to connect, you\'ll see their request here',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: _friendRequests.length,
//       itemBuilder: (context, index) {
//         final request = _friendRequests[index];
//         final senderInfo = request['senderInfo'];
//         final message = request['message'];
//         final Timestamp? createdAt = request['createdAt'];
//
//         // 格式化时间
//         String timeText = 'Recently';
//         if (createdAt != null) {
//           final date = createdAt.toDate();
//           final now = DateTime.now();
//           final difference = now.difference(date);
//
//           if (difference.inMinutes < 60) {
//             timeText = '${difference.inMinutes} min ago';
//           } else if (difference.inHours < 24) {
//             timeText = '${difference.inHours} hours ago';
//           } else {
//             timeText = '${difference.inDays} days ago';
//           }
//         }
//
//         return Card(
//           elevation: 2,
//           margin: const EdgeInsets.only(bottom: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 标题行
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 24,
//                       backgroundImage: NetworkImage(senderInfo['avatar']),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             senderInfo['name'],
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             senderInfo['title'],
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 13,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       timeText,
//                       style: TextStyle(
//                         color: Colors.grey[500],
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 // 公司名
//                 Padding(
//                   padding: const EdgeInsets.only(left: 60),
//                   child: Text(
//                     senderInfo['companyName'],
//                     style: TextStyle(
//                       color: Colors.blue[700],
//                       fontWeight: FontWeight.w500,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//
//                 // 消息内容
//                 if (message != null && message.isNotEmpty)
//                   Container(
//                     margin: const EdgeInsets.only(top: 12, bottom: 16),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[50],
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey.shade200),
//                     ),
//                     child: Text(
//                       message,
//                       style: TextStyle(
//                         color: Colors.grey[700],
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ),
//
//                 // 按钮行
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     OutlinedButton(
//                       onPressed: () => _handleFriendRequest(request['requestId'], false),
//                       style: OutlinedButton.styleFrom(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: const Text('Decline'),
//                     ),
//                     const SizedBox(width: 12),
//                     ElevatedButton(
//                       onPressed: () => _handleFriendRequest(request['requestId'], true),
//                       style: ElevatedButton.styleFrom(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: const Text('Accept'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // 显示名片详情
//   void _showCardDetails(Map<String, dynamic> user) {
//     final card = user['businessCard'];
//     final String userId = user['userId'];
//
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//         child: Container(
//           width: double.infinity,
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.8,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // 头部
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[50],
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(16),
//                     topRight: Radius.circular(16),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 40,
//                       backgroundImage: NetworkImage(card['avatar']),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       card['name'],
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       card['title'],
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     Container(
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(color: Colors.blue.shade200),
//                       ),
//                       child: Text(
//                         card['companyName'],
//                         style: TextStyle(
//                           color: Colors.blue[800],
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // 内容区
//               Flexible(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // 联系方式
//                       const Text(
//                         'Contact Information:',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//
//                       if (card.containsKey('contactMethods'))
//                         ...(card['contactMethods'] as List).map((method) {
//                           return ListTile(
//                             leading: Icon(
//                               _getIconForContactMethod(method['type']),
//                               color: _getColorForContactMethod(method['type']),
//                             ),
//                             title: Text(method['label']),
//                             subtitle: Text(method['value']),
//                             dense: true,
//                             contentPadding: EdgeInsets.zero,
//                           );
//                         }).toList(),
//
//                       const Divider(),
//
//                       // 业务描述
//                       const Text(
//                         'Business Description:',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(card['description'] ?? 'No description provided'),
//
//                       if (card.containsKey('services') &&
//                           (card['services'] as List).isNotEmpty) ...[
//                         const Divider(),
//                         const Text(
//                           'Services:',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         ...card['services'].map<Widget>((service) {
//                           return Row(
//                             children: [
//                               Icon(
//                                 Icons.check_circle,
//                                 color: Colors.green[600],
//                                 size: 16,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(child: Text(service)),
//                             ],
//                           );
//                         }).toList(),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//
//               // 底部按钮
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(16),
//                     bottomRight: Radius.circular(16),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     OutlinedButton.icon(
//                       icon: const Icon(Icons.close),
//                       label: const Text('Close'),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.person_add),
//                       label: const Text('Add Contact'),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _showAddContactDialog(userId, card['name']);
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // 显示添加联系人对话框
//   void _showAddContactDialog(String userId, String name) {
//     final messageController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Add $name'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Send a request to add this person to your contacts. '
//                   'You can include a brief message:',
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: messageController,
//               decoration: const InputDecoration(
//                 hintText: 'Hi, I found your card nearby...',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//
//               final message = messageController.text.isEmpty
//                   ? 'Hello, I would like to connect with you.'
//                   : messageController.text;
//
//               setState(() {
//                 _isLoading = true;
//               });
//
//               final success = await _nearbyService.sendFriendRequest(userId, message);
//
//               setState(() {
//                 _isLoading = false;
//               });
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(
//                     success
//                         ? 'Contact request sent successfully'
//                         : 'Failed to send contact request',
//                   ),
//                   backgroundColor: success ? Colors.green : Colors.red,
//                 ),
//               );
//             },
//             child: const Text('Send Request'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 获取联系方式图标
//   IconData _getIconForContactMethod(String type) {
//     switch (type) {
//       case 'phone':
//         return Icons.phone;
//       case 'email':
//         return Icons.email;
//       case 'website':
//         return Icons.language;
//       case 'address':
//         return Icons.location_on;
//       default:
//         return Icons.contact_page;
//     }
//   }
//
//   // 获取联系方式颜色
//   Color _getColorForContactMethod(String type) {
//     switch (type) {
//       case 'phone':
//         return Colors.green;
//       case 'email':
//         return Colors.blue;
//       case 'website':
//         return Colors.purple;
//       case 'address':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }