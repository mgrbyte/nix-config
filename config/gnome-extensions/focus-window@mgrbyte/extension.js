// GNOME Shell extension: focus-window@mgrbyte
// Exposes a D-Bus interface so external callers (e.g. Emacs, dev-tools script)
// can focus and tile windows without requiring org.gnome.Shell.Eval.
//
// FocusWindowByClass example:
//   gdbus call --session \
//     --dest org.gnome.Shell \
//     --object-path /org/mgrbyte/FocusWindow \
//     --method org.mgrbyte.FocusWindow.FocusWindowByClass \
//     "Alacritty"
//
// TileDevTools example:
//   gdbus call --session \
//     --dest org.gnome.Shell \
//     --object-path /org/mgrbyte/FocusWindow \
//     --method org.mgrbyte.FocusWindow.TileDevTools

import Gio from 'gi://Gio'
import Meta from 'gi://Meta'
import * as Main from 'resource:///org/gnome/shell/ui/main.js'

const IFACE_XML = `
<node>
  <interface name="org.mgrbyte.FocusWindow">
    <method name="FocusWindowByClass">
      <arg type="s" direction="in" name="className"/>
    </method>
    <method name="TileDevTools"/>
    <method name="GetWindowClasses">
      <arg type="s" direction="out" name="classes"/>
    </method>
  </interface>
</node>`

export default class FocusWindowExtension {
  constructor() {
    this._dbusImpl = null
  }

  enable() {
    const ifaceInfo = Gio.DBusNodeInfo.new_for_xml(IFACE_XML).interfaces[0]
    this._dbusImpl = Gio.DBusExportedObject.wrapJSObject(ifaceInfo, this)
    this._dbusImpl.export(Gio.DBus.session, '/org/mgrbyte/FocusWindow')
  }

  disable() {
    if (this._dbusImpl) {
      this._dbusImpl.unexport()
      this._dbusImpl = null
    }
  }

  FocusWindowByClass(className) {
    const win = global.get_window_actors()
      .map(a => a.meta_window)
      .find(w =>
        w.get_wm_class() === className ||
        w.get_wm_class_instance() === className.toLowerCase()
      )
    if (win) {
      Main.activateWindow(win)
    }
  }

  TileDevTools() {
    // Find largest monitor by pixel area (mirrors Hammerspoon largestScreen())
    const nMonitors = global.display.get_n_monitors()
    let bestMonitor = 0
    let bestArea = 0
    for (let i = 0; i < nMonitors; i++) {
      const geom = global.display.get_monitor_geometry(i)
      if (geom.width * geom.height > bestArea) {
        bestArea = geom.width * geom.height
        bestMonitor = i
      }
    }
    const work = global.workspace_manager
      .get_active_workspace()
      .get_work_area_for_monitor(bestMonitor)
    const halfW = Math.floor(work.width / 2)
    // Add extra height so character-grid-snapping windows (Emacs, Alacritty)
    // round up to fill the work area rather than leaving a gap at the bottom.
    // Mutter constrains the actual frame to the work area boundary.
    const fullH = work.height + 50
    for (const actor of global.get_window_actors()) {
      const win = actor.meta_window
      if (win.get_window_type() !== Meta.WindowType.NORMAL) continue
      const cls = win.get_wm_class() ?? ''
      if (/alacritty/i.test(cls)) {
        win.unmaximize(Meta.MaximizeFlags.BOTH)
        win.move_resize_frame(false, work.x, work.y, halfW, fullH)
      } else if (/emacs/i.test(cls)) {
        win.unmaximize(Meta.MaximizeFlags.BOTH)
        win.move_resize_frame(false, work.x + halfW, work.y, work.width - halfW, fullH)
      }
    }
  }

  GetWindowClasses() {
    return global.get_window_actors()
      .map(a => a.meta_window)
      .map(w => `${w.get_wm_class()}|${w.get_wm_class_instance()}|${w.get_title()}`)
      .join("\n")
  }
}
