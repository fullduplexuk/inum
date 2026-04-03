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
  contactsView('/contacts');

  final String routeName;
  const RouterEnum(this.routeName);
}
