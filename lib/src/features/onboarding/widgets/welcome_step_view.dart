import 'package:flutter/material.dart';

/// Step 1: Welcome slide introducing ByteMeter's core capabilities and zero-telemetry privacy promise.
class WelcomeStepView extends StatelessWidget {
  const WelcomeStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Glowing Hero Icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.speed_rounded,
              color: colorScheme.onPrimary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          // App Title & Tagline
          Text(
            'Welcome to ByteMeter',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Precision real-time network speed metering & intelligent data analytics.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Feature Highlights
          _buildPillarCard(
            context,
            icon: Icons.bolt_rounded,
            iconColor: colorScheme.primary,
            title: 'Sub-Second Speed Meter',
            description:
                'Live status bar & notification transfer rates with separate upload/download indicators.',
          ),
          const SizedBox(height: 12),
          _buildPillarCard(
            context,
            icon: Icons.pie_chart_rounded,
            iconColor: colorScheme.secondary,
            title: 'Per-App Traffic Breakdown',
            description:
                'Trace high-bandwidth consumers, view 2-hour burn rates, and filter by Wi-Fi or Mobile.',
          ),
          const SizedBox(height: 12),
          _buildPillarCard(
            context,
            icon: Icons.sim_card_outlined,
            iconColor: colorScheme.tertiary,
            title: 'Multi-SIM Quota Safety',
            description:
                'Smart billing renewal pacing, daily budget guidance, and automatic unused rollover.',
          ),
          const SizedBox(height: 12),
          _buildPillarCard(
            context,
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.green,
            title: '100% Offline & Private',
            description:
                'Zero analytics, zero tracking, zero ads. Your network statistics never leave your device.',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPillarCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
