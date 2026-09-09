import 'package:flutter/material.dart';

import '../models/group.dart';

class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.group, this.size = 44});

  final Group group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = group.name.trim().isEmpty ? '?' : group.name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(group.colorValue),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
