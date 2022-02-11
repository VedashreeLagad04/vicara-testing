import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/contact_edit_card.dart';
import 'package:vicara/Screens/Widgets/contact_selection_screen.dart';
import 'package:vicara/Screens/Widgets/loading_screen.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';
import 'package:vicara/Services/APIs/emergency_info_api.dart';
import 'package:vicara/Services/consts.dart';

// ignore: must_be_immutable
class EmergencyInfoScreen extends StatefulWidget {
  static String id = emergencyInfo;
  const EmergencyInfoScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyInfoScreen> createState() => _EmergencyInfoScreenState();
}

class _EmergencyInfoScreenState extends State<EmergencyInfoScreen> {
  var contacts = [];
  final EmergencyInfo _emergencyInfo = EmergencyInfo();
  final TextEditingController _ctrl = TextEditingController();

  var message = '';
  bool _isLoading = true;
  @override
  void initState() {
    _emergencyInfo.getEmergencyInfo().then((data) {
      setState(() {
        contacts = data['emergencyContacts'];
        message = data['emergencyMessage'];
        _isLoading = false;
      });
      _ctrl.text = message;
    }).catchError((err) {
      print(err);
      setState(() {
        _isLoading = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const LoadingScreen()
        : Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [Icon(Icons.arrow_back), SizedBox()],
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Contact List',
                        style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
                      ),
                      Text(
                        'Emergency Contacts',
                        style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w500-s16'],
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        ...(contacts
                            .map(
                              (contact) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ContactEditCard(
                                  contactName: contact['name'] ?? 'Unknown',
                                  number: contact['contact'] ?? 'Unknown',
                                  onTap: () {
                                    setState(() async {
                                      contacts = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ContactSelectionScreen(selectedContacts: contacts),
                                        ),
                                      );
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList()),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ContactEditCard(
                            contactName: '+ Add new',
                            number: '',
                            onTap: () {
                              setState(() async {
                                contacts = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ContactSelectionScreen(selectedContacts: contacts),
                                  ),
                                );
                              });
                            },
                            icon: Icons.add,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Emergency Message ',
                                  style: Provider.of<ThemeDataProvider>(context)
                                      .textTheme['dark-w500-s16'],
                                ),
                                const WidgetSpan(
                                  child: Icon(Icons.edit_outlined, size: 16),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_ctrl.text.length}/1000',
                            style:
                                Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s12'],
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      TextField(
                        minLines: 5,
                        maxLines: 15,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) {
                          message = value;
                        },
                        controller: _ctrl,
                        decoration: InputDecoration(
                          hintText: 'Start Typing...',
                          hintStyle:
                              Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s12'],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 21, vertical: 14),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(4.0),
                            ),
                            borderSide: BorderSide(),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4.0),
                            ),
                            borderSide:
                                BorderSide(color: Provider.of<ThemeDataProvider>(context).orange),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 64),
                          child: RoundButton(
                            text: 'Confirm',
                            onPressed: () async {
                              try {
                                await _emergencyInfo.setEmergencyInfo(emergencyInfo: {
                                  "payload": {
                                    "emergencyContacts": contacts.map((ele) {
                                      return {"name": ele["name"], "contact": ele["number"]};
                                    }).toList(),
                                    "emergencyMessage": message
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
