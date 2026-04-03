import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/domain/models/chat/channel_model.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_state.dart';

class ChannelListCubit extends Cubit<ChannelListState> {
  final IChatRepository _chatRepository;
  StreamSubscription<List<ChannelModel>>? _channelsSubscription;

  ChannelListCubit({required IChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChannelListLoading());

  void loadChannels() {
    emit(const ChannelListLoading());
    _channelsSubscription?.cancel();
    _channelsSubscription = _chatRepository.channelsStream.listen(
      (channels) {
        emit(ChannelListLoaded(
          channels: channels,
          filteredChannels: channels,
        ));
      },
      onError: (Object error) {
        debugPrint('ChannelList stream error: $error');
        emit(ChannelListError(error.toString()));
      },
    );
  }

  void searchChannels(String query) {
    final currentState = state;
    if (currentState is ChannelListLoaded) {
      if (query.isEmpty) {
        emit(ChannelListLoaded(
          channels: currentState.channels,
          filteredChannels: currentState.channels,
        ));
      } else {
        final filtered = currentState.channels.where((ch) {
          return ch.displayName.toLowerCase().contains(query.toLowerCase());
        }).toList();
        emit(ChannelListLoaded(
          channels: currentState.channels,
          filteredChannels: filtered,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _channelsSubscription?.cancel();
    return super.close();
  }
}
