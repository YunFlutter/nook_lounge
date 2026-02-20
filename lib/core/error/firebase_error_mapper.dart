import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:nook_lounge_app/core/error/error_display_info.dart';

class FirebaseErrorMapper {
  const FirebaseErrorMapper._();

  static ErrorDisplayInfo map(Object error) {
    if (error is FirebaseAuthException) {
      return _mapAuthError(error);
    }

    if (error is FirebaseException) {
      return _mapFirebaseError(error);
    }

    if (error is SocketException) {
      return const ErrorDisplayInfo(
        title: '네트워크 연결이 불안정해요',
        message: '인터넷 연결을 확인한 뒤 다시 시도해 주세요.',
      );
    }

    return ErrorDisplayInfo(
      title: '데이터를 불러오지 못했어요',
      message: '알 수 없는 오류가 발생했어요. 원인: ${error.runtimeType}',
    );
  }

  static ErrorDisplayInfo _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return const ErrorDisplayInfo(
          title: '로그인 중 네트워크 오류가 발생했어요',
          message: '인터넷 상태를 확인해 주세요. (auth/network-request-failed)',
        );
      case 'user-disabled':
        return const ErrorDisplayInfo(
          title: '사용이 중지된 계정이에요',
          message: '해당 계정은 비활성화 상태입니다. (auth/user-disabled)',
        );
      case 'operation-not-allowed':
        return const ErrorDisplayInfo(
          title: '로그인 제공자가 비활성화되어 있어요',
          message:
              'Firebase Authentication 설정을 확인해 주세요. (auth/operation-not-allowed)',
        );
      default:
        return ErrorDisplayInfo(
          title: '로그인에 실패했어요',
          message: '원인 코드: auth/${error.code}',
        );
    }
  }

  static ErrorDisplayInfo _mapFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return const ErrorDisplayInfo(
          title: '권한이 없어서 데이터를 읽을 수 없어요',
          message:
              'Firestore Rules에서 읽기/쓰기 권한을 확인해 주세요. (firestore/permission-denied)',
        );
      case 'unavailable':
        return const ErrorDisplayInfo(
          title: '현재 서버에 연결할 수 없어요',
          message: '잠시 후 다시 시도해 주세요. (firestore/unavailable)',
        );
      case 'failed-precondition':
        return const ErrorDisplayInfo(
          title: 'Firestore 설정이 아직 완료되지 않았어요',
          message:
              'Firestore Database 생성 및 인덱스/규칙을 확인해 주세요. (firestore/failed-precondition)',
        );
      default:
        return ErrorDisplayInfo(
          title: '데이터 처리 중 오류가 발생했어요',
          message: '원인 코드: firestore/${error.code}',
        );
    }
  }
}
