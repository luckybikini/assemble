import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room.dart';
import '../services/auth_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

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
      // 유저의 파티 참여 상태 확인
      final userDoc = await _firestore.collection('users').doc(leaderId).get();
      final userData = userDoc.data();

      if (userData?['isInParty'] == true) {
        throw Exception('이미 다른 파티에 참여 중입니다.');
      }

      // 트랜잭션으로 방 생성과 유저 상태 업데이트를 동시에 처리
      String newRoomId = '';
      await _firestore.runTransaction((transaction) async {
        // 1. 새로운 방 생성
        final roomRef = _firestore.collection('chatRooms').doc();
        newRoomId = roomRef.id;

        transaction.set(roomRef, {
          'title': title,
          'menu': menu,
          'maxMembers': maxMembers,
          'currentMembers': 1,
          'leaderId': leaderId,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'orderDeadline': Timestamp.fromDate(orderDeadline),
          'members': {leaderId: true},
          'together': together,
        });

        // 2. 유저 상태 업데이트
        final userRef = _firestore.collection('users').doc(leaderId);
        transaction.update(userRef, {
          'currentPartyId': newRoomId,
          'isInParty': true,
          'lastUpdated': FieldValue.serverTimestamp()
        });
      });

      return newRoomId;
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }

  // 채팅방 참여
  Future<void> joinRoom(String roomId, String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final roomRef = _firestore.collection('chatRooms').doc(roomId);

    try {
      // 채팅방 정보 업데이트를 Transaction으로 처리
      await _firestore.runTransaction((transaction) async {
        // 1. 유저 상태 확인
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data()!;
        final bool isInParty = userData['isInParty'] ?? false;
        final String? currentPartyId = userData['currentPartyId'];

        // 참여 조건 검증
        if (isInParty) {
          if (currentPartyId != roomId) {
            throw Exception('이미 다른 파티에 참여중입니다.');
          }
          return; // 이미 이 방에 참여중인 경우 추가 처리 없이 종료
        }

        // 2. 채팅방 정보 확인
        final roomDoc = await transaction.get(roomRef);
        if (!roomDoc.exists) {
          throw Exception('채팅방이 존재하지 않습니다.');
        }

        final roomData = roomDoc.data()!;
        final currentMembers = roomData['currentMembers'] ?? 0;
        final maxMembers = roomData['maxMembers'] ?? 0;
        final members = Map<String, dynamic>.from(roomData['members'] ?? {});

        // 최대 인원 제한 확인
        if (currentMembers >= maxMembers) {
          throw Exception('방이 가득 찼습니다.');
        }

        // members에 userId가 없는 경우에만 처리
        if (!members.containsKey(userId)) {
          members[userId] = true;
          transaction.update(roomRef, {
            'members': members,
            'currentMembers': currentMembers + 1,
          });

          // 유저 상태 업데이트
          transaction.update(userRef, {
            'currentPartyId': roomId,
            'isInParty': true,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('joinRoom 실패: $e');
      throw Exception('채팅방 참여 중 오류가 발생했습니다: $e');
    }
  }

  // 채팅방 나가기
  Future<void> leaveRoom(String roomId, String userId) async {
    final roomRef = _firestore.collection('chatRooms').doc(roomId);
    final userRef = _firestore.collection('users').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final roomDoc = await transaction.get(roomRef);
        if (!roomDoc.exists) {
          throw Exception('채팅방이 존재하지 않습니다.');
        }

        final roomData = roomDoc.data()!;
        final currentMembers = roomData['currentMembers'] ?? 0;
        final members = Map<String, dynamic>.from(roomData['members'] ?? {});
        final leaderId = roomData['leaderId'];

        if (leaderId == userId) {
          // 방장이 나가면 방 비활성화
          transaction.update(roomRef, {
            'status': 'inactive',
            'members.$userId': FieldValue.delete(),
            'currentMembers': currentMembers - 1,
          });
        } else if (members.containsKey(userId)) {
          // 일반 멤버가 나가는 경우
          members.remove(userId);
          transaction.update(roomRef, {
            'members': members,
            'currentMembers': currentMembers - 1,
          });
        }

        // 유저 상태 업데이트
        transaction.update(userRef, {
          'currentPartyId': null,
          'isInParty': false,
          'lastUpdated': FieldValue.serverTimestamp()
        });
      });
    } catch (e) {
      print('leaveRoom 실패: $e');
      throw Exception('채팅방 나가기 중 오류가 발생했습니다: $e');
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