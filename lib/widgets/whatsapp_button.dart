import 'package:flutter/material.dart';
import '../core/services/whatsapp_service.dart';

class WhatsAppButton extends StatelessWidget {
  final String personName;
  final String phoneNumber;
  final double amount;
  final DateTime dueDate;
  final String? note;
  final VoidCallback? onSent;
  final bool isCompact;
  final String? customLabel;

  const WhatsAppButton({
    super.key,
    required this.personName,
    required this.phoneNumber,
    required this.amount,
    required this.dueDate,
    this.note,
    this.onSent,
    this.isCompact = true,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final message = WhatsAppService.instance.generateReminderMessage(
          personName: personName,
          amount: amount,
          dueDate: dueDate,
          customNote: note,
        );

        final success = await WhatsAppService.instance.sendReminder(
          phoneNumber: phoneNumber,
          message: message,
          personName: personName,
          amount: amount,
          dueDate: dueDate,
        );

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('WhatsApp reminder prepared for $personName'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            onSent?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open WhatsApp. Please check phone number.'),
                backgroundColor: Color(0xFFF43F5E),
              ),
            );
          }
        }
      },
      icon: Icon(Icons.send_rounded, size: isCompact ? 13 : 16),
      label: Text(customLabel ?? (isCompact ? 'WhatsApp' : 'Remind on WhatsApp')),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
        foregroundColor: Colors.white,
        elevation: 0,
        padding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(fontSize: isCompact ? 11 : 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
