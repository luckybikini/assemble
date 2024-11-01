// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  Future<bool> isUserInParty(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return userData?['currentPartyId'] != null && userData?['isInParty'] == true;
    } catch (e) {
      print('파티 참여 상태 확인 실패: $e');
      return false;
    }
  }
  // 이메일 중복 체크
  Future<bool> isEmailAlreadyInUse(String email) async {
    try {
      print('이메일 중복 체크: $email'); // 디버그 로그
      final result = await _auth.fetchSignInMethodsForEmail(email);
      return result.isNotEmpty;
    } catch (e) {
      print('이메일 중복 체크 실패: $e'); // 디버그 로그
      throw '이메일 중복 확인 중 오류가 발생했습니다.';
    }
  }

  // 회원가입
  Future<User?> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      print('회원가입 진행: $email, $nickname'); // 디버그 로그

      // 이메일/비밀번호로 계정 생성
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      // Firestore에 사용자 정보 저장
      if (user != null) {
        print('Firebase Auth 계정 생성 성공'); // 디버그 로그

        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'nickname': nickname,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'currentPartyId': null,  // 현재 참여중인 파티 ID
          'isInParty': false,
        });

        print('Firestore 데이터 저장 성공'); // 디버그 로그

        // Firebase Auth 프로필 업데이트
        await user.updateDisplayName(nickname);

        print('프로필 업데이트 성공'); // 디버그 로그
        return user;
      }

      throw '회원가입에 실패했습니다.';
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth 에러: ${e.code}, ${e.message}'); // 디버그 로그

      switch (e.code) {
        case 'weak-password':
          throw '비밀번호가 너무 약합니다.';
        case 'email-already-in-use':
          throw '이미 사용 중인 이메일입니다.';
        case 'invalid-email':
          throw '유효하지 않은 이메일 형식입니다.';
        default:
          throw '회원가입 중 오류가 발생했습니다: ${e.message}';
      }
    } catch (e) {
      print('기타 에러: $e'); // 디버그 로그
      throw '회원가입 중 알 수 없는 오류가 발생했습니다: $e';
    }
  }

  Future<void> updatePartyStatus({
    required String userId,
    String? partyId,
    required bool isInParty,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'currentPartyId': partyId,
        'isInParty': isInParty,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('파티 상태 업데이트 실패: $e');
      throw '파티 상태 업데이트 중 오류가 발생했습니다.';
    }
  }

  Future<void> leaveParty(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'currentPartyId': null,
        'isInParty': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('파티 나가기 실패: $e');
      throw '파티 나가기 중 오류가 발생했습니다.';
    }
  }
  // 로그인
  Future<User?> signIn(String email, String password) async {
    try {
      print('로그인 진행: $email'); // 디버그 로그

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      // 마지막 로그인 시간 업데이트
      if (user != null) {
        print('Firebase Auth 로그인 성공'); // 디버그 로그

        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        print('Firestore 업데이트 성공'); // 디버그 로그
        return user;
      }

      throw '로그인에 실패했습니다.';
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth 에러: ${e.code}, ${e.message}'); // 디버그 로그

      switch (e.code) {
        case 'user-not-found':
          throw '존재하지 않는 계정입니다.';
        case 'wrong-password':
          throw '잘못된 비밀번호입니다.';
        case 'invalid-email':
          throw '유효하지 않은 이메일 형식입니다.';
        case 'user-disabled':
          throw '비활성화된 계정입니다.';
        default:
          throw '로그인 중 오류가 발생했습니다: ${e.message}';
      }
    } catch (e) {
      print('기타 에러: $e'); // 디버그 로그
      throw '로그인 중 알 수 없는 오류가 발생했습니다: $e';
    }
  }
}