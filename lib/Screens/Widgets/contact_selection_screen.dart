import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/contact_name_card.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';
import 'package:vicara/Services/contact.dart';

// ignore: must_be_immutable
class ContactSelectionScreen extends StatefulWidget {
  List selectedContacts = [];
  ContactSelectionScreen({required this.selectedContacts, Key? key}) : super(key: key);
  @override
  State<ContactSelectionScreen> createState() => _ContactSelectionScreenState();
}

class _ContactSelectionScreenState extends State<ContactSelectionScreen> {
  final ContactService _contactService = ContactService();
  List<Map<String, String>> selecteds = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(widget.selectedContacts)),
            ),
            Text(
              'Contact List',
              style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s16'],
                contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(4.0),
                  ),
                  borderSide: BorderSide(),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(4.0),
                  ),
                  borderSide: BorderSide(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List>(
                  future: _contactService.getContacts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return ListView(
                            shrinkWrap: true,
                            children: snapshot.data!.map(
                              (data) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: ContactNameCard(
                                    contactName: data["name"] ?? "User",
                                    number: "+91 " + data["number"],
                                    isSelected: selecteds
                                        .where((element) =>
                                            element["name"] == data["name"] &&
                                            element["number"] == data["number"])
                                        .isNotEmpty,
                                    onTap: () {
                                      setState(() {
                                        if (selecteds
                                            .where((element) =>
                                                element["name"] == data["name"] &&
                                                element["number"] == data["number"])
                                            .isNotEmpty) {
                                          selecteds.removeWhere((element) =>
                                              element["name"] == data["name"] &&
                                              element["number"] == data["number"]);
                                        } else {
                                          selecteds.add(
                                              {"name": data["name"], "number": data["number"]});
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ).toList());
                      } else {
                        return const Center(
                          child: Text("Something Went Wrong!"),
                        );
                      }
                    } else {
                      return const Center(child: CircularProgressIndicator(color: Colors.orange));
                    }
                  }),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: RoundButton(
                  text: 'Confirm Contacts',
                  onPressed: () {
                    Navigator.of(context).pop(selecteds);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SingleChildScrollView(
//                 child: FutureBuilder<List<Map<String, dynamic>>>(
//                     future: _contactService.getContacts(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.active) {
//                         return const Center(
//                           child: CircularProgressIndicator(),
//                         );
//                       } else {
//                         return snapshot.hasData
//                             ? Column(
//                                 children: snapshot.data!.map((contact) {
//                                   Random _rand = Random();
//                                   return Padding(
//                                     padding: const EdgeInsets.symmetric(vertical: 4.0),
//                                     child: ContactNameCard(
//                                       contactName: contact['name'],
//                                       number: contact['number'] ?? "My number",
//                                       isSelected: _rand.nextInt(10) % 4 == 0,
//                                       onTap: () {
//                                         debugPrint('object');
//                                       },
//                                     ),
//                                   );
//                                 }).toList(),
//                               )
//                             : const Center(
//                                 child: Text('No contact found!'),
//                               );
//                       }
//                     }),
//                 // child: Column(
//                 //   children: List.generate(
//                 //     30,
//                 //     (index) {
//                 //

//                 //     },
//                 //   ),
//                 // ),
//               ),
