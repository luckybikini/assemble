// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'makeroom_screen.dart';
import 'party_list_screen.dart';
import 'character_info_screen.dart';
import 'chat_screen.dart';
import '../services/auth_service.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  Widget _buildCurrentPartyCard(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final currentPartyId = userData?['currentPartyId'] as String?;

        if (currentPartyId == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 파티',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '참여 중인 파티가 없습니다',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chatRooms')
              .doc(currentPartyId)
              .snapshots(),
          builder: (context, roomSnapshot) {
            if (!roomSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final roomData = roomSnapshot.data!.data() as Map<String, dynamic>?;
            if (roomData == null) {
              return const Center(child: Text('파티 정보를 찾을 수 없습니다'));
            }

            final remainingTime = roomData['orderDeadline'].toDate().difference(DateTime.now());
            final remainingMinutes = remainingTime.inMinutes;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(roomId: currentPartyId),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 파티',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFCE93D8),
                          ),
                          child: Center(
                            child: Text(
                              roomData['title'].substring(0, min(2, roomData['title'].length)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roomData['title'] ?? '제목 없음',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${roomData['currentMembers']}/${roomData['maxMembers']} 명',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            remainingMinutes > 0
                                ? '주문 마감까지 ${remainingMinutes}분'
                                : '주문 마감',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: user == null
            ? null
            : StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final nickname = userData?['nickname'] as String? ?? '게스트';

            return Row(
              children: [
                Text(
                  '안녕하세요 $nickname님',
                  style: TextStyle(
                    color: Color(0xFF7F5E93),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CharacterInfoScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환영 메시지 추가
            const Text(
              '배달\nassemble',
              style: TextStyle(
                color: Color(0xFF6A1B9A),
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 40),

            // 현재 파티 카드
            _buildCurrentPartyCard(context),
            const SizedBox(height: 40),

            // 버튼들
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MakeRoomScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC871FD),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                '파티 만들기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PartyListScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: Color(0xFF6A1B9A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                '파티 참가',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                '함께 주문하고 배달비를 절약하세요!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// dart:math의 min 함수를 직접 구현
int min(int a, int b) => a < b ? a : b;