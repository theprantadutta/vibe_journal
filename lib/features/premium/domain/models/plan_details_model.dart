import 'package:cloud_firestore/cloud_firestore.dart';

class PlanDetailsModel {
  final String planName;
  final int maxCloudVibes;
  final int maxRecordingDurationMinutes;

  PlanDetailsModel({
    required this.planName,
    required this.maxCloudVibes,
    required this.maxRecordingDurationMinutes,
  });

  factory PlanDetailsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PlanDetailsModel(
      planName: data['planName'] ?? 'Unknown',
      maxCloudVibes: data['maxCloudVibes'] ?? 0,
      maxRecordingDurationMinutes: data['maxRecordingDurationMinutes'] ?? 1,
    );
  }
}
