// lib/screens/party_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/chat_room.dart';

import 'chat_screen.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  bool _showEatingTogether = true;

  // lib/screens/party_list_screen.dart
  Future<void> _joinAndNavigateToChat(BuildContext context, ChatRoom room) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      // 디버깅 로그 추가
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data();
      print('디버그 로그:');
      print('참가하려는 방 ID: ${room.id}');
      print('유저의 currentPartyId: ${userData?['currentPartyId']}');
      print('유저의 isInParty: ${userData?['isInParty']}');

      // 이미 다른 파티에 참여중인지 확인
      final isInParty = await _authService.isUserInParty(currentUser.uid);
      if (isInParty && userData?['currentPartyId'] != room.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 다른 파티에 참여중입니다. 기존 파티를 먼저 나가주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 참여 인원 초과 체크
      if (room.currentMembers >= room.maxMembers) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 정원이 가득 찼습니다.')),
          );
        }
        return;
      }

      // 채팅방 참여 처리
      await _chatService.joinRoom(room.id, currentUser.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파티에 참여했습니다!')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(roomId: room.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참여 실패: $e')),
        );
      }
    }
  }
  // party_list_screen.dart의 _buildPartyCard 메서드 수정
  Widget _buildPartyCard(BuildContext context, ChatRoom room) {
    final now = DateTime.now();
    final remainingTime = room.orderDeadline.difference(now);
    String timeText = '';

    if (remainingTime.isNegative) {
      timeText = '마감됨';
    } else {
      if (remainingTime.inHours > 0) {
        timeText = '${remainingTime.inHours}시간 ${remainingTime.inMinutes % 60}분';
      } else {
        timeText = '${remainingTime.inMinutes}분';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${room.currentMembers}/${room.maxMembers}',
                        style: const TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '메뉴: ${room.menu}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '주문 마감까지: $timeText',
                  style: TextStyle(
                    color: remainingTime.isNegative ? Colors.red : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 48,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            child: TextButton(
              onPressed: (remainingTime.isNegative || room.currentMembers >= room.maxMembers)
                  ? null
                  : () async {
                // 현재 유저 가져오기
                final currentUser = _authService.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인이 필요합니다.')),
                  );
                  return;
                }

                // 참여하기 전에 유저의 현재 상태 확인
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .get();
                final userData = userDoc.data();

                // 디버그 로그 출력
                print('===== 참여하기 버튼 클릭 =====');
                print('참가하려는 방 ID: ${room.id}');
                print('유저의 currentPartyId: ${userData?['currentPartyId']}');
                print('유저의 isInParty: ${userData?['isInParty']}');
                print('===========================');

                // 파티 참여 상태 확인
                if (userData?['isInParty'] == true && userData?['currentPartyId'] != room.id) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('이미 다른 파티에 참여중입니다. 기존 파티를 먼저 나가주세요.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                // 참여 처리 실행
                await _joinAndNavigateToChat(context, room);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6A1B9A),
              ),
              child: Text(
                room.currentMembers >= room.maxMembers
                    ? '정원 초과'
                    : remainingTime.isNegative
                    ? '마감됨'
                    : '참여하기',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              '필터',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            Switch(
              value: _showEatingTogether,
              onChanged: (value) {
                setState(() => _showEatingTogether = value);
              },
              activeColor: const Color(0xFF6A1B9A),
              activeTrackColor: const Color(0xFFCE93D8),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: _showEatingTogether
                        ? const Color(0xFF6A1B9A).withOpacity(0.2)
                        : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '같이 먹어요',
                    style: TextStyle(
                      color: _showEatingTogether
                          ? const Color(0xFF6A1B9A)
                          : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: !_showEatingTogether
                        ? const Color(0xFF6A1B9A).withOpacity(0.2)
                        : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '따로 먹어요',
                    style: TextStyle(
                      color: !_showEatingTogether
                          ? const Color(0xFF6A1B9A)
                          : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatRoom>>(
              stream: _chatService.getActiveRooms(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data ?? [];
                if (rooms.isEmpty) {
                  return const Center(
                    child: Text('현재 활성화된 파티가 없습니다.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) => _buildPartyCard(
                    context,
                    rooms[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}