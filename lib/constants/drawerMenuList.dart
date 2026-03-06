import 'package:flutter/cupertino.dart';

class DrawerMenuList {
  static List<Map<String, dynamic>> list = [
    {'path': '/users', 'icon': CupertinoIcons.person_3_fill, 'title': 'Users'},
    {
      'path': '/documents/all',
      'icon': CupertinoIcons.doc_text_fill,
      'title': 'All Documents',
    },
    {
      'path': '/customers',
      'icon': CupertinoIcons.person_2_fill,
      'title': 'Customers',
    },
    {
      'path': '/favorite_properties',
      'icon': CupertinoIcons.heart_fill,
      'title': 'My Favorite Properties',
    },
    {
      'path': '/meeting_schedules',
      'icon': CupertinoIcons.calendar,
      'title': 'Meeting Schedules',
    },
    {
      'path': '/all_purchase_bookings',
      'icon': CupertinoIcons.bag_fill,
      'title': 'All Purchase Bookings',
    },
    {
      'path': '/all_rental_bookings',
      'icon': CupertinoIcons.house_fill,
      'title': 'All Rental Bookings',
    },
    {
      'path': '/settings',
      'icon': CupertinoIcons.settings_solid,
      'title': 'Settings',
    },
    // {
    //   'path': '/auth/register',
    //   'icon': CupertinoIcons.person_badge_plus_fill,
    //   'title': 'Register User',
    // },
    {
      'path': '/auth/logout',
      'icon': CupertinoIcons.square_arrow_left_fill,
      'title': 'Logout',
    },
  ];
}
