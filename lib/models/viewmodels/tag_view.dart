import 'package:flutter/material.dart';
import 'package:toot_ui/helper.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';
import 'toot_view.dart';

class TagView extends StatefulWidget {
  final String tag; // without the "#", e.g., "ActivityPub"

  const TagView({super.key, required this.tag});

  @override
  State<TagView> createState() => _TagViewState();
}

class _TagViewState extends State<TagView> {
  final Helper _helper = Helper.get();
  List<MastodonStatus> _toots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTagTimeline();
  }

  Future<void> _loadTagTimeline() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rawToots =
          await _helper.getHashtagTimeline(widget.tag, limit: 40);
      final toots = rawToots
          .whereType<Map<String, dynamic>>()
          .map((data) => MastodonStatus.fromJson(data))
          .toList();

      setState(() {
        _toots = toots;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load hashtag timeline: $e');
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(title: Text('#${widget.tag}')),
      backgroundColor: backgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Failed to load posts for #${widget.tag}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadTagTimeline,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _toots.isEmpty
                  ? Center(
                      child: Text('No posts for #${widget.tag}',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTagTimeline,
                      child: ListView.separated(
                        itemCount: _toots.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TootView(
                              _toots[index],
                              darkMode: isDark,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
