import '../icons/paisa_icons.dart';

class TabDef {
  const TabDef(this.label, this.icon, this.path, this.screenTitle);
  final String label;
  final String icon;
  final String path;

  /// The mockup titles Activity "Transactions" and More "Settings".
  final String screenTitle;
}

const kTabs = [
  TabDef('Home', PaisaIcons.home, '/home', 'Home'),
  TabDef('Activity', PaisaIcons.list, '/activity', 'Transactions'),
  TabDef('Accounts', PaisaIcons.wallet, '/accounts', 'Accounts'),
  TabDef('Plans', PaisaIcons.target, '/plans', 'Plans'),
  TabDef('More', PaisaIcons.gear, '/more', 'Settings'),
];

/// Index of the Activity tab, which carries the inbox badge.
const kActivityTab = 1;
