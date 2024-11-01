// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/chat_room.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;

  const ChatScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  Future<void> _leaveRoom() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _chatService.leaveRoom(widget.roomId, user.uid);
        await _authService.leaveParty(user.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('파티에서 나갔습니다.')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파티 나가기 실패: $e')),
        );
      }
    }
  }
  Widget _buildMessage(DocumentSnapshot message, bool isMe, String? nickname) {
    final data = message.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeString = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      key: ValueKey(message.id),  // 고유 키 추가
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFFE6E6FA),
              radius: 15,
              child: Text(
                nickname?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(  // Flexible 추가
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      nickname ?? '알 수 없음',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,  // Row의 크기를 내용물에 맞춤
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMe)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          timeString,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    Flexible(  // Flexible 추가
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFE6E6FA)
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['content'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          timeString,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    try {
      setState(() => _isSending = true);
      final user = _authService.currentUser;

      if (user != null) {
        await _chatService.sendMessage(
          widget.roomId,
          user.uid,
          messageText,
        );

        _messageController.clear();

        // 스크롤 위치 조정을 지연 실행
        await Future.delayed(const Duration(milliseconds: 100));
        if (_scrollController.hasClients) {
          await _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chatRooms')
              .doc(widget.roomId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('로딩중...');
            }

            if (!snapshot.data!.exists) {
              return const Text('존재하지 않는 방');
            }

            final room = ChatRoom.fromDocument(snapshot.data!);
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE6E6FA),
                  child: Text(
                    room.title.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${room.currentMembers}/${room.maxMembers}명',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _leaveRoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getMessages(widget.roomId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('오류 발생: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final data = message.data() as Map<String, dynamic>;
                      final isMe = currentUser?.uid == data['senderId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['senderId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          String? nickname;
                          if (userSnapshot.hasData && userSnapshot.data != null) {
                            nickname = userSnapshot.data!.get('nickname') as String?;
                          }
                          return _buildMessage(message, isMe, nickname);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: '메시지 입력',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F8FA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isSending ? Icons.hourglass_empty : Icons.send),
                      onPressed: _isSending ? null : _sendMessage,
                      color: const Color(0xFFE6E6FA),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}