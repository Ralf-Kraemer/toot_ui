import 'package:flutter/material.dart';
import 'package:toot_ui/toot_ui.dart';
import 'profile_custom.dart';

class ProfileView extends StatefulWidget {
  final String? userId; // if null, show logged-in user's profile

  const ProfileView({super.key, this.userId});

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
      final data = widget.userId != null
          ? await _helper.getProfile(widget.userId!)
          : await _helper.getProfile('verify_credentials');

      // Convert Mastodon / ActivityPub custom fields to ProfileCustomNode
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
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // ===== Header section =====
          Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: _profileData!['header'] != null &&
                        _profileData!['header'].isNotEmpty
                    ? Image.network(
                        _profileData!['header'],
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey[300]),
              ),
              Positioned(
                left: 16,
                bottom: 0,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _profileData!['avatar'] != null &&
                          _profileData!['avatar'].isNotEmpty
                      ? NetworkImage(_profileData!['avatar'])
                      : null,
                  child: _profileData!['avatar'] == null ||
                          _profileData!['avatar'].isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
              Positioned(
                left: 16 + 80 + 16,
                bottom: 16,
                child: Text(
                  _profileData!['display_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
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
              ),
            ],
          ),

          // ===== Summary =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_profileData!['note'] ?? ''),
          ),

          // ===== Tabs =====
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

          // ===== Tab views =====
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
