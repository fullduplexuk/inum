import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inum/domain/models/chat/message_model.dart';
import 'package:inum/presentation/blocs/messages/messages_cubit.dart';
import 'package:inum/presentation/blocs/messages/messages_state.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockIChatRepository mockChatRepo;
  late StreamController<Map<String, dynamic>> wsController;

  setUp(() {
    mockChatRepo = MockIChatRepository();
    wsController = StreamController<Map<String, dynamic>>.broadcast();
    when(() => mockChatRepo.wsEvents)
        .thenAnswer((_) => wsController.stream);
    when(() => mockChatRepo.currentUserId).thenReturn('user-123');
  });

  tearDown(() {
    wsController.close();
  });

  group('MessagesCubit', () {
    test('initial state is MessagesInitial', () {
      final cubit = MessagesCubit(chatRepository: mockChatRepo);
      expect(cubit.state, isA<MessagesInitial>());
      cubit.close();
    });

    blocTest<MessagesCubit, MessagesState>(
      'loadMessages emits [Loading, Loaded] on success',
      build: () {
        when(() => mockChatRepo.getChannelMessages(any(), any()))
            .thenAnswer((_) async => [
                  TestData.message(id: 'm1'),
                  TestData.message(id: 'm2'),
                ]);
        return MessagesCubit(chatRepository: mockChatRepo);
      },
      act: (cubit) => cubit.loadMessages('ch1'),
      expect: () => [
        isA<MessagesLoading>(),
        isA<MessagesLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as MessagesLoaded;
        expect(state.messages.length, 2);
        expect(state.channelId, 'ch1');
        expect(state.hasMore, false); // less than 60 messages
      },
    );

    blocTest<MessagesCubit, MessagesState>(
      'loadMessages sets hasMore true when 60+ messages returned',
      build: () {
        final messages =
            List.generate(60, (i) => TestData.message(id: 'm$i'));
        when(() => mockChatRepo.getChannelMessages(any(), any()))
            .thenAnswer((_) async => messages);
        return MessagesCubit(chatRepository: mockChatRepo);
      },
      act: (cubit) => cubit.loadMessages('ch1'),
      expect: () => [
        isA<MessagesLoading>(),
        isA<MessagesLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as MessagesLoaded;
        expect(state.hasMore, true);
      },
    );

    blocTest<MessagesCubit, MessagesState>(
      'loadMessages emits Error on failure',
      build: () {
        when(() => mockChatRepo.getChannelMessages(any(), any()))
            .thenThrow(Exception('Network error'));
        return MessagesCubit(chatRepository: mockChatRepo);
      },
      act: (cubit) => cubit.loadMessages('ch1'),
      expect: () => [
        isA<MessagesLoading>(),
        isA<MessagesError>(),
      ],
    );

    blocTest<MessagesCubit, MessagesState>(
      'sendMessage delegates to repository',
      build: () {
        when(() =>
                mockChatRepo.sendMessage(any(), any(), rootId: any(named: 'rootId'), fileIds: any(named: 'fileIds')))
            .thenAnswer((_) async {});
        return MessagesCubit(chatRepository: mockChatRepo);
      },
      act: (cubit) => cubit.sendMessage('ch1', 'Hello'),
      verify: (_) {
        verify(() => mockChatRepo.sendMessage('ch1', 'Hello')).called(1);
      },
    );

    blocTest<MessagesCubit, MessagesState>(
      'updateMessage delegates to repository',
      build: () {
        when(() => mockChatRepo.updateMessage(any(), any()))
            .thenAnswer((_) async {});
        return MessagesCubit(chatRepository: mockChatRepo);
      },
      act: (cubit) => cubit.updateMessage('p1', 'Updated'),
      verify: (_) {
        verify(() => mockChatRepo.updateMessage('p1', 'Updated')).called(1);
      },
    );

    blocTest<MessagesCubit, MessagesState>(
      'deleteMessage delegates to repository',
      build: () {
        when(() => mockChatRepo.deleteMessage(any()))
            .thenAnswer((_) async {});
        return MessagesCubit(chatRepository: mockChatRepo);
      },
      act: (cubit) => cubit.deleteMessage('p1'),
      verify: (_) {
        verify(() => mockChatRepo.deleteMessage('p1')).called(1);
      },
    );

    blocTest<MessagesCubit, MessagesState>(
      'addReaction delegates to repository',
      build: () {
        when(() => mockChatRepo.addReaction(any(), any()))
            .thenAnswer((_) async {});
        return MessagesCubit(chatRepository: mockChatRepo);
      },
      act: (cubit) => cubit.addReaction('p1', 'thumbsup'),
      verify: (_) {
        verify(() => mockChatRepo.addReaction('p1', 'thumbsup')).called(1);
      },
    );

    blocTest<MessagesCubit, MessagesState>(
      'removeReaction delegates to repository',
      build: () {
        when(() => mockChatRepo.removeReaction(any(), any()))
            .thenAnswer((_) async {});
        return MessagesCubit(chatRepository: mockChatRepo);
      },
      act: (cubit) => cubit.removeReaction('p1', 'thumbsup'),
      verify: (_) {
        verify(() => mockChatRepo.removeReaction('p1', 'thumbsup')).called(1);
      },
    );
  });

  group('MessagesState', () {
    test('MessagesLoaded copyWith', () {
      final state = MessagesLoaded(
        messages: [TestData.message()],
        hasMore: true,
        channelId: 'ch1',
      );
      final updated = state.copyWith(hasMore: false);
      expect(updated.hasMore, false);
      expect(updated.messages.length, 1);
      expect(updated.channelId, 'ch1');
    });

    test('MessagesError contains message', () {
      const state = MessagesError('Something went wrong');
      expect(state.message, 'Something went wrong');
    });

    test('states are equatable', () {
      expect(const MessagesInitial(), const MessagesInitial());
      expect(const MessagesLoading(), const MessagesLoading());
    });
  });
}
