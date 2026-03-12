import 'dart:convert';

void main() {
  String responseData = '{"data": {"statusDistribution": {"A": 1}, "followUpDistribution": {"B": 2}, "recentLeadsList": [{"_id": "1"}, "justastring"]}}';
  
  Map<String, dynamic> jsonResponse = jsonDecode(responseData);
  Map<String, dynamic> analyticsData = jsonResponse['data'];

  try {
    Map<String, dynamic> dist = analyticsData['followUpDistribution'] as Map<String, dynamic>;
    print("FollowUp Cast OK");
  } catch (e) {
    print("FollowUp Cast Failed: $e");
  }

  try {
    List list = analyticsData['recentLeadsList'] as List;
    for (var lead in list) {
        if (lead is! Map<String, dynamic>) {
            print("Found lead that is not a Map! Type: ${lead.runtimeType}, Value: $lead");
            try {
               var map = lead as Map<String, dynamic>; // This reproduces the error!
               print(map);
            } catch (e) {
               print("Map cast error: $e");
            }
        }
    }
  } catch (e) {
     print("Error: $e");
  }
}
