/// Named routes used by [NavigationProvider] and [RouteGenerator].
enum AppRoute {
  landing('/landing'),
  login('/login'),
  signup('/signup'),
  home('/home'),
  cart('/cart'),
  trackOrder('/trackorder'),
  subscription('/subscription'),
  readBooks('/read-books'),
  affirmation('/affirmation'),
  game('/game'),
  tasks('/tasks'),
  product('/product');

  const AppRoute(this.path);
  final String path;
}
