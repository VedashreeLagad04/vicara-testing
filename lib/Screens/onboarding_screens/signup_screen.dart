import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pinput/pin_put/pin_put.dart';
import 'package:provider/provider.dart';
import 'package:timer_count_down/timer_controller.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';
import 'package:vicara/Services/APIs/auth_api.dart';
import 'package:vicara/Services/APIs/emergency_info_api.dart';
import 'package:vicara/Services/auth/auth.dart';
import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/prefs.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final Preferences _preferences = Preferences();
  final TextEditingController _otpController = TextEditingController();
  int _index = 0;
  final CountdownController _controller = CountdownController(autoStart: false);
  bool canResend = false;
  String name = '';
  String number = '';
  String otp = '';
  final _formKey = GlobalKey<FormState>();
  final Auth _auth = Auth();
  final TextEditingController _pinPutController = TextEditingController();
  final FocusNode _pinPutFocusNode = FocusNode();
  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15.0),
    );
  }

  final EmergencyInfo _emergencyInfo = EmergencyInfo();

  Future<void> signInCallBack() async {
    try {
      print({'name': name, 'phoneNumber': number, 'userUID': _auth.currentUser!.uid});
      var res = await _serverLogUser.logUser(
          name: name, phoneNumber: number, userUID: _auth.currentUser!.uid);
      await _preferences.setString(res['auth_token'], "auth_token");
      await _preferences.setString(number, "phone_no");

      dynamic emerInfo = await _emergencyInfo.getEmergencyInfo();
      await _preferences.setBool(emerInfo["is_configured"] != false, "configured");
      Navigator.of(context).pushReplacementNamed(emerInfo["is_configured"] == false ? conf : home);
    } catch (err) {
      _auth.signOut();
      if (_controller != null) {
        _controller.restart();
        _controller.pause();
      }
      setState(() => _index = 0);
      Fluttertoast.showToast(
        msg: err.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color(0x4F464646),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  final AuthAPIs _serverLogUser = AuthAPIs();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (_index != 0) {
                      _controller.restart();
                      _controller.pause();
                      setState(() => _index = 0);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Center(
                    child: SvgPicture.asset('assets/Images/delivery_partner.svg'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                        width: 2.0, color: Provider.of<ThemeDataProvider>(context).orange),
                    borderRadius: BorderRadius.circular(10),
                    color: Provider.of<ThemeDataProvider>(context).orange,
                  ),
                  child: Stack(
                    children: [
                      Offstage(
                        offstage: _index != 0,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sign Up',
                                    style: Provider.of<ThemeDataProvider>(context)
                                        .textTheme['white-w700-s24'],
                                  ),
                                  Text(
                                    '/Login',
                                    style: Provider.of<ThemeDataProvider>(context)
                                        .textTheme['white-w400-s16'],
                                  ),
                                ],
                              ),
                              TextFormField(
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w500-s16'],
                                cursorColor: Provider.of<ThemeDataProvider>(context).white,
                                decoration: InputDecoration(
                                  hintText: 'Name',
                                  hintStyle: Provider.of<ThemeDataProvider>(context)
                                      .textTheme['white-w500-s16'],
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Provider.of<ThemeDataProvider>(context).white,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Name cannot be empty";
                                  }
                                  return null;
                                },
                                onChanged: (value) => name = value,
                              ),
                              TextFormField(
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w500-s16'],
                                cursorColor: Provider.of<ThemeDataProvider>(context).white,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Phone',
                                  hintStyle: Provider.of<ThemeDataProvider>(context)
                                      .textTheme['white-w500-s16'],
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Provider.of<ThemeDataProvider>(context).white,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null) {
                                    return "Name cannot be null";
                                  }
                                  if (value.length != 10 || int.tryParse(value) == null) {
                                    return "Invalid input";
                                  }
                                  return null;
                                },
                                onChanged: (value) => number = value,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 35.0),
                                child: RoundButton(
                                  text: 'Sign Me Up',
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      try {
                                        // await _auth.sendOTP(name: name, phoneNumber: number);
                                        setState(() {
                                          _index = 2;
                                        });
                                        _auth.signInWithPhone(
                                            context: context,
                                            phoneNo: number.trim(),
                                            callback: signInCallBack,
                                            loading: () {
                                              setState(() {
                                                _index = 1;
                                                _controller.start();
                                              });
                                            });
                                      } catch (err) {
                                        Fluttertoast.showToast(
                                          msg: err.toString(),
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: const Color(0x4F464646),
                                          textColor: Colors.black,
                                          fontSize: 16.0,
                                        );
                                      }
                                    }
                                  },
                                  textStyle: Provider.of<ThemeDataProvider>(context)
                                      .textTheme['dark-w400-s16'],
                                  color: Provider.of<ThemeDataProvider>(context).white,
                                ),
                              ),
                              Text(
                                'By signing up you agree to the terms and conditions of the application including the privacy policy and data cookies.',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w400-s8'],
                              )
                            ],
                          ),
                        ),
                      ),
                      Offstage(
                        offstage: _index != 1,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sign Up',
                                  style: Provider.of<ThemeDataProvider>(context)
                                      .textTheme['white-w700-s24'],
                                ),
                                Text(
                                  '/Login',
                                  style: Provider.of<ThemeDataProvider>(context)
                                      .textTheme['white-w400-s16'],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'OTP Verification Sent',
                              style: Provider.of<ThemeDataProvider>(context)
                                  .textTheme['white-w400-s12'],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: PinPut(
                                textStyle: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['dark-w600-s16'],
                                eachFieldMargin: const EdgeInsets.only(right: 3.0),
                                eachFieldPadding: const EdgeInsets.only(right: 3.0),
                                eachFieldWidth: 20,
                                fieldsCount: 6,
                                pinAnimationType: PinAnimationType.scale,
                                focusNode: _pinPutFocusNode,
                                controller: _pinPutController,
                                submittedFieldDecoration: _pinPutDecoration,
                                selectedFieldDecoration: _pinPutDecoration.copyWith(
                                  border: Border.all(
                                    color: Colors.deepPurpleAccent.withOpacity(.5),
                                  ),
                                ),
                                followingFieldDecoration: _pinPutDecoration,
                                // onSubmit: (otp) async {
                                //   try {
                                //     await _auth.varifyOTP(otp, signInCallBack);
                                //   } catch (err) {
                                //     Fluttertoast.showToast(
                                //       msg: err.toString(),
                                //       toastLength: Toast.LENGTH_SHORT,
                                //       gravity: ToastGravity.BOTTOM,
                                //       timeInSecForIosWeb: 1,
                                //       backgroundColor: const Color(0x4F464646),
                                //       textColor: Colors.white,
                                //       fontSize: 16.0,
                                //     );
                                //   }
                                // },
                                inputDecoration: InputDecoration(
                                  fillColor: Provider.of<ThemeDataProvider>(context).white,
                                  border: const UnderlineInputBorder(borderSide: BorderSide.none),
                                ),
                                separator: const SizedBox(
                                  width: 13,
                                ),
                                onChanged: (value) => otp = value,
                              ),
                            ),
                            Countdown(
                              controller: _controller,
                              build: (_, double time) => Text(
                                'The sent otp will expire in $time seconds',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w400-s8'],
                              ),
                              seconds: 60,
                              interval: const Duration(milliseconds: 1000),
                              onFinished: () => canResend = true,
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  setState(() {
                                    _index = 2;
                                  });
                                  _auth.signInWithPhone(
                                      context: context,
                                      phoneNo: number.trim(),
                                      callback: signInCallBack,
                                      loading: () {
                                        setState(() {
                                          _index = 1;
                                          _controller.start();
                                        });
                                      });
                                } catch (err) {
                                  Fluttertoast.showToast(
                                    msg: err.toString(),
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: const Color(0x4F464646),
                                    textColor: Colors.black,
                                    fontSize: 16.0,
                                  );
                                }
                                _controller.restart();
                              },
                              child: Text(
                                'Resend OTP',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w400-s8-u'],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: RoundButton(
                                text: 'Verify',
                                onPressed: () async {
                                  try {
                                    await _auth.varifyOTP(otp, signInCallBack);
                                  } catch (err) {
                                    Fluttertoast.showToast(
                                      msg: err.toString(),
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: const Color(0x4F464646),
                                      textColor: Colors.white,
                                      fontSize: 16.0,
                                    );
                                  }
                                },
                                textStyle: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['dark-w400-s16'],
                                color: Provider.of<ThemeDataProvider>(context).white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Offstage(
                        offstage: _index != 2,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
