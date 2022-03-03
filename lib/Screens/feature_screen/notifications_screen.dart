import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:vicara/Screens/Widgets/notification_card.dart';
import 'package:vicara/Services/APIs/notification_and_fall_history_apis.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final int _pageSize = 15;
  final NotificationAndFallHistory _notificationAndFallHistory = NotificationAndFallHistory();
  final PagingController<int, dynamic> _pagingController = PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await _notificationAndFallHistory.getNotifications(
          pageNumber: pageKey, pageSize: _pageSize);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        int? nextPageKey = (pageKey + newItems.length) as int?;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'All Notifications',
                        style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
                      )
                    ],
                  ),
                  SvgPicture.asset('assets/Images/falling_delivery_partner_mini.svg'),
                ],
              ),
            ),
            preferredSize: Size(MediaQuery.of(context).size.width, 140)),
        body: PagedListView<int, dynamic>(
          // shrinkWrap: true,
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<dynamic>(
            itemBuilder: (context, element, index) {
              return NotificationCard(
                event: element['type'] ?? 'UNKNOWN',
                time: element['time'].length < 5
                    ? element['time']
                    : element['time'].substring(0, 5) ?? 'UNKNOWN',
                date: element['date'] ?? 'UNKNOWN',
                place: element['place'] != null ? element['place'].split('/')[0] : 'Nearby',
              );
            },
          ),
        ),
        // body: SingleChildScrollView(
        //   child: Column(
        //     children: [
        //       Padding(
        //         padding: const EdgeInsets.all(15.0),
        // child:
        //     ],
        //   ),
        // ),
      ),
    );
  }
}
