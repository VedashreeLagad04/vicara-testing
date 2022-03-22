import 'package:contacts_service/contacts_service.dart';

class ContactService {
  Future<List<Map<String, dynamic>>> getContacts({String query = ''}) async {
    List<Contact> contacts = await ContactsService.getContacts(query: query);
    return contacts
        .where((element) => element.phones != null)
        .map((contact) {
          return {
            'name': contact.displayName,
            'contact': contact.phones!.isNotEmpty
                ? RegExp(r'\d+')
                    .allMatches(contact.phones!.first.value??'contact')
                    .map((e) => e.group(0))
                    .join("")
                : null
          };
        })
        .where((element) => element["contact"] != null)
        .toList();
  }
}
