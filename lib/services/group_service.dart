import '../models/group_model.dart';
import '../data/mock/mock_groups.dart';

/// ⚠️ DEPRECATION WARNING:
/// This static mock service is an architectural anti-pattern for this app.
/// State management and Firebase integration are handled by [GroupProvider]
/// and [GroupRepository].
///
/// DO NOT use this service in production UI. Use `context.watch<GroupProvider>().groups` instead.
class GroupService {
  /// ✅ Get all groups (Mock حاليا — Firebase لاحقاً)
  @Deprecated('Use GroupProvider.groups instead to get real reactive data')
  static List<Group> getGroups() {
    return MockGroups.groups;
  }

  /// ✅ Active groups only
  @Deprecated('Use GroupProvider.active instead to get real reactive data')
  static List<Group> getActiveGroups() {
    return MockGroups.groups.where((g) => !g.isCompleted).toList();
  }

  /// ✅ Completed groups
  @Deprecated('Use GroupProvider.completed instead to get real reactive data')
  static List<Group> getCompletedGroups() {
    return MockGroups.groups.where((g) => g.isCompleted).toList();
  }
}
