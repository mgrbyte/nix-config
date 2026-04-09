// GNOME Shell extension: focus-window@mgrbyte
// Exposes a D-Bus interface so external callers (e.g. Emacs) can focus
// windows by WM class name without requiring org.gnome.Shell.Eval.
//
// Caller example:
//   gdbus call --session \
//     --dest org.gnome.Shell \
//     --object-path /org/mgrbyte/FocusWindow \
//     --method org.mgrbyte.FocusWindow.FocusWindowByClass \
//     "Alacritty"

import Gio from 'gi://Gio';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const IFACE_XML = `
<node>
  <interface name="org.mgrbyte.FocusWindow">
    <method name="FocusWindowByClass">
      <arg type="s" direction="in" name="className"/>
    </method>
    <method name="GetWindowClasses">
      <arg type="s" direction="out" name="classes"/>
    </method>
  </interface>
</node>`;

export default class FocusWindowExtension {
  constructor() {
    this._dbusImpl = null;
  }

  enable() {
    const ifaceInfo = Gio.DBusNodeInfo.new_for_xml(IFACE_XML).interfaces[0];
    this._dbusImpl = Gio.DBusExportedObject.wrapJSObject(ifaceInfo, this);
    this._dbusImpl.export(Gio.DBus.session, '/org/mgrbyte/FocusWindow');
  }

  disable() {
    if (this._dbusImpl) {
      this._dbusImpl.unexport();
      this._dbusImpl = null;
    }
  }

  FocusWindowByClass(className) {
    const win = global.get_window_actors()
      .map(a => a.meta_window)
      .find(w =>
        w.get_wm_class() === className ||
        w.get_wm_class_instance() === className.toLowerCase()
      );
    if (win)
      Main.activateWindow(win);
  }

  GetWindowClasses() {
    return global.get_window_actors()
      .map(a => a.meta_window)
      .map(w => `${w.get_wm_class()}|${w.get_wm_class_instance()}|${w.get_title()}`)
      .join('\n');
  }
}
