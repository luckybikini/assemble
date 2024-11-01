// lib/screens/makeroom_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class MakeRoomScreen extends StatefulWidget {
  const MakeRoomScreen({super.key});

  @override
  State<MakeRoomScreen> createState() => _MakeRoomScreenState();
}

class _MakeRoomScreenState extends State<MakeRoomScreen> {
  final _menuController = TextEditingController();
  final _maxMembersController = TextEditingController();
  final _storeController = TextEditingController();
  final _branchController = TextEditingController();
  final _authService = AuthService();
  final _chatService = ChatService();
  bool _isLoading = false;

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F8FA),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _createRoomAndNavigate() async {
    if (_menuController.text.isEmpty ||
        _maxMembersController.text.isEmpty ||
        _storeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 항목을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw '로그인이 필요합니다.';
      }

      // 채팅방 생성
      final roomId = await _chatService.createRoom(
        title: '${_storeController.text} 파티',
        menu: _menuController.text,
        maxMembers: int.parse(_maxMembersController.text),
        leaderId: user.uid,
        orderDeadline: DateTime.now().add(const Duration(hours: 1)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채팅방이 생성되었습니다!')),
        );

        // 채팅방으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(roomId: roomId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '파티 만들기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('메뉴'),
            _buildTextField(
              hint: '메뉴를 입력하세요',
              controller: _menuController,
            ),
            const SizedBox(height: 20),

            _buildLabel('총 인원수'),
            _buildTextField(
              hint: '인원수를 입력하세요',
              controller: _maxMembersController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            _buildLabel('업체명'),
            _buildTextField(
              hint: '주문할 가게를 입력하세요',
              controller: _storeController,
            ),
            const SizedBox(height: 20),

            _buildLabel('지점'),
            _buildTextField(
              hint: '주문할 식당의 지점을 입력하세요',
              controller: _branchController,
            ),
            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createRoomAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6E6FA),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
                    : const Text(
                  '채팅방 만들기',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
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
    _menuController.dispose();
    _maxMembersController.dispose();
    _storeController.dispose();
    _branchController.dispose();
    super.dispose();
  }
}