#!/usr/bin/env python3
import sys
import json
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

AGENT_INTERFACE = "org.bluez.Agent1"
AGENT_PATH = "/org/quickshell/bt_agent"
BUS_NAME = "org.bluez"

class BluezAgent(dbus.service.Object):
    def __init__(self, bus, path):
        super().__init__(bus, path)
        self.bus = bus
        self.pending_cb = None

    def get_device_info(self, device_path):
        name = ""
        alias = ""
        address = ""
        try:
            dev_obj = self.bus.get_object(BUS_NAME, device_path)
            props = dbus.Interface(dev_obj, "org.freedesktop.DBus.Properties")
            try:
                alias = str(props.Get("org.bluez.Device1", "Alias"))
            except Exception:
                pass
            try:
                name = str(props.Get("org.bluez.Device1", "Name"))
            except Exception:
                pass
            try:
                address = str(props.Get("org.bluez.Device1", "Address"))
            except Exception:
                pass
        except Exception:
            pass

        if not address:
            address = device_path.split("/")[-1].replace("dev_", "").replace("_", ":")
        display_name = alias or name or address
        return display_name, address

    @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
    def Release(self):
        self.emit_json({"type": "released"})

    @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        return "0000"

    @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        name, mac = self.get_device_info(device)
        self.emit_json({
            "type": "display_pin",
            "device": name,
            "mac": mac,
            "pincode": str(pincode)
        })

    @dbus.service.method(AGENT_INTERFACE, in_signature="ou", out_signature="", async_callbacks=("ok", "err"))
    def RequestConfirmation(self, device, passkey, ok, err):
        name, mac = self.get_device_info(device)
        self.pending_cb = (ok, err, device, mac)
        self.emit_json({
            "type": "request_confirmation",
            "device": name,
            "mac": mac,
            "passkey": f"{passkey:06d}"
        })

    @dbus.service.method(AGENT_INTERFACE, in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        name, mac = self.get_device_info(device)
        self.emit_json({
            "type": "display_passkey",
            "device": name,
            "mac": mac,
            "passkey": f"{passkey:06d}",
            "entered": int(entered)
        })

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
    def Cancel(self):
        if self.pending_cb:
            self.pending_cb = None
        self.emit_json({"type": "cancel"})

    def handle_user_response(self, action):
        if not self.pending_cb:
            return
        ok, err, device, mac = self.pending_cb
        self.pending_cb = None

        if action == "confirm":
            try:
                ok()
            except Exception as e:
                self.emit_json({"type": "error", "message": f"Confirm callback failed: {e}"})
                return

            self.emit_json({"type": "confirmed", "mac": mac})
            try:
                dev_obj = self.bus.get_object(BUS_NAME, device)
                props = dbus.Interface(dev_obj, "org.freedesktop.DBus.Properties")
                props.Set("org.bluez.Device1", "Trusted", dbus.Boolean(True))
            except Exception:
                pass
        else:
            try:
                err(dbus.exceptions.DBusException("org.bluez.Error.Rejected"))
                self.emit_json({"type": "rejected", "mac": mac})
            except Exception:
                pass

    def emit_json(self, data):
        sys.stdout.write(json.dumps(data) + "\n")
        sys.stdout.flush()

def on_stdin_read(channel, condition, agent):
    line = sys.stdin.readline()
    if not line:
        return False
    action = line.strip().lower()
    agent.handle_user_response(action)
    return True

def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    try:
        bus = dbus.SystemBus()
    except Exception as e:
        sys.stdout.write(json.dumps({"type": "error", "message": f"Cannot connect to SystemBus: {e}"}) + "\n")
        sys.stdout.flush()
        return

    try:
        agent = BluezAgent(bus, AGENT_PATH)
        manager_obj = bus.get_object(BUS_NAME, "/org/bluez")
        manager = dbus.Interface(manager_obj, "org.bluez.AgentManager1")
        try:
            manager.UnregisterAgent(AGENT_PATH)
        except Exception:
            pass
        manager.RegisterAgent(AGENT_PATH, "KeyboardDisplay")
        manager.RequestDefaultAgent(AGENT_PATH)
        agent.emit_json({"type": "ready"})
    except Exception as e:
        sys.stdout.write(json.dumps({"type": "error", "message": f"Failed to register agent: {e}"}) + "\n")
        sys.stdout.flush()
        return

    GLib.io_add_watch(0, GLib.IO_IN, on_stdin_read, agent)
    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        pass
    finally:
        try:
            manager.UnregisterAgent(AGENT_PATH)
        except Exception:
            pass

if __name__ == "__main__":
    main()

