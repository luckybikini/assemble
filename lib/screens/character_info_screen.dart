import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CharacterInfoScreen extends StatefulWidget {
  const CharacterInfoScreen({super.key});

  @override
  State<CharacterInfoScreen> createState() => _CharacterInfoScreenState();
}

class _CharacterInfoScreenState extends State<CharacterInfoScreen> {
  final _authService = AuthService();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _currentEmail;
  String? _currentNickname;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _currentEmail = user.email;
          _currentNickname = userData?['nickname'];
          _nicknameController.text = _currentNickname ?? '';
        });
      }
    }
  }

  Future<void> _updateNickname() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별명을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateNickname(user.uid, _nicknameController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('별명이 업데이트되었습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업데이트 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: const Text(
            '정말로 탈퇴하시겠습니까?\n탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                '탈퇴',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.deleteAccount(user.uid);
        if (mounted) {
          // 로그인 화면으로 이동
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계정 삭제 실패: $e')),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '개인 정보',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 별명 섹션
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '별명',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: '별명을 입력하세요',
                        filled: true,
                        fillColor: const Color(0xFFF8F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateNickname,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCC8FFA),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('별명 변경'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 계정 정보 섹션
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '계정 정보',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email: ${_currentEmail ?? ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 회원 탈퇴 버튼
              TextButton(
                onPressed: _showDeleteConfirmDialog,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  '회원 탈퇴',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }
}