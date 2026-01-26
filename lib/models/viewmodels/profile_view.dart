import 'package:flutter/material.dart';
import 'package:toot_ui/src/parsed_html.dart';
import 'package:toot_ui/toot_ui.dart';
import 'profile_custom.dart';

class ProfileView extends StatefulWidget {
  final String? url; // if null, show logged-in user's profile
  final String? username;
  final String? userId;

  const ProfileView({super.key, this.url, this.username, this.userId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  final Helper _helper = Helper.get();

  Map<String, dynamic>? _profileData;
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  List<ProfileCustomNode> _customFields = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      Map<String, dynamic> data;

      if (widget.userId != null) {
        data = await _helper.getProfile(widget.userId!);
      } else if (widget.username != null && widget.url != null) {
        final _url = Uri.parse(widget.url!);
        final preload =
            await _helper.getUserByUsername(_url.host, widget.username!);
        data = await _helper.getProfile(preload!.id);
      } else {
        data = await _helper.getProfile('verify_credentials');
      }

      final rawFields = List<Map<String, dynamic>>.from(data['custom_fields'] ?? []);
      final nodes = rawFields.take(4).map((f) {
        return ProfileCustomNode.fromField({
          'name': f['name']?.toString() ?? '',
          'value': f['value']?.toString() ?? '',
        });
      }).toList();

      setState(() {
        _profileData = data;
        _customFields = nodes;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profileData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = _profileData?['display_name'] ?? '';
    final username = _profileData?['username'] ?? '';
    final url = _profileData?['url'] ?? '';
    final avatar = _profileData?['avatar'] ?? '';
    final header = _profileData?['header'] ?? '';
    final statuses = _profileData?['statuses_count']?.toString() ?? '0';
    final followers = _profileData?['followers_count']?.toString() ?? '0';
    final following = _profileData?['following_count']?.toString() ?? '0';

    String hostPart = '';
    try {
      hostPart = Uri.parse(url).host;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('@$username'),
      ),
      body: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: header.isNotEmpty
                    ? Image.network(header, fit: BoxFit.cover)
                    : Container(color: Colors.grey[300]),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
              Positioned(
                left: 16 + 80 + 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    ),
                    Text(
                      '@$username${hostPart.isNotEmpty ? '@$hostPart' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStat(statuses, 'Toots'),
                        const SizedBox(width: 16),
                        _buildStat(followers, 'Followers'),
                        const SizedBox(width: 16),
                        _buildStat(following, 'Following'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ParsedHtml(
              html: _profileData?['note'] ?? '',
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Timeline'),
              Tab(text: 'Gallery'),
              Tab(text: 'Profile'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const Center(child: Text("Timeline placeholder")),
                const Center(child: Text("Gallery placeholder")),
                SingleChildScrollView(
                  child: ProfileCustom(customFields: _customFields),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white70, fontSize: 14),
        children: [
          TextSpan(
            text: count,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(text: label),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

