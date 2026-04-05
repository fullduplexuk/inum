import "package:hydrated_bloc/hydrated_bloc.dart";
import "package:equatable/equatable.dart";

// --- State ---

class BlockedUsersState extends Equatable {
  final Set<String> blockedIds;
  final List<ReportEntry> reports;

  const BlockedUsersState({
    this.blockedIds = const {},
    this.reports = const [],
  });

  BlockedUsersState copyWith({
    Set<String>? blockedIds,
    List<ReportEntry>? reports,
  }) {
    return BlockedUsersState(
      blockedIds: blockedIds ?? this.blockedIds,
      reports: reports ?? this.reports,
    );
  }

  @override
  List<Object?> get props => [blockedIds, reports];
}

class ReportEntry extends Equatable {
  final String userId;
  final String reason;
  final DateTime reportedAt;

  const ReportEntry({
    required this.userId,
    required this.reason,
    required this.reportedAt,
  });

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "reason": reason,
        "reported_at": reportedAt.toIso8601String(),
      };

  factory ReportEntry.fromJson(Map<String, dynamic> json) => ReportEntry(
        userId: json["user_id"] as String? ?? "",
        reason: json["reason"] as String? ?? "",
        reportedAt: DateTime.tryParse(json["reported_at"] as String? ?? "") ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [userId, reason, reportedAt];
}

// --- Cubit ---

class BlockedUsersCubit extends HydratedCubit<BlockedUsersState> {
  BlockedUsersCubit() : super(const BlockedUsersState());

  void blockUser(String userId) {
    final updated = Set<String>.from(state.blockedIds)..add(userId);
    emit(state.copyWith(blockedIds: updated));
  }

  void unblockUser(String userId) {
    final updated = Set<String>.from(state.blockedIds)..remove(userId);
    emit(state.copyWith(blockedIds: updated));
  }

  bool isBlocked(String userId) => state.blockedIds.contains(userId);

  void reportUser(String userId, String reason) {
    final entry = ReportEntry(
      userId: userId,
      reason: reason,
      reportedAt: DateTime.now(),
    );
    emit(state.copyWith(reports: [...state.reports, entry]));
  }

  @override
  BlockedUsersState? fromJson(Map<String, dynamic> json) {
    try {
      final ids = (json["blocked_ids"] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {};
      final reports = (json["reports"] as List<dynamic>?)
              ?.map((e) => ReportEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return BlockedUsersState(blockedIds: ids, reports: reports);
    } catch (_) {
      return const BlockedUsersState();
    }
  }

  @override
  Map<String, dynamic>? toJson(BlockedUsersState state) {
    return {
      "blocked_ids": state.blockedIds.toList(),
      "reports": state.reports.map((r) => r.toJson()).toList(),
    };
  }
}
