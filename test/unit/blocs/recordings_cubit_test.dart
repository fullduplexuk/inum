import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inum/domain/models/call/recording_model.dart';
import 'package:inum/presentation/blocs/recordings/recordings_cubit.dart';
import 'package:inum/presentation/blocs/recordings/recordings_state.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_data.dart';

class FakeRecordingModel extends Fake implements RecordingModel {}

void main() {
  late MockRecordingsRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeRecordingModel());
  });

  setUp(() {
    mockRepo = MockRecordingsRepository();
  });

  group('RecordingsCubit', () {
    test('initial state is RecordingsInitial', () {
      final cubit = RecordingsCubit(repository: mockRepo);
      expect(cubit.state, isA<RecordingsInitial>());
      cubit.close();
    });

    blocTest<RecordingsCubit, RecordingsState>(
      'loadRecordings emits [Loading, Loaded] on success',
      build: () {
        when(() => mockRepo.getRecordings(page: any(named: 'page')))
            .thenAnswer((_) async => [TestData.recording()]);
        return RecordingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadRecordings(),
      expect: () => [
        isA<RecordingsLoading>(),
        isA<RecordingsLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as RecordingsLoaded;
        expect(state.recordings.length, 1);
      },
    );

    blocTest<RecordingsCubit, RecordingsState>(
      'loadRecordings emits Error on failure',
      build: () {
        when(() => mockRepo.getRecordings(page: any(named: 'page')))
            .thenThrow(Exception('DB error'));
        return RecordingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadRecordings(),
      expect: () => [
        isA<RecordingsLoading>(),
        isA<RecordingsError>(),
      ],
    );

    blocTest<RecordingsCubit, RecordingsState>(
      'saveRecording then reloads',
      build: () {
        when(() => mockRepo.saveRecording(any()))
            .thenAnswer((_) async {});
        when(() => mockRepo.getRecordings(page: any(named: 'page')))
            .thenAnswer((_) async => [TestData.recording()]);
        return RecordingsCubit(repository: mockRepo);
      },
      seed: () => RecordingsLoaded(recordings: [TestData.recording()]),
      act: (cubit) => cubit.saveRecording(TestData.recording(id: 'new-rec')),
      expect: () => [
        isA<RecordingsLoading>(),
        isA<RecordingsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepo.saveRecording(any())).called(1);
      },
    );

    blocTest<RecordingsCubit, RecordingsState>(
      'deleteRecording then reloads',
      build: () {
        when(() => mockRepo.deleteRecording(any()))
            .thenAnswer((_) async {});
        when(() => mockRepo.getRecordings(page: any(named: 'page')))
            .thenAnswer((_) async => []);
        return RecordingsCubit(repository: mockRepo);
      },
      seed: () => RecordingsLoaded(recordings: [TestData.recording()]),
      act: (cubit) => cubit.deleteRecording('recording-1'),
      expect: () => [
        isA<RecordingsLoading>(),
        isA<RecordingsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepo.deleteRecording('recording-1')).called(1);
      },
    );

    test('getRecording delegates to repo', () async {
      when(() => mockRepo.getRecording(any()))
          .thenAnswer((_) async => TestData.recording());
      final cubit = RecordingsCubit(repository: mockRepo);
      final result = await cubit.getRecording('recording-1');
      expect(result, isNotNull);
      expect(result!.id, 'recording-1');
      cubit.close();
    });

    test('getRecording returns null on error', () async {
      when(() => mockRepo.getRecording(any()))
          .thenThrow(Exception('Not found'));
      final cubit = RecordingsCubit(repository: mockRepo);
      final result = await cubit.getRecording('nonexistent');
      expect(result, isNull);
      cubit.close();
    });

    test('getRecordingForCall delegates to repo', () async {
      when(() => mockRepo.getRecordingForCall(any()))
          .thenAnswer((_) async => TestData.recording());
      final cubit = RecordingsCubit(repository: mockRepo);
      final result = await cubit.getRecordingForCall('call-1');
      expect(result, isNotNull);
      cubit.close();
    });
  });

  group('RecordingsState', () {
    test('RecordingsLoaded equality', () {
      final a = RecordingsLoaded(recordings: [TestData.recording()]);
      final b = RecordingsLoaded(recordings: [TestData.recording()]);
      expect(a, equals(b));
    });

    test('RecordingsError contains message', () {
      const state = RecordingsError('Error');
      expect(state.message, 'Error');
    });
  });
}
