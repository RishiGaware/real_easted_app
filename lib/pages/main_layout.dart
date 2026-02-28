import 'package:flutter/material.dart';
import 'package:inhabit_realties/pages/home/home_page.dart';
import 'package:inhabit_realties/pages/leads/leads_page.dart';
import 'package:inhabit_realties/pages/profile/profile_page.dart';
import 'package:inhabit_realties/pages/properties/properties_page.dart';
import 'package:inhabit_realties/pages/meetingSchedule/meeting_schedule_user_page.dart';
import 'package:inhabit_realties/pages/widgets/app_bottom_nav.dart';

class MainLayout extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const MainLayout({Key? key, this.onToggleTheme}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, 
        children: [
          HomePage(
            onToggleTheme: () => widget.onToggleTheme?.call(),
            onSwitchTab: _onTabTapped,
          ),
          const PropertiesPage(),
          const LeadsPage(),
          const MeetingScheduleUserPage(),
          const ProfilePage(),
        ]
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
