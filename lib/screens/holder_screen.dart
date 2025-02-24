import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veerpeercard/providers/holder_screen_provider.dart';


class HolderScreen extends ConsumerWidget {
  const HolderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardState = ref.watch(providerHolderState); // 当前卡片状态
    final cardNotifier = ref.read(providerHolderState.notifier); // 状态管理器

    final List<Map<String, String>> cards = [
      {
        "name": "John D. Smith",
        "title": "YOUR TITLE HERE",
        "phone": "(555)-555-555",
        "fax": "(555)-555-555",
        "address": "123 YOUR ROAD\nYOUR CITY, STATE ZIP",
        "email": "email@perfectlycustom.com",
        "image": "https://via.placeholder.com/150", // 替换为卡片图片URL
      },
      {
        "name": "Emily D. King",
        "title": "YOUR TITLE HERE",
        "phone": "(555)-555-555",
        "fax": "(555)-555-555",
        "address": "123 YOUR ROAD\nYOUR CITY, STATE ZIP",
        "email": "email@perfectlycustom.com",
        "image": "https://via.placeholder.com/150", // 替换为卡片图片URL
      },
      {
        "name": "Jason D. White",
        "title": "YOUR TITLE HERE",
        "phone": "(555)-555-555",
        "fax": "(555)-555-555",
        "address": "123 YOUR ROAD\nYOUR CITY, STATE ZIP",
        "email": "email@perfectlycustom.com",
        "image": "https://via.placeholder.com/150", // 替换为卡片图片URL
      }
      // 更多卡片数据...
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Cards'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          final isExpanded = index == cardState;

          return GestureDetector(
            onTap: () {
              if (isExpanded) {
                cardNotifier.saveState(null, false); // 收起卡片
              } else {
                cardNotifier.saveState(index, false); // 展开卡片
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    // 阴影效果
                    color: Colors.grey.withValues(),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              height: isExpanded ? 300 : 100, // 展开和收起高度不同
              child: isExpanded
                  ? _buildExpandedCard(context, ref, card, index)
                  : _buildCollapsedCard(card),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedCard(Map<String, String> card) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(card["image"]!),
          radius: 30,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card["name"]!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              card["title"]!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedCard(BuildContext context, WidgetRef ref,
      Map<String, String> card, int index) {
    final cardNotifier = ref.read(providerHolderState.notifier);
    final showBack = ref.watch(providerHolderState.notifier).showBack;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              cardNotifier.saveState(index, !showBack); // 翻转卡片
            },
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showBack
                    ? _buildCardBack(card)
                    : _buildCardFront(card),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            cardNotifier.saveState(null, false); // 收起卡片
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildCardFront(Map<String, String> card) {
    return Column(
      key: const ValueKey('front'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(card["image"]!),
          radius: 50,
        ),
        const SizedBox(height: 10),
        Text(
          card["name"]!,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          card["title"]!,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCardBack(Map<String, String> card) {
    return Column(
      key: const ValueKey('back'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Phone: ${card["phone"]}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'Fax: ${card["fax"]}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          card["address"]!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          card["email"]!,
          style: const TextStyle(fontSize: 16, color: Colors.blue),
        ),
      ],
    );
  }
}