import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

class Partner {
  const Partner({
    required this.id,
    required this.userId,
    required this.name,
    required this.shareRatio,
    required this.contributionTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final double shareRatio;
  final double contributionTotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'shareRatio': shareRatio,
      'contributionTotal': contributionTotal,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Partner.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return Partner(
      id: id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      shareRatio: parseDouble(data['shareRatio']),
      contributionTotal: parseDouble(data['contributionTotal']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}

class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    required this.metadata,
  });

  final String id;
  final String actorId;
  final String actorName;
  final String action;
  final String entityType;
  final String entityId;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': createdAt,
      'metadata': metadata,
    };
  }

  factory ActivityLogEntry.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return ActivityLogEntry(
      id: id,
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      action: data['action'] as String? ?? '',
      entityType: data['entityType'] as String? ?? '',
      entityId: data['entityId'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? const {}),
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.route,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String route;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotificationItem.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return AppNotificationItem(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (value) => value.name == data['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      route: data['route'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
    );
  }
}
