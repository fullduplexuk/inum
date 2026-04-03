import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inum/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:inum/presentation/blocs/contacts/contacts_state.dart';
import '../../helpers/mock_api_client.dart';

void main() {
  late MockMattermostApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockMattermostApiClient();
  });

  group('ContactsCubit', () {
    test('initial state is ContactsLoading', () {
      final cubit = ContactsCubit(apiClient: mockApiClient);
      expect(cubit.state, isA<ContactsLoading>());
      cubit.close();
    });

    blocTest<ContactsCubit, ContactsState>(
      'loadContacts emits Loaded with empty list when no teams',
      build: () {
        when(() => mockApiClient.getMyTeams())
            .thenAnswer((_) async => []);
        return ContactsCubit(apiClient: mockApiClient);
      },
      act: (cubit) => cubit.loadContacts(),
      expect: () => [
        isA<ContactsLoading>(),
        isA<ContactsLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ContactsLoaded;
        expect(state.contacts, isEmpty);
      },
    );

    blocTest<ContactsCubit, ContactsState>(
      'loadContacts fetches DM partners',
      build: () {
        when(() => mockApiClient.getMyTeams())
            .thenAnswer((_) async => [
                  {'id': 'team1', 'name': 'test'},
                ]);
        when(() => mockApiClient.currentUserId).thenReturn('user-123');
        when(() => mockApiClient.getMyChannels('team1'))
            .thenAnswer((_) async => [
                  {
                    'id': 'dm1',
                    'type': 'D',
                    'name': 'user-123__user-456',
                    'display_name': '',
                  },
                ]);
        when(() => mockApiClient.getUsersByIds(['user-456']))
            .thenAnswer((_) async => [
                  {
                    'id': 'user-456',
                    'username': 'otheruser',
                    'first_name': 'Other',
                    'last_name': 'User',
                    'email': 'other@example.com',
                  },
                ]);
        return ContactsCubit(apiClient: mockApiClient);
      },
      act: (cubit) => cubit.loadContacts(),
      expect: () => [
        isA<ContactsLoading>(),
        isA<ContactsLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ContactsLoaded;
        expect(state.contacts.length, 1);
        expect(state.contacts[0].username, 'otheruser');
        expect(state.contacts[0].displayName, 'Other User');
      },
    );

    blocTest<ContactsCubit, ContactsState>(
      'loadContacts emits Error on failure',
      build: () {
        when(() => mockApiClient.getMyTeams())
            .thenThrow(Exception('Network error'));
        return ContactsCubit(apiClient: mockApiClient);
      },
      act: (cubit) => cubit.loadContacts(),
      expect: () => [
        isA<ContactsLoading>(),
        isA<ContactsError>(),
      ],
    );

    blocTest<ContactsCubit, ContactsState>(
      'searchContacts filters by displayName',
      build: () => ContactsCubit(apiClient: mockApiClient),
      seed: () => const ContactsLoaded(
        contacts: [
          ContactUser(id: '1', username: 'alice', firstName: 'Alice'),
          ContactUser(id: '2', username: 'bob', firstName: 'Bob'),
          ContactUser(id: '3', username: 'charlie', firstName: 'Charlie'),
        ],
        filteredContacts: [
          ContactUser(id: '1', username: 'alice', firstName: 'Alice'),
          ContactUser(id: '2', username: 'bob', firstName: 'Bob'),
          ContactUser(id: '3', username: 'charlie', firstName: 'Charlie'),
        ],
      ),
      act: (cubit) => cubit.searchContacts('ali'),
      expect: () => [isA<ContactsLoaded>()],
      verify: (cubit) {
        final state = cubit.state as ContactsLoaded;
        expect(state.filteredContacts.length, 1);
        expect(state.filteredContacts[0].firstName, 'Alice');
        expect(state.searchQuery, 'ali');
      },
    );

    blocTest<ContactsCubit, ContactsState>(
      'searchContacts with empty query restores all',
      build: () => ContactsCubit(apiClient: mockApiClient),
      seed: () => const ContactsLoaded(
        contacts: [
          ContactUser(id: '1', username: 'alice'),
          ContactUser(id: '2', username: 'bob'),
        ],
        filteredContacts: [
          ContactUser(id: '1', username: 'alice'),
        ],
        searchQuery: 'ali',
      ),
      act: (cubit) => cubit.searchContacts(''),
      expect: () => [isA<ContactsLoaded>()],
      verify: (cubit) {
        final state = cubit.state as ContactsLoaded;
        expect(state.filteredContacts.length, 2);
        expect(state.searchQuery, '');
      },
    );

    blocTest<ContactsCubit, ContactsState>(
      'searchContacts matches by email',
      build: () => ContactsCubit(apiClient: mockApiClient),
      seed: () => const ContactsLoaded(
        contacts: [
          ContactUser(
              id: '1',
              username: 'alice',
              email: 'alice@example.com'),
          ContactUser(id: '2', username: 'bob', email: 'bob@test.com'),
        ],
        filteredContacts: [
          ContactUser(
              id: '1',
              username: 'alice',
              email: 'alice@example.com'),
          ContactUser(id: '2', username: 'bob', email: 'bob@test.com'),
        ],
      ),
      act: (cubit) => cubit.searchContacts('example.com'),
      expect: () => [isA<ContactsLoaded>()],
      verify: (cubit) {
        final state = cubit.state as ContactsLoaded;
        expect(state.filteredContacts.length, 1);
      },
    );
  });

  group('ContactsState', () {
    test('ContactUser.displayName prefers firstName lastName', () {
      const user = ContactUser(
          id: '1', username: 'jdoe', firstName: 'John', lastName: 'Doe');
      expect(user.displayName, 'John Doe');
    });

    test('ContactUser.displayName falls back to username', () {
      const user = ContactUser(id: '1', username: 'jdoe');
      expect(user.displayName, 'jdoe');
    });

    test('ContactsLoaded copyWith', () {
      const state = ContactsLoaded(
        contacts: [ContactUser(id: '1', username: 'a')],
        filteredContacts: [ContactUser(id: '1', username: 'a')],
      );
      final updated = state.copyWith(searchQuery: 'test');
      expect(updated.searchQuery, 'test');
      expect(updated.contacts.length, 1);
    });

    test('ContactsError contains message', () {
      const state = ContactsError('Error');
      expect(state.message, 'Error');
    });
  });
}
