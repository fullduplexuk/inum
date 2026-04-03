import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inum/domain/models/chat/channel_model.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_cubit.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_state.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockIChatRepository mockChatRepo;
  late StreamController<List<ChannelModel>> channelsController;

  setUp(() {
    mockChatRepo = MockIChatRepository();
    channelsController = StreamController<List<ChannelModel>>.broadcast();
    when(() => mockChatRepo.channelsStream)
        .thenAnswer((_) => channelsController.stream);
  });

  tearDown(() {
    channelsController.close();
  });

  group('ChannelListCubit', () {
    test('initial state is ChannelListLoading', () {
      final cubit = ChannelListCubit(chatRepository: mockChatRepo);
      expect(cubit.state, isA<ChannelListLoading>());
      cubit.close();
    });

    blocTest<ChannelListCubit, ChannelListState>(
      'loadChannels emits Loading then Loaded when channels arrive',
      build: () => ChannelListCubit(chatRepository: mockChatRepo),
      act: (cubit) {
        cubit.loadChannels();
        final channels = [
          TestData.channel(id: 'ch1', displayName: 'General'),
          TestData.channel(id: 'ch2', displayName: 'Random'),
        ];
        channelsController.add(channels);
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<ChannelListLoading>(),
        isA<ChannelListLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ChannelListLoaded;
        expect(state.channels.length, 2);
        expect(state.filteredChannels.length, 2);
      },
    );

    blocTest<ChannelListCubit, ChannelListState>(
      'searchChannels filters by display name',
      build: () => ChannelListCubit(chatRepository: mockChatRepo),
      seed: () => ChannelListLoaded(
        channels: [
          TestData.channel(id: 'ch1', displayName: 'General'),
          TestData.channel(id: 'ch2', displayName: 'Random'),
          TestData.channel(id: 'ch3', displayName: 'Development'),
        ],
        filteredChannels: [
          TestData.channel(id: 'ch1', displayName: 'General'),
          TestData.channel(id: 'ch2', displayName: 'Random'),
          TestData.channel(id: 'ch3', displayName: 'Development'),
        ],
      ),
      act: (cubit) => cubit.searchChannels('gen'),
      expect: () => [
        isA<ChannelListLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ChannelListLoaded;
        expect(state.filteredChannels.length, 1);
        expect(state.filteredChannels[0].displayName, 'General');
        expect(state.channels.length, 3); // original list unchanged
      },
    );

    blocTest<ChannelListCubit, ChannelListState>(
      'searchChannels with empty query restores full list',
      build: () => ChannelListCubit(chatRepository: mockChatRepo),
      seed: () => ChannelListLoaded(
        channels: [
          TestData.channel(id: 'ch1', displayName: 'General'),
          TestData.channel(id: 'ch2', displayName: 'Random'),
        ],
        filteredChannels: [
          TestData.channel(id: 'ch1', displayName: 'General'),
        ],
      ),
      act: (cubit) => cubit.searchChannels(''),
      expect: () => [isA<ChannelListLoaded>()],
      verify: (cubit) {
        final state = cubit.state as ChannelListLoaded;
        expect(state.filteredChannels.length, 2);
      },
    );

    blocTest<ChannelListCubit, ChannelListState>(
      'searchChannels is case insensitive',
      build: () => ChannelListCubit(chatRepository: mockChatRepo),
      seed: () => ChannelListLoaded(
        channels: [
          TestData.channel(id: 'ch1', displayName: 'General'),
          TestData.channel(id: 'ch2', displayName: 'Random'),
        ],
        filteredChannels: [
          TestData.channel(id: 'ch1', displayName: 'General'),
          TestData.channel(id: 'ch2', displayName: 'Random'),
        ],
      ),
      act: (cubit) => cubit.searchChannels('GENERAL'),
      expect: () => [isA<ChannelListLoaded>()],
      verify: (cubit) {
        final state = cubit.state as ChannelListLoaded;
        expect(state.filteredChannels.length, 1);
      },
    );

    blocTest<ChannelListCubit, ChannelListState>(
      'searchChannels returns empty when no match',
      build: () => ChannelListCubit(chatRepository: mockChatRepo),
      seed: () => ChannelListLoaded(
        channels: [TestData.channel(id: 'ch1', displayName: 'General')],
        filteredChannels: [
          TestData.channel(id: 'ch1', displayName: 'General')
        ],
      ),
      act: (cubit) => cubit.searchChannels('zzzzz'),
      expect: () => [isA<ChannelListLoaded>()],
      verify: (cubit) {
        final state = cubit.state as ChannelListLoaded;
        expect(state.filteredChannels, isEmpty);
      },
    );

    test('searchChannels does nothing when state is not Loaded', () {
      final cubit = ChannelListCubit(chatRepository: mockChatRepo);
      // State is Loading, search should not crash
      cubit.searchChannels('test');
      expect(cubit.state, isA<ChannelListLoading>());
      cubit.close();
    });
  });

  group('ChannelListState', () {
    test('ChannelListLoaded equality', () {
      final channels = [TestData.channel()];
      final a =
          ChannelListLoaded(channels: channels, filteredChannels: channels);
      final b =
          ChannelListLoaded(channels: channels, filteredChannels: channels);
      expect(a, equals(b));
    });

    test('ChannelListError equality', () {
      const a = ChannelListError('error');
      const b = ChannelListError('error');
      expect(a, equals(b));
    });
  });
}
