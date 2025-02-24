import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veerpeercard/providers/bottom_tabs_provider.dart';
import 'package:veerpeercard/providers/theme_provider.dart';
import 'package:veerpeercard/screens/user_settings_screen.dart';
import 'screens.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // final List<String> _titles = [
  //   'Messages',
  //   'Holder',
  //   'Me',
  //   'Parcelbox',
  //   'Moments',
  // ];

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(providerCurrentTabIndex);
    final currentTheme = ref.watch(providerTheme);
    final user = FirebaseAuth.instance.currentUser;

    final isDarkMode = currentTheme == ThemeMode.dark ||
        (currentTheme == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final screens = [
      const MessagesScreen(),
      const HolderScreen(),
      const MeScreen(),
      const ParcelboxScreen(),
      const MomentsScreen(),
    ];

    final appBarDestinations = const [
      NavigationDestination(
        icon: Icon(Icons.message_outlined),
        label: 'Messages',
        selectedIcon: Icon(Icons.message),
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        label: 'Holder',
        selectedIcon: Icon(Icons.wallet),
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outlined),
        label: 'Me',
        selectedIcon: Icon(Icons.person),
      ),
      NavigationDestination(
        icon: Icon(Icons.markunread_mailbox_outlined),
        label: 'Parcelbox',
        selectedIcon: Icon(Icons.markunread_mailbox),
      ),
      NavigationDestination(
        icon: Icon(Icons.camera_outlined),
        label: 'Moments',
        selectedIcon: Icon(Icons.camera),
      )
    ];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 16.0,  // 添加这行来设置大小
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14.0,  // 调整文字大小
                ),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSettingsScreen(),
                ),
              );
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 32.0,  // 调整大小和 CircleAvatar 直径一致
              ),
              onPressed: () async {
                await ref.read(providerTheme.notifier).toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentTabIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTabIndex,
        onDestinationSelected: (index) {
          ref.read(providerCurrentTabIndex.notifier).setTabIndex(index);
        },
        destinations: appBarDestinations,
      ),
    );
  }
}