import 'package:flutter/material.dart';
import 'package:skai/profile.dart';
import 'package:skai/index.dart';
import 'package:skai/widgets/navbar.dart';
import 'package:skai/skai.dart';
import 'package:skai/events.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;

  // Si quieres preservar posiciones de scroll entre tabs
  final PageStorageBucket _bucket = PageStorageBucket();

  late final List<Widget> _pages = <Widget>[
    Index(onOpenSkai: () => _onItemTapped(1)),
    const SkaiPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // si tu navbar es translúcida/curvada queda mejor
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
