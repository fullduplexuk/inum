enum RouterEnum {
  initialLocation('/'),
  signInView('/sign-in'),
  dashboardView('/dashboard'),
  chatView('/chat'),
  profileView('/profile'),
  settingsView('/settings'),
  callView('/call'),
  callHistoryView('/call-history'),
  voicemailView('/voicemail'),
  contactsView('/contacts'),
  recordingsView('/recordings'),
  recordingDetailView('/recordings/:id'),
  transcriptView('/transcript/:id'),
  callSummaryView('/call-summary/:id'),
  languageSettingsView('/settings/language'),
  // Phase 7
  dialpadView('/dialpad'),
  smsView('/sms'),
  smsConversationView('/sms/:number'),
  callForwardingView('/settings/call-forwarding'),
  voicemailSettingsView('/settings/voicemail'),
  // Phase 8
  qrLoginView('/auth/qr-login'),
  notificationSettingsView('/settings/notifications'),
  scheduleMeetingView('/meetings/schedule'),
  createChannelView('/channels/create'),
  channelInfoView('/channels/info');

  final String routeName;
  const RouterEnum(this.routeName);
}
