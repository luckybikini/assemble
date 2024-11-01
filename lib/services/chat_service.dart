import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 채팅방 생성
  Future<String> createRoom({
    required String title,
    required String menu,
    required int maxMembers,
    required String leaderId,
    required DateTime orderDeadline,
    required bool together,
  }) async {
    try {
      final docRef = await _firestore.collection('chatRooms').add({
        'title': title,
        'menu': menu,
        'maxMembers': maxMembers,
        'currentMembers': 1,
        'leaderId': leaderId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'orderDeadline': Timestamp.fromDate(orderDeadline),
        'members': {leaderId: true},
        'together' : together,
      });

      // 방장의 joinedRooms 업데이트
      await _firestore.collection('users').doc(leaderId).update({
        'joinedRooms': FieldValue.arrayUnion([docRef.id])
      });

      return docRef.id;
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }

  // 활성화된 채팅방 목록 가져오기
  Stream<List<ChatRoom>> getActiveRooms() {
    return _firestore
        .collection('chatRooms')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => ChatRoom.fromDocument(doc)).toList());
  }

  // 특정 사용자의 채팅방 목록 가져오기
  Stream<List<ChatRoom>> getUserRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('members.$userId', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => ChatRoom.fromDocument(doc)).toList());
  }

  // 채팅방 참여
  Future<void> joinRoom(String roomId, String userId) async {
    final roomRef = _firestore.collection('chatRooms').doc(roomId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      final currentMembers = roomDoc.data()?['currentMembers'] ?? 0;
      final maxMembers = roomDoc.data()?['maxMembers'] ?? 0;

      // 최대 인원 제한을 초과하는 경우 예외 처리
      if (currentMembers >= maxMembers) {
        throw Exception('방이 가득 찼습니다.');
      }

      // 멤버 필드와 현재 인원 수 업데이트
      transaction.update(roomRef, {
        'members.$userId': true,
        'currentMembers': currentMembers + 1,
      });

      transaction.update(userRef, {
        'joinedRooms': FieldValue.arrayUnion([roomId])
      });
    });
  }

  // 채팅방 나가기
  Future<void> leaveRoom(String roomId, String userId) async {
    final roomRef = _firestore.collection('chatRooms').doc(roomId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      final currentMembers = roomDoc.data()?['currentMembers'] ?? 0;
      final leaderId = roomDoc.data()?['leaderId'];

      if (leaderId == userId) {
        // 방장이 나가면 방 비활성화
        transaction.update(roomRef, {'status': 'inactive'});
      } else {
        // 멤버 필드와 현재 인원 수 업데이트
        transaction.update(roomRef, {
          'members.$userId': FieldValue.delete(),
          'currentMembers': currentMembers - 1,
        });
      }

      transaction.update(userRef, {
        'joinedRooms': FieldValue.arrayRemove([roomId])
      });
    });
  }

  // 메시지 전송
  Future<void> sendMessage(String roomId, String userId, String content) async {
    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'content': content,
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 메시지 스트림 가져오기
  Stream<QuerySnapshot> getMessages(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // 채팅방 정보 업데이트
  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    await _firestore.collection('chatRooms').doc(roomId).update(data);
  }

  // 채팅방 상태 확인
  Future<bool> isRoomActive(String roomId) async {
    final doc = await _firestore.collection('chatRooms').doc(roomId).get();
    return doc.exists && doc.data()?['status'] == 'active';
  }
}
