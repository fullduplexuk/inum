enum RouterEnum {
  initialLocation('/'),
  signInView('/sign-in'),
  dashboardView('/dashboard'),
  chatView('/chat'),
  profileView('/profile'),
  settingsView('/settings'),
  callView('/call');

  final String routeName;
  const RouterEnum(this.routeName);
}
