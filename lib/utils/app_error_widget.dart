import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A friendly, branded global error recovery screen that replaces Flutter's
/// default red/grey screen of death when an unexpected UI build or layout
/// exception occurs.
class GlobalAppErrorWidget extends StatefulWidget {
  final FlutterErrorDetails details;

  const GlobalAppErrorWidget({
    super.key,
    required this.details,
  });

  @override
  State<GlobalAppErrorWidget> createState() => _GlobalAppErrorWidgetState();
}

class _GlobalAppErrorWidgetState extends State<GlobalAppErrorWidget> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Something went wrong',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'An unexpected interface error occurred. Your conversations, '
                      'models, and local data remain safe on your device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Technical Details Accordion
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _showDetails = !_showDetails;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _showDetails
                                      ? Icons.info_rounded
                                      : Icons.info_outline_rounded,
                                  size: 18,
                                  color: const Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Technical details',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _showDetails
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showDetails) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              widget.details.exceptionAsString(),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                color: Color(0xFFF87171),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF818CF8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: widget.details.exceptionAsString(),
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text(
                                  'Copy error',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Primary Recovery Action
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Attempt to pop or reload root route
                          final nav = Navigator.maybeOf(context);
                          if (nav != null && nav.canPop()) {
                            nav.pop();
                          } else {
                            // If root cannot pop, navigate to initial route
                            Navigator.of(context, rootNavigator: true)
                                .pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'Reload App',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
