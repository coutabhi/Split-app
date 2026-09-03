import 'package:flutter/material.dart';

import '../models/person.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.person,
    this.radius = 18,
    this.selected = false,
    this.showCheck = false,
  });

  final Person person;
  final double radius;
  final bool selected;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: person.color,
      child: showCheck && selected
          ? Icon(Icons.check, color: Colors.white, size: radius)
          : Text(
              person.initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.75,
              ),
            ),
    );

    if (!selected || !showCheck) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, size: radius * 0.6, color: person.color),
          ),
        ),
      ],
    );
  }
}
