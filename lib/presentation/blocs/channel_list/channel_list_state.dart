import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/chat/channel_model.dart';

abstract class ChannelListState extends Equatable {
  const ChannelListState();

  @override
  List<Object?> get props => [];
}

class ChannelListLoading extends ChannelListState {
  const ChannelListLoading();
}

class ChannelListLoaded extends ChannelListState {
  final List<ChannelModel> channels;
  final List<ChannelModel> filteredChannels;

  const ChannelListLoaded({
    required this.channels,
    required this.filteredChannels,
  });

  @override
  List<Object?> get props => [channels, filteredChannels];
}

class ChannelListError extends ChannelListState {
  final String message;
  const ChannelListError(this.message);

  @override
  List<Object?> get props => [message];
}
