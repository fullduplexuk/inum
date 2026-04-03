import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inum/domain/models/call/forwarding_rule.dart';
import 'package:inum/presentation/design_system/colors.dart';

class CallForwardingView extends StatefulWidget {
  const CallForwardingView({super.key});

  @override
  State<CallForwardingView> createState() => _CallForwardingViewState();
}

class _CallForwardingViewState extends State<CallForwardingView> {
  static const _storageKey = 'call_forwarding_rules';
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;

  late List<ForwardingRule> _rules;

  @override
  void initState() {
    super.initState();
    _rules = ForwardingCondition.values
        .map((c) => ForwardingRule(condition: c))
        .toList();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final json = await _storage.read(key: _storageKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _rules = list
            .map((e) => ForwardingRule.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Use defaults
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveRules() async {
    final json = jsonEncode(_rules.map((r) => r.toMap()).toList());
    await _storage.write(key: _storageKey, value: json);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Forwarding rules saved')),
      );
    }
  }

  void _updateRule(int index, ForwardingRule updated) {
    setState(() {
      _rules[index] = updated;
    });
  }

  static const _delayOptions = [10, 15, 20, 25, 30];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Forwarding'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saveRules,
            child: const Text(
              'Save',
              style: TextStyle(
                color: inumSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _rules.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final rule = _rules[index];
                return _ForwardingRuleTile(
                  rule: rule,
                  delayOptions: _delayOptions,
                  onChanged: (updated) => _updateRule(index, updated),
                );
              },
            ),
    );
  }
}

class _ForwardingRuleTile extends StatelessWidget {
  final ForwardingRule rule;
  final List<int> delayOptions;
  final ValueChanged<ForwardingRule> onChanged;

  const _ForwardingRuleTile({
    required this.rule,
    required this.delayOptions,
    required this.onChanged,
  });

  IconData get _conditionIcon => switch (rule.condition) {
        ForwardingCondition.always => Icons.phone_forwarded,
        ForwardingCondition.busy => Icons.phone_in_talk,
        ForwardingCondition.noAnswer => Icons.phone_missed,
        ForwardingCondition.offline => Icons.phone_disabled,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Icon(_conditionIcon, color: inumPrimary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rule.conditionLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: rule.enabled,
                onChanged: (val) => onChanged(rule.copyWith(enabled: val)),
                activeColor: inumSecondary,
              ),
            ],
          ),

          if (rule.enabled) ...[
            const SizedBox(height: 12),
            // Destination input
            TextField(
              decoration: InputDecoration(
                labelText: 'Forward to',
                hintText: 'Phone number or username',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              controller: TextEditingController(text: rule.destination),
              onChanged: (val) =>
                  onChanged(rule.copyWith(destination: val)),
            ),

            // Delay selector (only for noAnswer)
            if (rule.condition == ForwardingCondition.noAnswer) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 18, color: customGreyColor600),
                  const SizedBox(width: 8),
                  const Text(
                    'Forward after',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: rule.delaySeconds,
                    underline: const SizedBox.shrink(),
                    items: delayOptions
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d seconds'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        onChanged(rule.copyWith(delaySeconds: val));
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
