import 'package:flutter/material.dart';
import '../../features/diagnosis/presentation/job_portrait.dart';

/// The original transparent job crests supplied by the user.
class RoleLogo extends StatelessWidget {
  const RoleLogo({super.key, required this.role, this.size = 48});
  final String role;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
      'assets/images/role_logos/${JobPortrait.roleNames.containsKey(role) ? role : 'warrior'}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: '${JobPortrait.roleNames[role] ?? '剣士'}の職業ロゴ');
}
