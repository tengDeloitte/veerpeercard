import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veerpeercard/providers/parcelbox_screen_provider.dart';

class ParcelboxScreen extends ConsumerWidget {
  const ParcelboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前状态
    final parcelboxState = ref.watch(providerParcelboxState);
    final parcelboxNotifier = ref.read(providerParcelboxState.notifier);

    final bool hasNearbyCard = parcelboxState['hasNearbyCard'] ?? false;
    final bool hasPendingApplication = parcelboxState['hasPendingApplication'] ?? false;

    return Scaffold(
      appBar: AppBar(
        // title: const Text('Parcelbox Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 附近消息按钮
            GestureDetector(
              onTap: () {
                // 模拟切换附近消息状态
                parcelboxNotifier.setHasNearbyCard(!hasNearbyCard);
                _showNearbyInfo(context, hasNearbyCard);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.question_mark,
                    size: 30,
                    color: hasNearbyCard ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Nearby Messages',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 申请选项按钮
            GestureDetector(
              onTap: () {
                // 模拟切换申请状态
                parcelboxNotifier.setHasPendingApplication(!hasPendingApplication);
                _showApplicationStatus(context, hasPendingApplication);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 30,
                    color: hasPendingApplication ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Applications',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示附近消息信息
  void _showNearbyInfo(BuildContext context, bool hasNearbyCard) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nearby Messages'),
          content: hasNearbyCard
              ? const Text('You have new nearby cards! 🎉')
              : const Text('No nearby messages at the moment.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // 显示申请状态信息
  void _showApplicationStatus(BuildContext context, bool hasPendingApplication) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Application Status'),
          content: hasPendingApplication
              ? const Text('You have pending applications. 📋')
              : const Text('No pending applications.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}