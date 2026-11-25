import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/recommendation_link_service.dart';
import '../localization/recommendations_strings.dart';

class RecommendationLinkActions extends ConsumerStatefulWidget {
  const RecommendationLinkActions({super.key, required this.query});

  final String query;

  @override
  ConsumerState<RecommendationLinkActions> createState() =>
      _RecommendationLinkActionsState();
}

class _RecommendationLinkActionsState
    extends ConsumerState<RecommendationLinkActions> {
  bool _opening = false;

  Future<void> _open({required bool directions}) async {
    setState(() => _opening = true);
    var opened = false;
    try {
      final service = ref.read(recommendationLinkServiceProvider);
      opened = directions
          ? await service.directions(widget.query)
          : await service.viewPlace(widget.query);
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            RecommendationsStrings(Localizations.localeOf(context)).linkError,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = RecommendationsStrings(Localizations.localeOf(context));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton.icon(
            onPressed: _opening ? null : () => _open(directions: false),
            icon: const Icon(Icons.open_in_new),
            label: Text(strings.viewPlace),
          ),
          TextButton.icon(
            onPressed: _opening ? null : () => _open(directions: true),
            icon: const Icon(Icons.directions_outlined),
            label: Text(strings.directions),
          ),
        ],
      ),
    );
  }
}
