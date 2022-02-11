import 'package:contacts_service/contacts_service.dart';

class ContactService {
  Future<List<Map<String, dynamic>>> getContacts() async {
    List<Contact> contacts = await ContactsService.getContacts();
    return contacts
        .map((contact) {
          return {
            'name': contact.displayName,
            'number': contact.phones!.isNotEmpty
                ? RegExp(r'\d+')
                    .allMatches(contact.phones!.first.value!)
                    .map((e) => e.group(0))
                    .join("")
                : null
          };
        })
        .where((element) => element["number"] != null)
        .toList();
  }
}
