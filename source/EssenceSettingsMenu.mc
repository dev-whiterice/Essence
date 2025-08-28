//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

//! The app settings menu
class EssenceSettingsMenu extends WatchUi.Menu2 {
  //! Constructor
  public function initialize() {
    Menu2.initialize({ :title => Rez.Strings.Settings });
    buildMenu();
  }

  function buildMenu() {
    var value = getApp().getProperty("BatterySave");
    Menu2.addItem(
      new WatchUi.ToggleMenuItem(Rez.Strings.BatterySave, null, 1, value, null)
    );

    value = getApp().getProperty("DarkMode");
    Menu2.addItem(
      new WatchUi.ToggleMenuItem(Rez.Strings.DarkMode, null, 2, value, null)
    );

    value = getApp().getProperty("FieldTop");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldTop,
        fieldCatalog[value]["labelExt"],
        3,
        {}
      )
    );
    value = getApp().getProperty("FieldUpperLeft");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldUpperLeft,
        fieldCatalog[value]["labelExt"],
        4,
        {}
      )
    );
    value = getApp().getProperty("FieldUpperCenter");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldUpperCenter,
        fieldCatalog[value]["labelExt"],
        5,
        {}
      )
    );
    value = getApp().getProperty("FieldUpperRight");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldUpperRight,
        fieldCatalog[value]["labelExt"],
        6,
        {}
      )
    );
    value = getApp().getProperty("FieldLowerLeft");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldLowerLeft,
        fieldCatalog[value]["labelExt"],
        7,
        {}
      )
    );
    value = getApp().getProperty("FieldLowerCenter");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldLowerCenter,
        fieldCatalog[value]["labelExt"],
        8,
        {}
      )
    );
    value = getApp().getProperty("FieldLowerRight");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldLowerRight,
        fieldCatalog[value]["labelExt"],
        9,
        {}
      )
    );
    value = getApp().getProperty("FieldBottom");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldBottom,
        fieldCatalog[value]["labelExt"],
        10,
        {}
      )
    );

    value = getApp().getProperty("ShowGraph");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.ShowGraph,
        graphCatalog[value]["labelExt"],
        11,
        {}
      )
    );

    value = getApp().getProperty("GraphSize");
    var graphSize = "";
    if (value == 0) {
      graphSize = WatchUi.loadResource(Rez.Strings.GraphSizeSmall);
    } else {
      graphSize = WatchUi.loadResource(Rez.Strings.GraphSizeLarge);
    }

    Menu2.addItem(
      new WatchUi.MenuItem(Rez.Strings.GraphSize, graphSize, 12, {})
    );
  }
}

//! Input handler for the app settings menu
class EssenceSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
  //! Constructor
  public function initialize() {
    Menu2InputDelegate.initialize();
  }

  //! Handle a menu item being selected
  //! @param menuItem The menu item selected
  public function onSelect(menuItem as MenuItem) as Void {
    var itemId = menuItem.getId();
    itemId = itemId as Number;

    if (itemId == 1) {
      if (menuItem instanceof ToggleMenuItem) {
        getApp().setProperty("BatterySave", menuItem.isEnabled());
      }
    } else if (itemId == 2) {
      if (menuItem instanceof ToggleMenuItem) {
        getApp().setProperty("DarkMode", menuItem.isEnabled());
      }
    } else if (itemId <= 10) {
      itemId = itemId - 3;

      var value = getApp().getProperty(fieldLayout[itemId]["id"]);

      if (value < fieldCatalog.size() - 1) {
        value = value + 1;
      } else {
        value = 0;
      }

      menuItem.setSubLabel(fieldCatalog[value]["labelExt"]);
      getApp().setProperty(fieldLayout[itemId]["id"], value);
    } else if (itemId == 11) {
      itemId = itemId - 2;
      var value = getApp().getProperty("ShowGraph");

      if (value < graphCatalog.size() - 1) {
        value = value + 1;
      } else {
        value = 0;
      }

      menuItem.setSubLabel(graphCatalog[value]["labelExt"]);
      getApp().setProperty("ShowGraph", value);
    } else if (itemId == 12) {
      itemId = itemId - 2;
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
    redrawLayout = true;
  }
}
