import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inum/domain/models/call/call_record.dart';
import 'package:inum/presentation/blocs/call_history/call_history_cubit.dart';
import 'package:inum/presentation/blocs/call_history/call_history_state.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockCallHistoryRepository mockRepo;

  setUp(() {
    mockRepo = MockCallHistoryRepository();
  });

  group('CallHistoryCubit', () {
    test('initial state is CallHistoryLoading', () {
      final cubit = CallHistoryCubit(repository: mockRepo);
      expect(cubit.state, isA<CallHistoryLoading>());
      cubit.close();
    });

    blocTest<CallHistoryCubit, CallHistoryState>(
      'loadHistory with all filter',
      build: () {
        when(() => mockRepo.getCallHistory())
            .thenAnswer((_) async => [TestData.callRecord()]);
        when(() => mockRepo.getMissedCallCount())
            .thenAnswer((_) async => 2);
        return CallHistoryCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<CallHistoryLoading>(),
        isA<CallHistoryLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as CallHistoryLoaded;
        expect(state.records.length, 1);
        expect(state.filter, CallHistoryFilter.all);
        expect(state.missedCount, 2);
      },
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'loadHistory with missed filter',
      build: () {
        when(() => mockRepo.getMissedCalls()).thenAnswer((_) async =>
            [TestData.callRecord(status: CallRecordStatus.missed)]);
        when(() => mockRepo.getMissedCallCount())
            .thenAnswer((_) async => 1);
        return CallHistoryCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadHistory(filter: CallHistoryFilter.missed),
      expect: () => [
        isA<CallHistoryLoading>(),
        isA<CallHistoryLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as CallHistoryLoaded;
        expect(state.filter, CallHistoryFilter.missed);
      },
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'loadHistory with incoming filter',
      build: () {
        when(() => mockRepo.getIncomingCalls()).thenAnswer((_) async =>
            [TestData.callRecord(direction: CallDirection.incoming)]);
        when(() => mockRepo.getMissedCallCount())
            .thenAnswer((_) async => 0);
        return CallHistoryCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadHistory(filter: CallHistoryFilter.incoming),
      expect: () => [
        isA<CallHistoryLoading>(),
        isA<CallHistoryLoaded>(),
      ],
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'loadHistory with outgoing filter',
      build: () {
        when(() => mockRepo.getOutgoingCalls())
            .thenAnswer((_) async => [TestData.callRecord()]);
        when(() => mockRepo.getMissedCallCount())
            .thenAnswer((_) async => 0);
        return CallHistoryCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadHistory(filter: CallHistoryFilter.outgoing),
      expect: () => [
        isA<CallHistoryLoading>(),
        isA<CallHistoryLoaded>(),
      ],
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'loadHistory emits Error on failure',
      build: () {
        when(() => mockRepo.getCallHistory())
            .thenThrow(Exception('DB error'));
        when(() => mockRepo.getMissedCallCount())
            .thenAnswer((_) async => 0);
        return CallHistoryCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<CallHistoryLoading>(),
        isA<CallHistoryError>(),
      ],
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'deleteRecord reloads history',
      build: () {
        when(() => mockRepo.deleteCallRecord(any()))
            .thenAnswer((_) async {});
        when(() => mockRepo.getCallHistory())
            .thenAnswer((_) async => []);
        when(() => mockRepo.getMissedCallCount())
            .thenAnswer((_) async => 0);
        return CallHistoryCubit(repository: mockRepo);
      },
      seed: () => CallHistoryLoaded(
        records: [TestData.callRecord()],
        missedCount: 0,
      ),
      act: (cubit) => cubit.deleteRecord('rec-1'),
      expect: () => [
        isA<CallHistoryLoading>(),
        isA<CallHistoryLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepo.deleteCallRecord('rec-1')).called(1);
      },
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'clearMissedBadge sets missedCount to 0',
      build: () {
        when(() => mockRepo.clearMissedCallBadge())
            .thenAnswer((_) async {});
        return CallHistoryCubit(repository: mockRepo);
      },
      seed: () => const CallHistoryLoaded(
        records: [],
        missedCount: 5,
      ),
      act: (cubit) => cubit.clearMissedBadge(),
      expect: () => [
        isA<CallHistoryLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as CallHistoryLoaded;
        expect(state.missedCount, 0);
      },
    );

    test('missedCount returns 0 when not loaded', () {
      final cubit = CallHistoryCubit(repository: mockRepo);
      expect(cubit.missedCount, 0);
      cubit.close();
    });

    test('missedCount returns value from loaded state', () {
      final cubit = CallHistoryCubit(repository: mockRepo);
      cubit.emit(const CallHistoryLoaded(records: [], missedCount: 3));
      expect(cubit.missedCount, 3);
      cubit.close();
    });
  });

  group('CallHistoryState', () {
    test('CallHistoryLoaded copyWith', () {
      final state = CallHistoryLoaded(
        records: [TestData.callRecord()],
        filter: CallHistoryFilter.all,
        missedCount: 2,
      );
      final updated = state.copyWith(missedCount: 0);
      expect(updated.missedCount, 0);
      expect(updated.records.length, 1);
    });

    test('CallHistoryFilter values', () {
      expect(CallHistoryFilter.values.length, 4);
    });
  });
}
