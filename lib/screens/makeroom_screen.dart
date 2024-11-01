// lib/screens/makeroom_screen.dart
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MakeRoomScreen extends StatelessWidget {
  const MakeRoomScreen({super.key});

  Widget _buildTextField({required String hint}) {
    return TextField(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '파티를 만들었습니다',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('매뉴'),
            _buildTextField(hint: '메뉴를 입력하세요'),
            const SizedBox(height: 20),

            _buildLabel('총 인원수'),
            _buildTextField(hint: '인원수를 입력하세요'),
            const SizedBox(height: 20),

            _buildLabel('업체명'),
            _buildTextField(hint: '주문할 가게를 입력하세요'),
            const SizedBox(height: 20),

            _buildLabel('지점'),
            _buildTextField(hint: '주문할 식당의 지점을 입력하세요'),
            const SizedBox(height: 40),

            // 채팅방 입장 버튼 추가
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen(roomId: '',)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6E6FA),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '채팅방 입장하기',
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
}