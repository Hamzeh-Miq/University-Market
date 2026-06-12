import 'package:flutter_test/flutter_test.dart';
import 'package:university_market/services/auth_service.dart';

void main() {
  group('AuthService.isStudentEmail', () {
    test('accepts valid Applied Science Private University student emails', () {
      expect(AuthService.isStudentEmail('student@students.asu.edu.jo'), isTrue);
      expect(AuthService.isStudentEmail('STUDENT@STUDENTS.ASU.EDU.JO'), isTrue);
    });

    test('rejects non-student or legacy domains', () {
      expect(AuthService.isStudentEmail('student@asu.edu.jo'), isFalse);
      expect(AuthService.isStudentEmail('student@students.edu.jo'), isFalse);
      expect(AuthService.isStudentEmail('student@example.com'), isFalse);
    });
  });
}
