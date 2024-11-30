import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/bottom_navigation_provider.dart';

class BottomNavigation extends StatelessWidget {
  final Function(int) onTap;

  BottomNavigation({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavigationProvider>(
      builder: (context, provider, child) {
        return BottomNavigationBar(
          currentIndex: provider.currentIndex,
          onTap: (index) {
            onTap(index);
          },
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                provider.currentIndex == 0
                    ? 'assets/icons/list_selected.png'
                    : 'assets/icons/list_unselected.png',
                width: 24,
                height: 24,
              ),
              label: '목록',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                provider.currentIndex == 1
                    ? 'assets/icons/map_selected.png'
                    : 'assets/icons/map_unselected.png',
                width: 24,
                height: 24,
              ),
              label: '지도',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                provider.currentIndex == 2
                    ? 'assets/icons/add_selected.png'
                    : 'assets/icons/add_unselected.png',
                width: 24,
                height: 24,
              ),
              label: '추가',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                provider.currentIndex == 3
                    ? 'assets/icons/friends_selected.png'
                    : 'assets/icons/friends_unselected.png',
                width: 24,
                height: 24,
              ),
              label: '친구',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                provider.currentIndex == 4
                    ? 'assets/icons/profile_selected.png'
                    : 'assets/icons/profile_unselected.png',
                width: 24,
                height: 24,
              ),
              label: '프로필',
            ),
          ],
        );
      },
    );
  }
}
