import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/presentation/blocs/contacts/contacts_state.dart';

class ContactsCubit extends Cubit<ContactsState> {
  final MattermostApiClient _apiClient;

  ContactsCubit({required MattermostApiClient apiClient})
      : _apiClient = apiClient,
        super(const ContactsLoading());

  Future<void> loadContacts() async {
    emit(const ContactsLoading());
    try {
      // Get the user's teams first
      final teams = await _apiClient.getMyTeams();
      if (teams.isEmpty) {
        emit(const ContactsLoaded(contacts: [], filteredContacts: []));
        return;
      }

      final teamId = (teams.first as Map<String, dynamic>)['id'] as String;
      final users = <ContactUser>[];
      final seen = <String>{};

      // Get channels to find all DM partners
      final channels = await _apiClient.getMyChannels(teamId);
      for (final ch in channels) {
        final channel = ch as Map<String, dynamic>;
        final channelType = channel['type'] as String? ?? '';
        if (channelType == 'D') {
          // Direct message channel - extract the other user's ID
          final name = channel['name'] as String? ?? '';
          final parts = name.split('__');
          for (final part in parts) {
            if (part != _apiClient.currentUserId && part.isNotEmpty && !seen.contains(part)) {
              seen.add(part);
            }
          }
        }
      }

      // Batch fetch user details
      if (seen.isNotEmpty) {
        final userList = await _apiClient.getUsersByIds(seen.toList());
        for (final u in userList) {
          final userData = u as Map<String, dynamic>;
          users.add(ContactUser.fromJson(userData));
        }
      }

      // Sort alphabetically by display name
      users.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      emit(ContactsLoaded(contacts: users, filteredContacts: users));
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      emit(ContactsError(e.toString()));
    }
  }

  void searchContacts(String query) {
    final currentState = state;
    if (currentState is ContactsLoaded) {
      if (query.isEmpty) {
        emit(currentState.copyWith(
          filteredContacts: currentState.contacts,
          searchQuery: '',
        ));
      } else {
        final lowerQuery = query.toLowerCase();
        final filtered = currentState.contacts.where((c) {
          return c.displayName.toLowerCase().contains(lowerQuery) ||
              c.username.toLowerCase().contains(lowerQuery) ||
              c.email.toLowerCase().contains(lowerQuery);
        }).toList();
        emit(currentState.copyWith(
          filteredContacts: filtered,
          searchQuery: query,
        ));
      }
    }
  }
}
