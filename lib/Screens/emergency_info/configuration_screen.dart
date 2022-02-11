import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/contact_selection_screen.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';
import 'package:vicara/Services/APIs/emergency_info_api.dart';
import 'package:vicara/Services/auth/auth.dart';
import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/logout_popup.dart';

class ConfigurationScreen extends StatefulWidget {
  static String id = conf;
  const ConfigurationScreen({Key? key}) : super(key: key);

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final Auth _auth = Auth();
  late StreamSubscription<User?> authListner;
  static final EmergencyInfo _emergencyInfo = EmergencyInfo();

  @override
  void initState() {
    authListner = _auth.authState.listen((user) {
      if (user == null) Navigator.of(context).pushReplacementNamed(auth);
    });
    super.initState();
  }

  @override
  void dispose() {
    authListner.cancel();
    super.dispose();
  }

  final GlobalKey<FormState> _key = GlobalKey();
  String? emergencyMessage = '';
  List<Map<String, String>> selectedContacts = [];
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          popLogout(
              context: context,
              callback: _auth.signOut,
              title: "Logout?",
              subTitle: "Do you want logout?");
          return true;
        } catch (e) {
          return false;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => {_auth.signOut()},
                    ),
                    const SizedBox(),
                  ],
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: SvgPicture.asset('assets/Images/falling_delivary_partner.svg'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Information',
                        style: Provider.of<ThemeDataProvider>(context).textTheme['white-w700-s24'],
                      ),
                      Text(
                        'Add Emergency Contacts',
                        style: Provider.of<ThemeDataProvider>(context).textTheme['white-w500-s16'],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: selectedContacts.length > 4
                            ? selectedContacts
                                .sublist(0, 5)
                                .map(
                                  (element) => MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () async {
                                        var contacts = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ContactSelectionScreen(
                                                selectedContacts: selectedContacts),
                                          ),
                                        );
                                        setState(() {
                                          selectedContacts = contacts;
                                        });
                                      },
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          element["name"]![0],
                                          style: Provider.of<ThemeDataProvider>(context)
                                              .textTheme["dark-w500-s16"],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList()
                            : [
                                ...selectedContacts,
                                ...List.generate(5 - selectedContacts.length, (index) => null)
                              ]
                                .map(
                                  (element) => MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () async {
                                        var contacts = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ContactSelectionScreen(
                                                selectedContacts: selectedContacts),
                                          ),
                                        );
                                        setState(() {
                                          selectedContacts = contacts;
                                        });
                                      },
                                      child: element != null
                                          ? CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: Text(
                                                element["name"]![0],
                                                style: Provider.of<ThemeDataProvider>(context)
                                                    .textTheme["dark-w500-s16"],
                                              ),
                                            )
                                          : Card(
                                              child: Padding(
                                                padding: const EdgeInsets.all(5.0),
                                                child: Icon(
                                                  Icons.add_rounded,
                                                  color: Provider.of<ThemeDataProvider>(context)
                                                      .orange,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      Text(
                        'Add Emergency Message',
                        style: Provider.of<ThemeDataProvider>(context).textTheme['white-w500-s16'],
                      ),
                      Form(
                        key: _key,
                        child: TextFormField(
                          validator: (val) {
                            if (val == null || val.length < 50) {
                              return 'Message must be 50 character long';
                            }
                          },
                          style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s12'],
                          minLines: 5,
                          maxLines: 15,
                          keyboardType: TextInputType.multiline,
                          onChanged: (value) => emergencyMessage = value,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Provider.of<ThemeDataProvider>(context).white,
                            hintText: 'Start Typing...',
                            hintStyle:
                                Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s12'],
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 21, vertical: 14),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(
                                Radius.circular(4.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: RoundButton(
                            text: 'Confirm',
                            onPressed: () async {
                              _key.currentState!.validate();
                              try {
                                await _emergencyInfo.setEmergencyInfo(emergencyInfo: {
                                  "payload": {
                                    "emergencyContacts": selectedContacts.map((ele) {
                                      return {"name": ele["name"], "contact": ele["number"]};
                                    }).toList(),
                                    "emergencyMessage": emergencyMessage
                                  }
                                });
                                await Navigator.of(context).pushReplacementNamed(home);
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
                            textStyle:
                                Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s16'],
                            color: Provider.of<ThemeDataProvider>(context).white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
