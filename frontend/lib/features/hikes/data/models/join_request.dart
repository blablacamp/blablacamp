import 'profile_ref.dart';

/// A pending/handled join request as seen by the organizer:
/// one hike_participants row + who applied + which hike.
class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.hikeId,
    required this.hikeTitle,
    required this.applicant,
    required this.status,
  });

  final String id; // hike_participants row id
  final String hikeId;
  final String hikeTitle;
  final ProfileRef applicant;
  final String status;
}
