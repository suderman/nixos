"""Minimal NetworkManager fixture on a private D-Bus, never the system bus."""

import asyncio
import json
import sys
from pathlib import Path

from dbus_next import Message, MessageType, Variant
from dbus_next.aio import MessageBus

address, logfile = sys.argv[1:]
assert address.startswith("unix:path=/tmp/"), "Private test bus required"
NM = "org.freedesktop.NetworkManager"
ROOT = "/org/freedesktop/NetworkManager"
WIFI = ROOT + "/Devices/1"
WIRED = ROOT + "/Devices/2"
SETTING = ROOT + "/Settings/1"
ACTIVE = ROOT + "/ActiveConnection/1"
DEV = NM + ".Device"
WIRELESS = DEV + ".Wireless"
CONNECTION = NM + ".Connection.Active"
present = [WIFI]
denied = False


def properties(**values):
    return {
        name: Variant(signature, value) for name, (signature, value) in values.items()
    }


objects = {
    ROOT: {
        NM: properties(
            Version=("s", "1.56.0"),
            State=("u", 70),
            NetworkingEnabled=("b", True),
            WirelessEnabled=("b", True),
            WirelessHardwareEnabled=("b", True),
            WwanEnabled=("b", False),
            WwanHardwareEnabled=("b", False),
            Connectivity=("u", 4),
            ConnectivityCheckAvailable=("b", True),
            ConnectivityCheckEnabled=("b", False),
            Devices=("ao", present.copy()),
            AllDevices=("ao", present.copy()),
            ActiveConnections=("ao", [ACTIVE]),
            PrimaryConnection=("o", ACTIVE),
            ActivatingConnection=("o", "/"),
            Startup=("b", False),
            Metered=("u", 1),
        )
    },
    WIFI: {
        DEV: properties(
            DeviceType=("u", 2),
            Interface=("s", "sim-wifi"),
            HwAddress=("s", "00:11:22:33:44:55"),
            Managed=("b", True),
            State=("u", 100),
            Autoconnect=("b", True),
            AvailableConnections=("ao", [SETTING]),
            ActiveConnection=("o", ACTIVE),
            InterfaceFlags=("u", 3),
            IpInterface=("s", "sim-wifi"),
        ),
        WIRELESS: properties(
            LastScan=("x", -1),
            WirelessCapabilities=("u", 255),
            ActiveAccessPoint=("o", "/"),
            Mode=("u", 2),
            AccessPoints=("ao", []),
            HwAddress=("s", "00:11:22:33:44:55"),
        ),
    },
    WIRED: {
        DEV: properties(
            DeviceType=("u", 1),
            Interface=("s", "sim-ethernet"),
            HwAddress=("s", "00:11:22:33:44:66"),
            Managed=("b", True),
            State=("u", 100),
            Autoconnect=("b", True),
            AvailableConnections=("ao", []),
            ActiveConnection=("o", "/"),
            InterfaceFlags=("u", 3),
            IpInterface=("s", "sim-ethernet"),
        ),
        DEV + ".Wired": properties(Speed=("u", 1000), Carrier=("b", True)),
    },
    SETTING: {
        NM + ".Settings.Connection": properties(Unsaved=("b", False), Flags=("u", 0))
    },
    ROOT + "/Settings": {
        NM + ".Settings": properties(
            Connections=("ao", [SETTING]), Hostname=("s", "sim"), CanModify=("b", True)
        )
    },
    ACTIVE: {
        CONNECTION: properties(
            Connection=("o", SETTING),
            State=("u", 2),
            Id=("s", "Sim Wi-Fi"),
            Uuid=("s", "11111111-1111-1111-1111-111111111111"),
            Type=("s", "802-11-wireless"),
            Devices=("ao", [WIFI]),
            Default=("b", True),
        )
    },
}
settings = {
    "connection": properties(
        id=("s", "Sim Wi-Fi"),
        uuid=("s", "11111111-1111-1111-1111-111111111111"),
        type=("s", "802-11-wireless"),
    ),
    "802-11-wireless": properties(
        ssid=("ay", b"Sim Wi-Fi"), mode=("s", "infrastructure")
    ),
}


async def main():
    bus = await MessageBus(bus_address=address).connect()

    def emit(path, interface, changes):
        objects[path][interface].update(changes)
        bus.send(
            Message.new_signal(
                path,
                "org.freedesktop.DBus.Properties",
                "PropertiesChanged",
                "sa{sv}as",
                [interface, changes, []],
            )
        )

    def set_state(device, state):
        active = ACTIVE if device == WIFI and state == 100 else "/"
        emit(
            device,
            DEV,
            {"State": Variant("u", state), "ActiveConnection": Variant("o", active)},
        )

    def radio(value):
        emit(ROOT, NM, {"WirelessEnabled": Variant("b", value)})
        if not value:
            set_state(WIFI, 30)

    def handler(message):
        global denied, present
        if message.message_type != MessageType.METHOD_CALL:
            return None
        with Path(logfile).open("a") as log:
            log.write(
                json.dumps(
                    {
                        "path": message.path,
                        "interface": message.interface,
                        "method": message.member,
                        "property": message.body[1]
                        if message.interface == "org.freedesktop.DBus.Properties"
                        and message.member == "Set"
                        else None,
                    }
                )
                + "\n"
            )
        if message.interface == "org.freedesktop.DBus.Introspectable":
            xml = "<node>"
            for interface, props in objects.get(message.path, {}).items():
                xml += '<interface name="' + interface + '">'
                for name, value in props.items():
                    xml += f'<property name="{name}" type="{value.signature}" access="readwrite"/>'
                if interface == NM:
                    xml += '<method name="GetAllDevices"><arg direction="out" type="ao"/></method><method name="GetDevices"><arg direction="out" type="ao"/></method>'
                    xml += '<signal name="DeviceAdded"><arg type="o"/></signal><signal name="DeviceRemoved"><arg type="o"/></signal>'
                if interface == WIRELESS:
                    xml += '<method name="GetAllAccessPoints"><arg direction="out" type="ao"/></method>'
                if interface == NM + ".Settings.Connection":
                    xml += '<method name="GetSettings"><arg direction="out" type="a{sa{sv}}"/></method>'
                xml += "</interface>"
            xml += '<interface name="org.freedesktop.DBus.ObjectManager"><method name="GetManagedObjects"><arg direction="out" type="a{oa{sa{sv}}}"/></method></interface></node>'
            return Message.new_method_return(message, "s", [xml])
        if message.member == "GetManagedObjects":
            managed = {
                path: props
                for path, props in objects.items()
                if path not in [WIFI, WIRED] or path in present
            }
            return Message.new_method_return(message, "a{oa{sa{sv}}}", [managed])
        if message.interface == "org.freedesktop.DBus.Properties":
            interface = message.body[0]
            if message.member == "GetAll":
                return Message.new_method_return(
                    message, "a{sv}", [objects[message.path][interface]]
                )
            if message.member == "Get":
                return Message.new_method_return(
                    message, "v", [objects[message.path][interface][message.body[1]]]
                )
            if message.member == "Set":
                if denied:
                    return Message.new_error(
                        message, NM + ".PermissionDenied", "Sim radio change denied"
                    )
                if interface == NM and message.body[1] == "WirelessEnabled":
                    radio(message.body[2].value)
                    return Message.new_method_return(message)
        if message.member in ["GetAllDevices", "GetDevices"]:
            return Message.new_method_return(message, "ao", [present])
        if message.member == "GetAllAccessPoints":
            return Message.new_method_return(message, "ao", [[]])
        if message.member == "GetSettings":
            return Message.new_method_return(message, "a{sa{sv}}", [settings])
        if message.member == "GetPermissions":
            return Message.new_method_return(
                message, "a{ss}", [{NM + ".enable-disable-wifi": "yes"}]
            )
        if message.interface == "org.example.SettingsTest":
            if message.member == "Radio":
                radio(message.body[0])
            elif message.member == "Hardware":
                emit(
                    ROOT, NM, {"WirelessHardwareEnabled": Variant("b", message.body[0])}
                )
            elif message.member == "Denied":
                denied = message.body[0]
            elif message.member == "State":
                set_state(WIFI if message.body[0] == "wifi" else WIRED, message.body[1])
            elif message.member == "Devices":
                next_devices = {
                    "wifi": [WIFI],
                    "wired": [WIRED],
                    "both": [WIFI, WIRED],
                    "none": [],
                }[message.body[0]]
                for path in present:
                    if path not in next_devices:
                        bus.send(
                            Message.new_signal(ROOT, NM, "DeviceRemoved", "o", [path])
                        )
                for path in next_devices:
                    if path not in present:
                        bus.send(
                            Message.new_signal(ROOT, NM, "DeviceAdded", "o", [path])
                        )
                present = next_devices
                emit(
                    ROOT,
                    NM,
                    {
                        "Devices": Variant("ao", present),
                        "AllDevices": Variant("ao", present),
                    },
                )
            elif message.member == "Service":
                asyncio.create_task(
                    bus.request_name(NM) if message.body[0] else bus.release_name(NM)
                )
            return Message.new_method_return(message)
        return Message.new_error(
            message,
            "org.freedesktop.DBus.Error.UnknownMethod",
            "Unsupported test method",
        )

    bus.add_message_handler(handler)
    await bus.request_name(NM)
    await bus.request_name("org.example.SettingsTest")
    print("NetworkManager fixture ready", flush=True)
    await asyncio.Future()


asyncio.run(main())
