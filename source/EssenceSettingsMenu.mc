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

    value = getApp().getProperty("FieldTop");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldTop,
        dataField[value]["labelExt"],
        2,
        {}
      )
    );
    value = getApp().getProperty("FieldUpperLeft");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldUpperLeft,
        dataField[value]["labelExt"],
        3,
        {}
      )
    );
    value = getApp().getProperty("FieldUpperCenter");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldUpperCenter,
        dataField[value]["labelExt"],
        4,
        {}
      )
    );
    value = getApp().getProperty("FieldUpperRight");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldUpperRight,
        dataField[value]["labelExt"],
        5,
        {}
      )
    );
    value = getApp().getProperty("FieldLowerLeft");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldLowerLeft,
        dataField[value]["labelExt"],
        6,
        {}
      )
    );
    value = getApp().getProperty("FieldLowerCenter");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldLowerCenter,
        dataField[value]["labelExt"],
        7,
        {}
      )
    );
    value = getApp().getProperty("FieldLowerRight");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldLowerRight,
        dataField[value]["labelExt"],
        8,
        {}
      )
    );
    value = getApp().getProperty("FieldBottom");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.FieldBottom,
        dataField[value]["labelExt"],
        9,
        {}
      )
    );

    value = getApp().getProperty("ShowGraph");
    Menu2.addItem(
      new WatchUi.MenuItem(
        Rez.Strings.ShowGraph,
        dataGraph[value]["labelExt"],
        10,
        {}
      )
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
    } else if (itemId <= 9) {
      itemId = itemId - 2;
      if (itemId == 7) {
        itemId = 6;
      }
      var value = getApp().getProperty(fieldLayout[itemId]["id"]);

      if (value < dataField.size() - 1) {
        value = value + 1;
      } else {
        value = 0;
      }

      menuItem.setSubLabel(dataField[value]["labelExt"]);
      getApp().setProperty(fieldLayout[itemId]["id"], value);
    } else {
      itemId = itemId - 2;
      var value = getApp().getProperty("ShowGraph");

      if (value < dataGraph.size() - 1) {
        value = value + 1;
      } else {
        value = 0;
      }

      menuItem.setSubLabel(dataGraph[value]["labelExt"]);
      getApp().setProperty("ShowGraph", value);
    }
    redrawLayout = true;
  }
}
