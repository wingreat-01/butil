import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/billing_provider.dart';

/// Shows [child] while the trial is active or the app is purchased,
/// otherwise shows the paywall.
class AccessGate extends StatelessWidget {
  final Widget child;
  const AccessGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BillingProvider>();
    if (!b.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return b.hasAccess ? child : const PaywallScreen();
  }
}

/// Slim banner shown during the trial. Put it above the main content.
class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BillingProvider>();
    if (b.purchased || !b.trialActive) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final urgent = b.daysLeft <= 7;
    return Material(
      color: urgent ? Colors.orange.shade100 : scheme.primaryContainer.withOpacity(0.5),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaywallScreen(canClose: true)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Free trial: ${b.daysLeft} day${b.daysLeft == 1 ? '' : 's'} left',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Text(
                'Unlock ${b.priceLabel}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaywallScreen extends StatelessWidget {
  /// True when opened from the trial banner (user can go back).
  final bool canClose;
  const PaywallScreen({super.key, this.canClose = false});

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BillingProvider>();
    final scheme = Theme.of(context).colorScheme;

    // Close automatically once purchased.
    if (b.purchased && canClose) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }

    final expired = !b.trialActive && !b.purchased;

    return Scaffold(
      appBar: canClose ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rice_bowl_rounded, size: 64, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    expired ? 'Your 30-day free trial has ended' : 'Unlock Bigasan POS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    expired
                        ? 'Pay once to keep using the app. Your sales and stock data are safe and will be here when you unlock.'
                        : '${b.daysLeft} days left in your free trial. Pay once, use it forever.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Text(b.priceLabel,
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: scheme.primary)),
                          const Text('One-time payment • No subscription',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (kIsWeb)
                    Text(
                      'To unlock, open Bigasan POS on your Android phone from Google Play.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: b.canPurchase && !b.busy ? b.buy : null,
                        child: b.busy
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Text('Unlock for ${b.priceLabel}'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: b.busy ? null : b.restore,
                      child: const Text('Restore purchase'),
                    ),
                    if (!b.canPurchase && b.loaded)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Google Play is not available right now. Check your internet and try again later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                  ],
                  if (b.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(b.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
