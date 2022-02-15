import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Auth {
  late String _verificationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<User?> authState;
  late User? currentUser = _auth.currentUser;
  // late ConfirmationResult _confirmationResult;
  Auth() {
    authState = _auth.userChanges();
  }
  signInAnon() async {
    await _auth.signInAnonymously();
  }
  // sendOTP(String phoneNo) async => _confirmationResult = await _auth.signInWithPhoneNumber(
  //       phoneNo,
  //       RecaptchaVerifier(
  //         container: 'recaptcha',
  //         size: RecaptchaVerifierSize.compact,
  //         theme: RecaptchaVerifierTheme.dark,
  //       ),
  //     );

  Future<void> varifyOTP(otp, Function() callback) async {
    PhoneAuthCredential credential =
        PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: otp);
    await _auth.signInWithCredential(credential);
    await callback();
  }

  Future<void> signOut() async => await _auth.signOut();
  void signInWithPhone({
    required BuildContext context,
    required String phoneNo,
    required void Function() loading,
    required Function() callback,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91' + phoneNo.trim(),
      timeout: const Duration(seconds: 10),
      verificationCompleted: (PhoneAuthCredential creds) async {
        await _auth.signInWithCredential(creds);
        await callback();
        Fluttertoast.showToast(
          msg: 'OTP Autoverified',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: const Color(0x4F464646),
          textColor: Colors.black,
          fontSize: 16.0,
        );
      },
      verificationFailed: (FirebaseAuthException authException) {
        Fluttertoast.showToast(
          msg:
              'Phone number verification failed. Code: ${authException.code}. Message: ${authException.message}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: const Color(0x4F464646),
          textColor: Colors.black,
          fontSize: 16.0,
        );

        throw "Phone number verification failed. Code: ${authException.code}. Message: ${authException.message}";
      },
      codeSent: (String verificationId, [int? forceResendingToken]) {
        Fluttertoast.showToast(
          msg: 'Varification code sent to phone ending with ${phoneNo.substring(6)}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: const Color(0x4F464646),
          textColor: Colors.black,
          fontSize: 16.0,
        );
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        loading();
      },
    );
  }
}
