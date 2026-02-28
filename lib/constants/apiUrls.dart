import '../config/environment.dart';

class ApiUrls {
  static String get baseUrl => EnvironmentConfig.baseUrl;

  //auth
  static String get checkAuth => '$baseUrl/auth/check';
  static String get login => '$baseUrl/auth/login';

  //users
  static String get register => '$baseUrl/users/register';
  static String get editUser => '$baseUrl/users/edit/';
  static String get getAllUsers => '$baseUrl/users';
  static String get getAllUsersWithParams => '$baseUrl/users/withparams';
  static String get getUserById => '$baseUrl/users/';
  static String get changePassword => '$baseUrl/users/change-password';

  //roles
  static String get getAllRoles => '$baseUrl/roles';

  //file
  static String get createProfileImage =>
      '$baseUrl/file/userprofilepicture/create';
  static String get getProfileImage => '$baseUrl/file/userprofilepicture/';

  //property
  static String get getAllProperties => '$baseUrl/property/';
  static String get getPropertyById => '$baseUrl/property/';
  static String get createProperty => '$baseUrl/property/create/';
  static String get editProperty => '$baseUrl/property/edit/';

  //property images
  static String get createPropertyImage => '$baseUrl/property/image/create/';
  static String get getAllPropertyImages => '$baseUrl/property/images/all/';
  static String get getPropertyImageById => '$baseUrl/property/image/';
  static String get deletePropertyImage => '$baseUrl/property/delete/';
  static String get deletePropertyImageById =>
      '$baseUrl/property/image/delete/';
  static String get deleteAllPropertyImages => '$baseUrl/property/delete/all/';

  //property types
  static String get getAllPropertyTypes =>
      '$baseUrl/propertytypes/'; //updated property types

  //leads - Updated to match actual backend routes
  static String get getAllLeads => '$baseUrl/leads';
  static String get getAllNotPublishedLeads =>
      '$baseUrl/leads/notpublishedusers';
  static String get getAllLeadsWithParams => '$baseUrl/leads/withparams';
  static String get getAssignedLeadsForCurrentUser =>
      '$baseUrl/leads/assigned-to-me';
  static String get getLeadById => '$baseUrl/leads/';
  static String get createLead => '$baseUrl/leads/create';
  static String get editLead => '$baseUrl/leads/edit/';
  static String get deleteLead => '$baseUrl/leads/delete/';

  //lead statuses
  static String get getAllLeadStatuses => '$baseUrl/leadstatus';
  static String get getLeadStatusById => '$baseUrl/leadstatus/';
  static String get createLeadStatus => '$baseUrl/leadstatus/create';
  static String get editLeadStatus => '$baseUrl/leadstatus/edit/';
  static String get deleteLeadStatus => '$baseUrl/leadstatus/delete/';

  //follow-up statuses
  static String get getAllFollowUpStatuses => '$baseUrl/followupstatus';
  static String get getFollowUpStatusById => '$baseUrl/followupstatus/';
  static String get createFollowUpStatus => '$baseUrl/followupstatus/create';
  static String get editFollowUpStatus => '$baseUrl/followupstatus/edit/';
  static String get deleteFollowUpStatus => '$baseUrl/followupstatus/delete/';

  //reference sources
  static String get getAllReferenceSources => '$baseUrl/referancesource';
  static String get getReferenceSourceById => '$baseUrl/referancesource/';
  static String get createReferenceSource => '$baseUrl/referancesource/create';
  static String get editReferenceSource => '$baseUrl/referancesource/edit/';
  static String get deleteReferenceSource => '$baseUrl/referancesource/delete/';

  //documents
  static String get getAllDocuments => '$baseUrl/documents';
  static String get getAllDocumentsWithParams =>
      '$baseUrl/documents/withparams';
  static String get getDocumentById => '$baseUrl/documents/';
  static String get createDocument => '$baseUrl/documents/create';
  static String get editDocument => '$baseUrl/documents/edit/';
  static String get deleteDocument => '$baseUrl/documents/delete/';

  //document types
  static String get getAllDocumentTypes => '$baseUrl/documenttypes';
  static String get getDocumentTypeById => '$baseUrl/documenttypes/';
  static String get createDocumentType => '$baseUrl/documenttypes/create';
  static String get editDocumentType => '$baseUrl/documenttypes/edit/';
  static String get deleteDocumentType => '$baseUrl/documenttypes/delete/';

  //favorite properties
  static String get getAllFavoriteProperties => '$baseUrl/favoriteproperty';
  static String get getFavoritePropertyById => '$baseUrl/favoriteproperty/';
  static String get createFavoriteProperty =>
      '$baseUrl/favoriteproperty/create';
  static String get deleteFavoriteProperty =>
      '$baseUrl/favoriteproperty/delete/';
  static String get getFavoritePropertiesByUserId =>
      '$baseUrl/favoriteproperty/user/';
  static String get getFavoritePropertiesWithParams =>
      '$baseUrl/favoriteproperty/withparams';

  //meeting schedules - Updated to match backend routes
  static String get getAllMeetingSchedules => '$baseUrl/meetingschedule';
  static String get getMyMeetings => '$baseUrl/meetingschedule/my-meetings/';
  static String get getAllNotPublishedMeetingSchedules =>
      '$baseUrl/meetingschedule/notpublished';
  static String get getMeetingScheduleById =>
      '$baseUrl/meetingschedule/scheduledByUserId/';
  static String get getMeetingById => '$baseUrl/meetingschedule/';
  static String get createMeetingSchedule => '$baseUrl/meetingschedule/create';
  static String get editMeetingSchedule => '$baseUrl/meetingschedule/edit/';
  static String get deleteMeetingSchedule => '$baseUrl/meetingschedule/delete/';

  //meeting schedule statuses
  static String get getAllMeetingScheduleStatuses =>
      '$baseUrl/meetingschedulestatus';
  static String get getMeetingScheduleStatusById =>
      '$baseUrl/meetingschedulestatus/';

  //notifications
  static String get createNotification => '$baseUrl/notifications/create';
  static String get getAllNotifications => '$baseUrl/notifications';
  static String get getAllNotPublishedNotifications =>
      '$baseUrl/notifications/notpublished';
  static String get getAllNotificationsWithParams =>
      '$baseUrl/notifications/withparams';
  static String get getNotificationById => '$baseUrl/notifications/';
  static String get editNotification => '$baseUrl/notifications/edit/';
  static String get deleteNotificationById => '$baseUrl/notifications/delete/';
  static String get getUserNotifications => '$baseUrl/notifications/my-notifications';
  static String get markNotificationAsRead => '$baseUrl/notifications/read/';
  static String get markNotificationAsUnread =>
      '$baseUrl/notifications/unread/';
  static String get markAllNotificationsAsRead =>
      '$baseUrl/notifications/read-all';
  static String get deleteNotification => '$baseUrl/notifications/delete/';
  static String get getUnreadCount => '$baseUrl/notifications/unread-count';
  static String get createTestNotification =>
      '$baseUrl/notifications/test/create';
  static String get createMeetingReminders =>
      '$baseUrl/notifications/meeting-reminders';

  //user addresses
  static String get getAllUserAddresses => '$baseUrl/useraddress';
  static String get getUserAddressById => '$baseUrl/useraddress/';
  static String get getUserAddressByUserId => '$baseUrl/useraddress/user/';
  static String get createUserAddress => '$baseUrl/useraddress/create';
  static String get updateUserAddress => '$baseUrl/useraddress/edit/';
  static String get deleteUserAddress => '$baseUrl/useraddress/delete/';

  //dashboard
  static String get getDashboardOverview => '$baseUrl/dashboard/overview';
  static String get getTodaySchedules => '$baseUrl/dashboard/today-schedules';

  //admin booking endpoints
  static String get getAllPurchaseBookings => '$baseUrl/purchase-bookings/all';
  static String get getAllRentalBookings => '$baseUrl/rental-bookings/all';
  static String get getPurchaseBookingById => '$baseUrl/purchase-bookings/';
  static String get getRentalBookingById => '$baseUrl/rental-bookings/';
  static String get confirmPurchaseBooking =>
      '$baseUrl/purchase-bookings/confirm/';
  static String get confirmRentalBooking => '$baseUrl/rental-bookings/confirm/';
}
