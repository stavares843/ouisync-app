import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ouisync_app/app/utils/utils.dart';

class SearchBar extends StatefulWidget {
  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '<search>',
              textAlign: TextAlign.center,
            )
          ),
          buildActionIcon(icon: Icons.search_outlined, onTap: () {}, size: 35.0)
        ]
      )
    );
  }
}