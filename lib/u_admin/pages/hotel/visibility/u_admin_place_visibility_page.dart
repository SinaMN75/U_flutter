import "package:u/utilities.dart";

/// All hotels and dorms in one table: switch "featured", "verified (visited in person)" and "visible" quickly.
class UAdminPlaceVisibilityPage extends StatefulWidget {
  const UAdminPlaceVisibilityPage({super.key});

  @override
  State<UAdminPlaceVisibilityPage> createState() => _PlaceVisibilityPageState();
}

class _PlaceVisibilityPageState extends State<UAdminPlaceVisibilityPage> {
  final UAdminPlaceVisibilityController c = UAdminPlaceVisibilityController();

  @override
  void initState() {
    c.init();
    super.initState();
  }
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.placesVisibility,
    body: UAdminListView<UAdminPlaceRow>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.list.length,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.hotels),
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.type, U.s.city, U.s.featured, U.s.verifiedOnSite, U.s.active]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  String _city(UAdminPlaceRow i) {
    final UCountryCityInfo city = UCountries.infoByCode(i.cityCode);
    return city.city?.nameFa ?? city.province?.nameFa ?? "";
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) => Switch(value: value, onChanged: onChanged);

  Widget _itemDesktop(UAdminPlaceRow i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.isHotel ? U.s.hotel : U.s.dorm),
      UAdminTable.cell(_city(i)),
      _switch(i.featured, (bool v) => c.setTag(i, i.featuredTag, on: v)).expanded(),
      _switch(i.verified, (bool v) => c.setTag(i, i.verifiedTag, on: v)).expanded(),
      _switch(i.visible, (bool v) => c.setVisible(i, visible: v)).expanded(),
    ],
  );

  Widget _itemResponsive(UAdminPlaceRow i, int index) => UColumn(
    children: <Widget>[
      UAdminTable.mobileCard(
        icon: i.isHotel ? Icons.apartment_rounded : Icons.bedroom_parent_rounded,
        title: i.title,
        fields: <UAdminField>[
          UAdminField(U.s.type, i.isHotel ? U.s.hotel : U.s.dorm),
          UAdminField(U.s.city, _city(i)),
        ],
      ),
      Wrap(
        spacing: 8,
        children: <Widget>[
          FilterChip(label: Text(U.s.featured), selected: i.featured, onSelected: (bool v) => c.setTag(i, i.featuredTag, on: v)),
          FilterChip(label: Text(U.s.verifiedOnSite), selected: i.verified, onSelected: (bool v) => c.setTag(i, i.verifiedTag, on: v)),
          FilterChip(label: Text(U.s.active), selected: i.visible, onSelected: (bool v) => c.setVisible(i, visible: v)),
        ],
      ),
    ],
  );
}
