import 'package:flutter/material.dart';

enum TipScenario { normal, localError, empty, missing }

/// This API accepts no form values and makes no account decisions or requests.
class LocalTipSource {
  const LocalTipSource();
  static const category = 'password_help';
  static const tips = <String, List<String>>{
    category: [
      'Choose a long, unique passphrase for each account.',
      'A password manager can help you keep different passwords for different accounts.',
      'Never share your password in a signup tip request.',
    ],
  };

  String select({TipScenario scenario = TipScenario.normal}) {
    if (scenario == TipScenario.localError) {
      throw const TipFailure(
        'Simulated local error. Tap Retry to load the bundled tip.',
      );
    }
    final List<String>? candidates = switch (scenario) {
      TipScenario.empty => const <String>[],
      TipScenario.missing => null,
      _ => tips[category],
    };
    if (candidates == null || candidates.isEmpty) {
      throw const TipFailure(
        'No local tip is available. Tap Retry to restore the bundled tip.',
      );
    }
    // Deterministic selection: always the first tip in the fixed category.
    final tip = candidates.first.trim();
    if (tip.isEmpty || tip.length > 240) {
      throw const TipFailure(
        'Local tip data is invalid. Tap Retry to restore the bundled tip.',
      );
    }
    return tip;
  }
}

class TipFailure implements Exception {
  const TipFailure(this.message);
  final String message;
}

class SignupTipCard extends StatefulWidget {
  const SignupTipCard({super.key});
  @override
  State<SignupTipCard> createState() => _SignupTipCardState();
}

class _SignupTipCardState extends State<SignupTipCard> {
  TipScenario _scenario = TipScenario.normal;
  bool _loading = false;
  String? _tip;
  String? _error;

  Future<void> _load({bool retry = false}) async {
    if (_loading) return;
    final scenario = retry ? TipScenario.normal : _scenario;
    setState(() {
      if (retry) _scenario = TipScenario.normal;
      _loading = true;
      _tip = null;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    try {
      final tip = const LocalTipSource().select(scenario: scenario);
      setState(() {
        _tip = tip;
        _loading = false;
      });
    } on TipFailure catch (error) {
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Signup coach • local demo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Preset demo tip—not live AI.'),
          const SizedBox(height: 8),
          const Text(
            'Category: password_help. This feature never reads your form and cannot approve signup.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TipScenario>(
            key: ValueKey(_scenario),
            initialValue: _scenario,
            decoration: const InputDecoration(labelText: 'Local test scenario'),
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: TipScenario.normal,
                child: Text('Bundled tip'),
              ),
              DropdownMenuItem(
                value: TipScenario.localError,
                child: Text('Simulated error'),
              ),
              DropdownMenuItem(
                value: TipScenario.empty,
                child: Text('Empty tip list'),
              ),
              DropdownMenuItem(
                value: TipScenario.missing,
                child: Text('Missing category data'),
              ),
            ],
            onChanged: _loading
                ? null
                : (value) => setState(() {
                    _scenario = value!;
                    _tip = null;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('get-tip'),
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Get a signup tip'),
          ),
          if (_loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const Text(
              'Loading local tip…',
              semanticsLabel: 'Loading local tip',
            ),
          ],
          if (_tip != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(_tip!, key: const Key('tip-result')),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(_error!, key: const Key('tip-error')),
            ),
            TextButton.icon(
              key: const Key('retry'),
              onPressed: () => _load(retry: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );
}
