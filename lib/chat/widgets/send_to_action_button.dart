import 'package:flutter/material.dart';

class SendToActionButton extends StatelessWidget {
  final int selectedCount;
  final String label;
  final Future<void> Function()? onPressed;

  const SendToActionButton({
    super.key,
    required this.selectedCount,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed == null ? null : () => onPressed!(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF871DAD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
