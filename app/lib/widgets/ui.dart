import 'package:flutter/material.dart';

import '../theme.dart';

/// Brutalist offset card: a dark backing block with the content panel nudged
/// up-left so a hard shadow shows through. Used across every screen.
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
      decoration: const BoxDecoration(color: ink),
      child: Transform.translate(
        offset: const Offset(-4, -4),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: ink, width: 2),
          ),
          child: child,
        ),
      ),
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
      child: ShadowCard(
        color: accent,
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
