"""Minimal BlueZ fixture. Run only on a private D-Bus inside disposable Sim."""

import asyncio
import json
import sys
from pathlib import Path

from dbus_next import Message, MessageType, Variant
from dbus_next.aio import MessageBus

address, logfile = sys.argv[1:]
assert address.startswith("unix:path=/tmp/"), "Private test bus required"
ADAPTER = "/org/bluez/hci0"
DEVICE = ADAPTER + "/dev_00_11_22_33_44_55"
UNPAIRED = ADAPTER + "/dev_00_11_22_33_44_66"


def props(**values):
    return {
        key: Variant(
            "b"
            if isinstance(value, bool)
            else "u"
            if isinstance(value, int)
            else "o"
            if key == "Adapter"
            else "s",
            value,
        )
        for key, value in values.items()
    }


objects = {
    ADAPTER: {
        "org.bluez.Adapter1": props(
            Alias="Sim adapter",
            Powered=True,
            PowerState="on",
            Discoverable=False,
            DiscoverableTimeout=0,
            Discovering=False,
            Pairable=True,
            PairableTimeout=0,
        )
    },
    DEVICE: {
        "org.bluez.Device1": props(
            Address="00:11:22:33:44:55",
            Name="Sim headphones",
            Alias="Sim headphones",
            Connected=False,
            Paired=True,
            Bonded=True,
            Trusted=True,
            Blocked=False,
            WakeAllowed=False,
            Icon="audio-headphones",
            Adapter=ADAPTER,
        )
    },
    UNPAIRED: {
        "org.bluez.Device1": props(
            Address="00:11:22:33:44:66",
            Name="Unpaired device",
            Alias="Unpaired device",
            Connected=False,
            Paired=False,
            Bonded=False,
            Trusted=False,
            Blocked=False,
            WakeAllowed=False,
            Icon="input-keyboard",
            Adapter=ADAPTER,
        )
    },
}
fail_next = False


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

    async def connection(message):
        global fail_next
        failed = fail_next
        fail_next = False
        await asyncio.sleep(0.7)
        if failed:
            bus.send(
                Message.new_error(
                    message, "org.bluez.Error.Failed", "Sim connection rejected"
                )
            )
        else:
            emit(
                message.path,
                "org.bluez.Device1",
                {"Connected": Variant("b", message.member == "Connect")},
            )
            bus.send(Message.new_method_return(message))

    def handler(message):
        global fail_next
        if message.message_type != MessageType.METHOD_CALL:
            return None
        with Path(logfile).open("a") as log:
            log.write(
                json.dumps(
                    {
                        "path": message.path,
                        "interface": message.interface,
                        "method": message.member,
                    }
                )
                + "\n"
            )
        if message.interface == "org.freedesktop.DBus.Introspectable":
            xml = "<node>"
            for interface, properties in objects.get(message.path, {}).items():
                xml += '<interface name="' + interface + '">'
                for name, value in properties.items():
                    xml += f'<property name="{name}" type="{value.signature}" access="readwrite"/>'
                if interface == "org.bluez.Device1":
                    xml += '<method name="Connect"/><method name="Disconnect"/>'
                xml += "</interface>"
            xml += '<interface name="org.freedesktop.DBus.ObjectManager"><method name="GetManagedObjects"><arg direction="out" type="a{oa{sa{sv}}}"/></method></interface></node>'
            return Message.new_method_return(message, "s", [xml])
        if message.member == "GetManagedObjects":
            return Message.new_method_return(message, "a{oa{sa{sv}}}", [objects])
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
                name, value = message.body[1:]
                emit(message.path, interface, {name: value})
                if name == "Powered":
                    emit(
                        ADAPTER,
                        interface,
                        {"PowerState": Variant("s", "on" if value.value else "off")},
                    )
                    if not value.value:
                        emit(
                            DEVICE,
                            "org.bluez.Device1",
                            {"Connected": Variant("b", False)},
                        )
                return Message.new_method_return(message)
        if message.interface == "org.bluez.Device1" and message.member in [
            "Connect",
            "Disconnect",
        ]:
            asyncio.create_task(connection(message))
            return True
        if message.interface == "org.example.SettingsTest":
            if message.member == "FailNext":
                fail_next = True
            elif message.member == "PowerState":
                emit(
                    ADAPTER,
                    "org.bluez.Adapter1",
                    {
                        "PowerState": Variant("s", message.body[0]),
                        "Powered": Variant("b", message.body[0] == "on"),
                    },
                )
            elif message.member == "Connected":
                emit(
                    DEVICE,
                    "org.bluez.Device1",
                    {"Connected": Variant("b", message.body[0])},
                )
            elif message.member == "DeviceBlocked":
                emit(
                    DEVICE,
                    "org.bluez.Device1",
                    {"Blocked": Variant("b", message.body[0])},
                )
            elif message.member == "Paired":
                emit(
                    DEVICE,
                    "org.bluez.Device1",
                    {"Paired": Variant("b", message.body[0])},
                )
            elif message.member == "AdapterPresent":
                if message.body[0]:
                    bus.send(
                        Message.new_signal(
                            "/",
                            "org.freedesktop.DBus.ObjectManager",
                            "InterfacesAdded",
                            "oa{sa{sv}}",
                            [ADAPTER, objects[ADAPTER]],
                        )
                    )
                else:
                    bus.send(
                        Message.new_signal(
                            "/",
                            "org.freedesktop.DBus.ObjectManager",
                            "InterfacesRemoved",
                            "oas",
                            [ADAPTER, ["org.bluez.Adapter1"]],
                        )
                    )
            return Message.new_method_return(message)
        return Message.new_error(
            message,
            "org.freedesktop.DBus.Error.UnknownMethod",
            "Unsupported test method",
        )

    bus.add_message_handler(handler)
    await bus.request_name("org.bluez")
    print("BlueZ fixture ready", flush=True)
    await asyncio.Future()


asyncio.run(main())
