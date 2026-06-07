import 'package:flutter/material.dart';

import '../theme.dart';

/// Soft rounded surface card with a subtle drop shadow. Used across every
/// screen. (Was a brutalist offset card; now matches the periwinkle web theme.)
class ShadowCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  const ShadowCard({
    super.key,
    required this.child,
    this.color = paper,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.10),
            blurRadius: 30,
            spreadRadius: -12,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small uppercase accent label above a heading.
class Kicker extends StatelessWidget {
  final String text;
  const Kicker(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: accent,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class ErrorCard extends StatelessWidget {
  final String message;
  const ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDEAE2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: peach.withValues(alpha: 0.5)),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF9A3B22),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
