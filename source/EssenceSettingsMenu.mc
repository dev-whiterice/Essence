// ============================================================================
// EssenceSettingsMenu.mc
// In-watch settings UI, accessible via long-press on the watch face.
//
// Menu item ID mapping (used in onSelect to identify which item was tapped):
//   1        — BatterySave toggle
//   2        — DarkMode toggle
//   3–10     — Field zone selectors (FieldTop through FieldBottom)
//              offset: fieldLayout index = itemId - 3
//   11       — ShowGraph selector
//   12       — GraphSize toggle
// ============================================================================

import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

// ----------------------------------------------------------------------------
// EssenceSettingsMenu — builds the Menu2 shown to the user
// ----------------------------------------------------------------------------
class EssenceSettingsMenu extends WatchUi.Menu2 {

  public function initialize() {
    Menu2.initialize({ :title => Rez.Strings.Settings });
    buildMenu();
  }

  // Populate all menu items in display order.
  // Toggle items (BatterySave, DarkMode) use ToggleMenuItem.
  // All other items use MenuItem with the current value as the sublabel;
  // tapping cycles to the next option (handled in EssenceSettingsMenuDelegate).
  function buildMenu() {

    // --- Toggles ------------------------------------------------------------

    var value = getApp().getProperty("BatterySave");
    Menu2.addItem(
      new WatchUi.ToggleMenuItem(Rez.Strings.BatterySave, null, 1, value, null)
    );

    value = getApp().getProperty("DarkMode");
    Menu2.addItem(
      new WatchUi.ToggleMenuItem(Rez.Strings.DarkMode, null, 2, value, null)
    );

    // --- Field zone selectors (IDs 3–10, one per fieldLayout entry) ---------
    // The sublabel shows the currently configured data type for that zone.

    value = getApp().getProperty("FieldTop");
    Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.FieldTop, fieldCatalog[value]["labelExt"], 3, {}));

    value = getApp().getProperty("FieldUpperLeft");
    Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.FieldUpperLeft, fieldCatalog[value]["labelExt"], 4, {}));

    value = getApp().getProperty("FieldUpperCenter");
    Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.FieldUpperCenter, fieldCatalog[value]["labelExt"], 5, {}));

    value = getApp().getProperty("FieldUpperRight");
    Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.FieldUpperRight, fieldCatalog[value]["labelExt"], 6, {}));

    value = getApp().getProperty("FieldLowerLeft");
    Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.FieldLowerLeft, fieldCatalog[value]["labelExt"], 7, {}));

    value = getApp().getProperty("FieldLowerCenter");
    Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.FieldLowerCenter, fieldCatalog[value]["labelExt"], 8, {}));

    value = getApp().getProperty("FieldLowerRight");
    Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.FieldLowerRight, fieldCatalog[value]["labelExt"], 9, {}));

    value = getApp().getProperty("FieldBottom");
    Menu2.addItem(new WatchUi.MenuItem(Rez.Strings.FieldBottom, fieldCatalog[value]["labelExt"], 10, {}));

    // --- Graph selectors (IDs 11–12) ----------------------------------------

    value = getApp().getProperty("ShowGraph");
    Menu2.addItem(
      new WatchUi.MenuItem(Rez.Strings.ShowGraph, graphCatalog[value]["labelExt"], 11, {})
    );

    value = getApp().getProperty("GraphSize");
    var graphSizeLabel = (value == 0)
      ? WatchUi.loadResource(Rez.Strings.GraphSizeSmall)
      : WatchUi.loadResource(Rez.Strings.GraphSizeLarge);
    Menu2.addItem(
      new WatchUi.MenuItem(Rez.Strings.GraphSize, graphSizeLabel, 12, {})
    );
  }
}

// ----------------------------------------------------------------------------
// EssenceSettingsMenuDelegate — handles item selection
// ----------------------------------------------------------------------------
class EssenceSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

  public function initialize() {
    Menu2InputDelegate.initialize();
  }

  // Dispatch each tap to the appropriate handler based on item ID.
  // All changes write immediately to persistent storage via setProperty(),
  // then set redrawLayout = true so the next onUpdate() picks them up.
  public function onSelect(menuItem as MenuItem) as Void {
    var itemId = menuItem.getId() as Number;

    if (itemId == 1) {
      // BatterySave toggle — write the new boolean state directly
      if (menuItem instanceof ToggleMenuItem) {
        getApp().setProperty("BatterySave", menuItem.isEnabled());
      }

    } else if (itemId == 2) {
      // DarkMode toggle — write the new boolean state directly
      if (menuItem instanceof ToggleMenuItem) {
        getApp().setProperty("DarkMode", menuItem.isEnabled());
      }

    } else if (itemId <= 10) {
      // Field zone selector (IDs 3–10).
      // Map item ID back to fieldLayout index: index = itemId - 3.
      // Cycle forward through fieldCatalog[], wrapping at the end.
      var fieldIndex = itemId - 3;
      var value      = getApp().getProperty(fieldLayout[fieldIndex]["id"]);

      if (value < fieldCatalog.size() - 1) {
        value = value + 1;
      } else {
        value = 0;
      }

      menuItem.setSubLabel(fieldCatalog[value]["labelExt"]);
      getApp().setProperty(fieldLayout[fieldIndex]["id"], value);

    } else if (itemId == 11) {
      itemId = itemId - 2;  // unused after this point — kept for parity with original
      var value = getApp().getProperty("ShowGraph");

      if (value < graphCatalog.size() - 1) {
        value = value + 1;
      } else {
        value = 0;
      }

      menuItem.setSubLabel(graphCatalog[value]["labelExt"]);
      getApp().setProperty("ShowGraph", value);

    } else if (itemId == 12) {
      itemId = itemId - 2;  // unused after this point — kept for parity with original
      var value = getApp().getProperty("GraphSize");

      if (value == 0) {
        value = 1;
        menuItem.setSubLabel(WatchUi.loadResource(Rez.Strings.GraphSizeLarge));
      } else {
        value = 0;
        menuItem.setSubLabel(WatchUi.loadResource(Rez.Strings.GraphSizeSmall));
      }

      getApp().setProperty("GraphSize", value);
    }

    // Signal the view to rebuild on the next frame
    redrawLayout = true;
  }
}
