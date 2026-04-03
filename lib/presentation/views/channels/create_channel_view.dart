import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:inum/presentation/blocs/contacts/contacts_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class CreateChannelView extends StatefulWidget {
  const CreateChannelView({super.key});
  @override
  State<CreateChannelView> createState() => _CreateChannelViewState();
}

class _CreateChannelViewState extends State<CreateChannelView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _headerController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isPrivate = false;
  bool _isCreating = false;
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';

  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    context.read<ContactsCubit>().loadContacts(); }

  @override
  void dispose() { _tabController.dispose(); _nameController.dispose(); _descController.dispose();
    _headerController.dispose(); _searchController.dispose(); super.dispose(); }

  Future<void> _createDm() async {
    if (_selectedUserIds.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a user'))); return; }
    setState(() => _isCreating = true);
    try {
      final api = getIt<MattermostApiClient>(); final uid = api.currentUserId ?? '';
      final ch = await api.createDirectChannel([uid, _selectedUserIds.first]);
      final cid = ch['id'] as String? ?? '';
      if (cid.isNotEmpty && mounted) { Navigator.of(context).pop();
        context.push('${RouterEnum.chatView.routeName}?channelId=$cid&channelName=Direct%20Message'); }
    } catch (e) { if (mounted) { setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); } }
  }

  Future<void> _createGroupDm() async {
    if (_selectedUserIds.length < 2) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 2 users'))); return; }
    setState(() => _isCreating = true);
    try {
      final api = getIt<MattermostApiClient>(); final uid = api.currentUserId ?? '';
      final ch = await api.createGroupChannel([uid, ..._selectedUserIds]);
      final cid = ch['id'] as String? ?? '';
      if (cid.isNotEmpty && mounted) { Navigator.of(context).pop();
        context.push('${RouterEnum.chatView.routeName}?channelId=$cid&channelName=Group%20Chat'); }
    } catch (e) { if (mounted) { setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); } }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Conversation'), centerTitle: false,
        bottom: TabBar(controller: _tabController, labelColor: inumPrimary, unselectedLabelColor: customGreyColor500,
          indicatorColor: inumPrimary, tabs: const [Tab(text: 'Channel'), Tab(text: 'DM'), Tab(text: 'Group')])),
      body: TabBarView(controller: _tabController, children: [
        _buildChannelTab(), _buildUserList(1, 'Start Conversation', _createDm),
        _buildUserList(7, 'Create Group (${_selectedUserIds.length} selected)', _createGroupDm)]),
    );
  }

  Widget _buildChannelTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _OptCard(icon: Icons.public, label: 'Public', sub: 'Anyone can join', sel: !_isPrivate,
          onTap: () => setState(() => _isPrivate = false))),
        const SizedBox(width: 12),
        Expanded(child: _OptCard(icon: Icons.lock_outline, label: 'Private', sub: 'Invite only', sel: _isPrivate,
          onTap: () => setState(() => _isPrivate = true))),
      ]),
      const SizedBox(height: 20),
      TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Channel Name', hintText: 'e.g., project-alpha',
        prefixIcon: Icon(_isPrivate ? Icons.lock_outline : Icons.tag), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 12),
      TextField(controller: _descController, decoration: InputDecoration(labelText: 'Description (optional)',
        prefixIcon: const Icon(Icons.description_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
      const SizedBox(height: 12),
      TextField(controller: _headerController, decoration: InputDecoration(labelText: 'Header (optional)',
        prefixIcon: const Icon(Icons.short_text), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: _isCreating ? null : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Channel creation via API pending'))); },
        icon: const Icon(Icons.add), label: Text(_isCreating ? 'Creating...' : 'Create Channel'),
        style: ElevatedButton.styleFrom(backgroundColor: inumPrimary, foregroundColor: white,
          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]));
  }

  Widget _buildUserList(int maxSel, String actionLabel, VoidCallback onAction) {
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: TextField(
        controller: _searchController, onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(hintText: 'Search contacts...', prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)))),
      if (_selectedUserIds.isNotEmpty) Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(scrollDirection: Axis.horizontal, children: _selectedUserIds.map((id) => Padding(
          padding: const EdgeInsets.only(right: 6), child: Chip(
            label: Text(id.length > 8 ? id.substring(0, 8) : id, style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => _selectedUserIds.remove(id)), visualDensity: VisualDensity.compact))).toList())),
      Expanded(child: BlocBuilder<ContactsCubit, ContactsState>(builder: (context, state) {
        if (state is ContactsLoading) return const Center(child: CircularProgressIndicator());
        if (state is ContactsLoaded) {
          final contacts = state.contacts.where((c) { if (_searchQuery.isEmpty) return true;
            return c.displayName.toLowerCase().contains(_searchQuery) || c.username.toLowerCase().contains(_searchQuery); }).toList();
          return ListView.builder(itemCount: contacts.length, itemBuilder: (context, index) {
            final c = contacts[index]; final isSel = _selectedUserIds.contains(c.id);
            return ListTile(
              leading: CircleAvatar(backgroundColor: inumPrimary.withAlpha(30),
                child: Text(c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                  style: const TextStyle(color: inumPrimary, fontWeight: FontWeight.w600))),
              title: Text(c.displayName), subtitle: Text('@${c.username}', style: const TextStyle(fontSize: 13)),
              trailing: isSel ? const Icon(Icons.check_circle, color: inumSecondary) : const Icon(Icons.radio_button_unchecked, color: customGreyColor400),
              onTap: () => setState(() { if (isSel) _selectedUserIds.remove(c.id); else if (_selectedUserIds.length < maxSel) _selectedUserIds.add(c.id); }));
          });
        }
        return const Center(child: Text('Load contacts to select members', style: TextStyle(color: customGreyColor500)));
      })),
      Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isCreating || _selectedUserIds.isEmpty ? null : onAction, child: Text(actionLabel),
        style: ElevatedButton.styleFrom(backgroundColor: inumPrimary, foregroundColor: white,
          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))))),
    ]);
  }
}

class _OptCard extends StatelessWidget {
  final IconData icon; final String label; final String sub; final bool sel; final VoidCallback onTap;
  const _OptCard({required this.icon, required this.label, required this.sub, required this.sel, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: sel ? inumPrimary.withAlpha(15) : null, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sel ? inumPrimary : customGreyColor300, width: sel ? 2 : 1)),
      child: Column(children: [
        Icon(icon, color: sel ? inumPrimary : customGreyColor600, size: 28), const SizedBox(height: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: sel ? inumPrimary : customGreyColor700)),
        Text(sub, style: const TextStyle(fontSize: 11, color: customGreyColor500))])));
  }
}
