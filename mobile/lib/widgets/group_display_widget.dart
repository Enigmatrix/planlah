import 'package:flutter/material.dart';

class GroupDisplay extends StatefulWidget {
  String name;
  String mostRecentText;
  String imageUrl;
  String time;
  bool isMessageRead;

  GroupDisplay({
    Key? key,
    required this.name,
    required this.mostRecentText,
    required this.imageUrl,
    required this.time,
    required this.isMessageRead,
  }) : super(key: key);

  @override
  State<GroupDisplay> createState() => _GroupDisplayState();
}

class _GroupDisplayState extends State<GroupDisplay> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {

      },
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: 10
        ),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.imageUrl),
                      maxRadius: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.mostRecentText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: widget.isMessageRead ? FontWeight.normal : FontWeight.bold
                                ),
                              )
                            ],
                          )
                        )
                    ),
                    Text(
                      widget.time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: widget.isMessageRead ? FontWeight.normal : FontWeight.bold
                      ),
                    )
                  ]
                )
            )
          ],
        ),
      ),
    );
  }
}
