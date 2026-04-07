import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

class Partner {
  const Partner({
    required this.id,
    required this.userId,
    required this.linkedEmail,
    required this.name,
    required this.shareRatio,
    required this.contributionTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String linkedEmail;
  final String name;
  final double shareRatio;
  final double contributionTotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'linkedEmail': linkedEmail,
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
      linkedEmail: data['linkedEmail'] as String? ?? '',
      name: data['name'] as String? ?? '',
      shareRatio: parseDouble(data['shareRatio']),
      contributionTotal: parseDouble(data['contributionTotal']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Partner copyWith({
    String? id,
    String? userId,
    String? linkedEmail,
    String? name,
    double? shareRatio,
    double? contributionTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Partner(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      linkedEmail: linkedEmail ?? this.linkedEmail,
      name: name ?? this.name,
      shareRatio: shareRatio ?? this.shareRatio,
      contributionTotal: contributionTotal ?? this.contributionTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    this.referenceKey = '',
    this.metadata = const {},
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String route;
  final bool isRead;
  final DateTime createdAt;
  final String referenceKey;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'route': route,
      'isRead': isRead,
      'createdAt': createdAt,
      'referenceKey': referenceKey,
      'metadata': metadata,
    };
  }

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
      referenceKey: data['referenceKey'] as String? ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? const {}),
    );
  }

  AppNotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? route,
    bool? isRead,
    DateTime? createdAt,
    String? referenceKey,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      route: route ?? this.route,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      referenceKey: referenceKey ?? this.referenceKey,
      metadata: metadata ?? this.metadata,
    );
  }
}
