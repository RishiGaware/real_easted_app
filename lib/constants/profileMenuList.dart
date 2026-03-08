import 'package:flutter/cupertino.dart';

class ProfileMenuList {
  static List<Map<String, dynamic>> list = [
    {
      'path': '/home',
      'icon': CupertinoIcons.chart_bar_alt_fill,
      'title': 'Dashboard',
      'trailingNumberLabel': null,
    },
    {
      'path': '/leads/assigned',
      'icon': CupertinoIcons.person_2_square_stack_fill,
      'title': 'Assigned Leads',
      'trailingNumberLabel': 0,
    },
    {
      'path': '/notifications',
      'icon': CupertinoIcons.bell_fill,
      'title': 'Notifications',
      'trailingNumberLabel': 0,
    },
    {
      'path': '/documents',
      'icon': CupertinoIcons.doc_text_fill,
      'title': 'My Documents',
      'trailingNumberLabel': null,
    },
    {
      'path': '/my_meetings',
      'icon': CupertinoIcons.calendar,
      'title': 'My Meetings',
      'trailingNumberLabel': null,
    },
    {
      'path': '/my_purchase_bookings',
      'icon': CupertinoIcons.bag_fill,
      'title': 'My Purchase Bookings',
      'trailingNumberLabel': null,
    },
    {
      'path': '/my_rental_bookings',
      'icon': CupertinoIcons.house_fill,
      'title': 'My Rental Bookings',
      'trailingNumberLabel': null,
    },
    {
      'path': '/settings',
      'icon': CupertinoIcons.settings_solid,
      'title': 'Settings',
      'trailingNumberLabel': null,
    },
    {
      'path': '/auth/change_password',
      'icon': CupertinoIcons.lock_shield_fill,
      'title': 'Change Password',
      'trailingNumberLabel': null,
    },
    {
      'path': '/auth/logout',
      'icon': CupertinoIcons.square_arrow_left_fill,
      'title': 'Logout',
      'trailingNumberLabel': null,
    },
  ];
}
