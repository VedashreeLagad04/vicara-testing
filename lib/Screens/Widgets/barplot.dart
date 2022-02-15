import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class GraphWidget extends StatefulWidget {
  const GraphWidget({Key? key}) : super(key: key);

  @override
  _GraphWidgetState createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  int dayVal = 7;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fall Trend',
              style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                onChanged: (int? val) {
                  setState(() {
                    dayVal = val!;
                  });
                },
                value: dayVal,
                icon: Icon(
                  Icons.keyboard_arrow_down_outlined,
                  color: Provider.of<ThemeDataProvider>(context).black,
                ),
                items: [
                  DropdownMenuItem(
                    child: Text(
                      'Last 7 Days',
                      style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s18'],
                    ),
                    value: 7,
                  ),
                  DropdownMenuItem(
                    child: Text(
                      'Last 1 Month',
                      style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s18'],
                    ),
                    value: 730,
                  ),
                ],
              ),
            )
          ],
        ),
        SvgPicture.asset('assets/Images/temp_graph.svg')
      ],
    );
  }
}
