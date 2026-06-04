import 'package:flutter/material.dart';

class ConnectionStatusBar extends StatelessWidget {
  final bool isBluetoothConnected;
  final bool isInternetConnected;

  const ConnectionStatusBar({
    super.key,
    required this.isBluetoothConnected,
    required this.isInternetConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusChip(
            context,
            'HC-05 Scanner',
            Icons.bluetooth,
            isBluetoothConnected,
          ),
          Container(
            width: 1,
            height: 24,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _buildStatusChip(
            context,
            'Cloud Sync',
            Icons.cloud,
            isInternetConnected,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, IconData icon, bool isConnected) {
    final color = isConnected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
