import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inhabit_realties/models/meeting_schedule_model.dart';
import 'package:inhabit_realties/constants/apiUrls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeetingScheduleService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<MeetingSchedule>> getAllMeetings() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(ApiUrls.getAllMeetingSchedules),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> meetingsData = data['data'] ?? [];
        final List<MeetingSchedule> meetings = meetingsData
            .map((json) => MeetingSchedule.fromJson(json))
            .toList();
        
        meetings.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          final dateA = DateTime.tryParse(a.createdAt!);
          final dateB = DateTime.tryParse(b.createdAt!);
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        return meetings;
      } else {
        throw Exception('Failed to load meetings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading meetings: $e');
    }
  }

  Future<List<MeetingSchedule>> getMyMeetings() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Get current user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('currentUser');
      if (userJson == null) {
        throw Exception('No current user found');
      }

      final userData = json.decode(userJson);
      final userId = userData['_id'] ?? userData['id'];
      if (userId == null) {
        throw Exception('No user ID found in current user data');
      }

      final response = await http.get(
        Uri.parse('${ApiUrls.getMyMeetings}$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> meetingsData = data['data'] ?? [];
        final List<MeetingSchedule> meetings = meetingsData
            .map((json) => MeetingSchedule.fromJson(json))
            .toList();

        meetings.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          final dateA = DateTime.tryParse(a.createdAt!);
          final dateB = DateTime.tryParse(b.createdAt!);
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        return meetings;
      } else {
        throw Exception('Failed to load my meetings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading my meetings: $e');
    }
  }

  Future<List<MeetingSchedule>> createMeeting(
      Map<String, dynamic> meetingData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse(ApiUrls.createMeetingSchedule),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(meetingData),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> meetingsData = data['data'] ?? [];
        return meetingsData
            .map((json) => MeetingSchedule.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to create meeting: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating meeting: $e');
    }
  }

  Future<MeetingSchedule> updateMeeting(
      String id, Map<String, dynamic> meetingData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '${ApiUrls.editMeetingSchedule}$id';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(meetingData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        // If there's no data field, return a mock meeting object
        if (data['data'] != null) {
          return MeetingSchedule.fromJson(data['data']);
        } else {
          // Return a mock meeting object since the backend doesn't return the updated data
          return MeetingSchedule(
            id: id,
            title: meetingData['title'] ?? '',
            description: meetingData['description'] ?? '',
            meetingDate: meetingData['meetingDate'] ?? '',
            startTime: meetingData['startTime'] ?? '',
            endTime: meetingData['endTime'],
            duration: meetingData['duration'],
            status: meetingData['status'] ?? '',
            scheduledByUserId: meetingData['scheduledByUserId'] ?? '',
            customerId: meetingData['customerId'] ?? '',
            propertyId: meetingData['propertyId'],
            notes: meetingData['notes'] ?? '',
            createdByUserId: meetingData['createdByUserId'] ?? '',
            updatedByUserId: meetingData['updatedByUserId'] ?? '',
            published: true,
          );
        }
      } else {
        throw Exception('Failed to update meeting: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating meeting: $e');
    }
  }

  Future<void> deleteMeeting(String id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('${ApiUrls.deleteMeetingSchedule}$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete meeting: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting meeting: $e');
    }
  }

  // Check if a meeting should be marked as missed
  bool _isMeetingMissed(MeetingSchedule meeting) {
    try {
      // Parse meeting date and end time
      final meetingDate = DateTime.parse(meeting.meetingDate);
      final endTime = meeting.endTime ?? meeting.startTime;
      
      // Create DateTime for meeting end
      final timeParts = endTime.split(':');
      final meetingEndDateTime = DateTime(
        meetingDate.year,
        meetingDate.month,
        meetingDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      
      // Check if current time is past meeting end time
      final now = DateTime.now();
      return now.isAfter(meetingEndDateTime);
    } catch (e) {
      // If parsing fails, return false
      return false;
    }
  }

  // Update meeting status to missed if applicable
  Future<void> updateMeetingStatusIfMissed(MeetingSchedule meeting) async {
    try {
      // Only update if meeting is currently scheduled and should be marked as missed
      if (meeting.getStatusName().toLowerCase() == 'scheduled' && _isMeetingMissed(meeting)) {
        // Get the missed status ID (you'll need to implement this based on your status system)
        final missedStatusId = await _getMissedStatusId();
        
        if (missedStatusId != null) {
          await updateMeeting(meeting.id, {
            'status': missedStatusId,
            'updatedByUserId': meeting.updatedByUserId,
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String? _cachedMissedStatusId;

  // Get the missed status ID from the backend
  Future<String?> _getMissedStatusId() async {
    if (_cachedMissedStatusId != null) return _cachedMissedStatusId;
    
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiUrls.getAllMeetingScheduleStatuses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> statuses = data['data'] ?? [];
        
        // Find the missed status
        for (final status in statuses) {
          if (status['name']?.toString().toLowerCase() == 'missed') {
            _cachedMissedStatusId = status['_id'] ?? status['id'];
            return _cachedMissedStatusId;
          }
        }
      }
      return null;
    } catch (e) {
      // Handle error silently
      return null;
    }
  }

  // Check and update all meetings for missed status
  Future<void> checkAndUpdateMissedMeetings({List<MeetingSchedule>? meetings}) async {
    try {
      final meetingsToCheck = meetings ?? await getAllMeetings();
      final List<Future<void>> updateTasks = [];
      
      for (final meeting in meetingsToCheck) {
        updateTasks.add(updateMeetingStatusIfMissed(meeting));
      }
      
      if (updateTasks.isNotEmpty) {
        await Future.wait(updateTasks);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Get all not published meeting schedules (admin only)
  Future<List<MeetingSchedule>> getAllNotPublishedMeetings() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(ApiUrls.getAllNotPublishedMeetingSchedules),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> meetingsData = data['data'] ?? [];
        return meetingsData
            .map((json) => MeetingSchedule.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load not published meetings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading not published meetings: $e');
    }
  }

  // Get meeting schedule by user ID
  Future<List<MeetingSchedule>> getMeetingScheduleByUserId(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('getMeetingScheduleByUserId called with userId: $userId');
      
      final url = '${ApiUrls.getMeetingScheduleById}$userId';
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('getMeetingScheduleByUserId response status: ${response.statusCode}');
      print('getMeetingScheduleByUserId response body length: ${response.body.length}');
      // Only print body if it's not too huge, or just the start
      if (response.statusCode != 200 || response.body.length < 1000) {
        print('body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> meetingsData = data['data'] ?? [];
        final List<MeetingSchedule> meetings = meetingsData
            .map((json) => MeetingSchedule.fromJson(json))
            .toList();

        meetings.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          final dateA = DateTime.tryParse(a.createdAt!);
          final dateB = DateTime.tryParse(b.createdAt!);
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        return meetings;
      } else {
        throw Exception(
            'Failed to load meeting schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading meeting schedule: $e');
    }
  }

  // Get meeting details by meeting ID
  Future<MeetingSchedule> getMeetingById(String meetingId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiUrls.getMeetingById}$meetingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return MeetingSchedule.fromJson(data['data']);
      } else {
        throw Exception('Failed to load meeting details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading meeting details: $e');
    }
  }

  // Get user details by ID
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiUrls.getUserById}$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get property details by ID
  Future<Map<String, dynamic>?> getPropertyDetails(String propertyId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiUrls.getPropertyById}$propertyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
