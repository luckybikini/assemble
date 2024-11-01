import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String title;
  final String menu;
  final int maxMembers;
  final int currentMembers;
  final String leaderId;
  final String status;
  final DateTime createdAt;
  final DateTime orderDeadline;
  final Map<String, bool> members;

  ChatRoom({
    required this.id,
    required this.title,
    required this.menu,
    required this.maxMembers,
    required this.currentMembers,
    required this.leaderId,
    required this.status,
    required this.createdAt,
    required this.orderDeadline,
    required this.members,
  });

  factory ChatRoom.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      title: data['title'] ?? '',
      menu: data['menu'] ?? '',
      maxMembers: data['maxMembers'] ?? 0,
      currentMembers: data['currentMembers'] ?? 0,
      leaderId: data['leaderId'] ?? '',
      status: data['status'] ?? 'inactive',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      orderDeadline: (data['orderDeadline'] as Timestamp).toDate(),
      members: Map<String, bool>.from(data['members'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'menu': menu,
      'maxMembers': maxMembers,
      'currentMembers': currentMembers,
      'leaderId': leaderId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'orderDeadline': Timestamp.fromDate(orderDeadline),
      'members': members,
    };
  }
}