import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "bridge", Path(__file__).with_name("herdr-hypr.py")
)
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)


class PairingTest(unittest.TestCase):
    def setUp(self):
        self.workspace = {"workspace_id": "wA", "label": "renamable"}
        self.owner = "chromium-agent-123456789abc-wA"
        self.env = patch.dict(
            os.environ,
            {"HYPRLAND_INSTANCE_SIGNATURE": "live", "XDG_RUNTIME_DIR": "/runtime"},
            clear=True,
        )
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_metadata_success_has_no_json(self):
        result = bridge.subprocess.CompletedProcess([], 0, stdout="", stderr="")
        with patch.object(bridge.subprocess, "run", return_value=result):
            self.assertEqual(bridge.herdr("workspace", "report-metadata", "wA"), "")

    def test_missing_context(self):
        with self.assertRaisesRegex(bridge.Error, "inside a Herdr-owned pane"):
            bridge.context()

    def test_context_follows_moved_pane(self):
        with tempfile.NamedTemporaryFile() as socket:
            os.environ.update(
                HERDR_SOCKET_PATH=socket.name,
                HERDR_WORKSPACE_ID="wOld",
                HERDR_PANE_ID="wOld:p1",
            )
            with patch.object(
                bridge,
                "herdr",
                side_effect=[
                    {"pane": {"workspace_id": "wA"}},
                    {"workspace": self.workspace},
                ],
            ):
                workspace, owner, path = bridge.context()
        self.assertEqual(workspace, self.workspace)
        self.assertTrue(owner.endswith("-wA"))
        self.assertEqual(path, socket.name)

    def test_only_current_absolute_metadata(self):
        for value in ["4", "name:project", "special:trial"]:
            self.assertEqual(
                bridge.target(
                    {"tokens": {"hypr_workspace": value, "hypr_instance": "live"}}
                ),
                value,
            )
        for value in ["", "0", "-1", "r+1", "previous", "name:", "special:", "4\n"]:
            self.assertIsNone(
                bridge.target(
                    {"tokens": {"hypr_workspace": value, "hypr_instance": "live"}}
                )
            )
        self.assertIsNone(
            bridge.target({"tokens": {"hypr_workspace": "4", "hypr_instance": "old"}})
        )
        self.assertIsNone(bridge.target({}))
        self.assertIsNone(bridge.target({"tokens": None}))
        self.assertIsNone(
            bridge.target({"tokens": {"hypr_workspace": 4, "hypr_instance": "live"}})
        )

    def test_pair_moves_all_and_only_owned(self):
        clients = [
            {"class": self.owner, "address": "0xa"},
            {"class": self.owner, "address": "0xb"},
            {"class": "chromium-browser", "address": "0xc"},
            {"class": "chromium-agent-123456789abc-wB", "address": "0xd"},
        ]
        with (
            patch.object(
                bridge, "context", return_value=(self.workspace, self.owner, "/socket")
            ),
            patch.object(
                bridge,
                "hypr",
                side_effect=lambda kind: (
                    clients if kind == "clients" else {"id": 7, "name": "7"}
                ),
            ),
            patch.object(bridge, "herdr") as metadata,
            patch.object(bridge, "move") as move,
        ):
            bridge.main(["pair"])
        self.assertEqual(move.call_count, 2)
        self.assertEqual(move.call_args_list[0].args, (clients[0], "7"))
        self.assertIn("hypr_workspace=7", metadata.call_args.args)

    def test_unpair_does_not_move_windows(self):
        with (
            patch.object(
                bridge, "context", return_value=(self.workspace, self.owner, "/socket")
            ),
            patch.object(bridge, "herdr") as metadata,
            patch.object(bridge, "hypr") as hypr,
        ):
            bridge.main(["unpair"])
        hypr.assert_not_called()
        self.assertIn("--clear-token", metadata.call_args.args)

    def test_unpaired_goto_does_nothing(self):
        with (
            patch.object(
                bridge, "context", return_value=(self.workspace, self.owner, "/socket")
            ),
            patch.object(bridge, "hypr"),
            patch.object(bridge, "dispatch") as dispatch,
            self.assertRaisesRegex(bridge.Error, "not paired"),
        ):
            bridge.main(["goto"])
        dispatch.assert_not_called()

    def test_normal_browser_never_reads_process_context(self):
        with (
            patch.object(
                bridge,
                "hypr",
                return_value=[{"address": "0xa", "class": "chromium-browser"}],
            ),
            patch.object(bridge.Path, "read_bytes") as process,
        ):
            bridge.route("0xa")
        process.assert_not_called()

    def test_route_resolves_browser_socket(self):
        client = {
            "address": "0xa",
            "class": self.owner,
            "pid": 123,
            "workspace": {"id": 2, "name": "2"},
        }
        workspace = self.workspace | {
            "tokens": {"hypr_workspace": "7", "hypr_instance": "live"}
        }
        with (
            patch.object(bridge, "hypr", return_value=[client]),
            patch.object(bridge, "browser_pid", return_value=123),
            patch.object(bridge.Path, "readlink", return_value=Path("/named/socket")),
            patch.object(
                bridge, "socket_key", return_value=("123456789abc", "/named/socket")
            ),
            patch.object(
                bridge, "herdr", return_value={"workspace": workspace}
            ) as query,
            patch.object(bridge, "move") as move,
        ):
            bridge.route("0xa")
        self.assertEqual(
            query.call_args.kwargs["env"]["HERDR_SOCKET_PATH"], "/named/socket"
        )
        move.assert_called_once_with(client, "7")

    def test_old_server_generation_does_not_route(self):
        client = {"address": "0xa", "class": self.owner, "pid": 123}
        with (
            patch.object(bridge, "hypr", return_value=[client]),
            patch.object(bridge, "browser_pid", return_value=123),
            patch.object(bridge.Path, "readlink", return_value=Path("/socket")),
            patch.object(
                bridge, "socket_key", return_value=("differentkey", "/socket")
            ),
            patch.object(bridge, "herdr") as query,
        ):
            bridge.route("0xa")
        query.assert_not_called()

    def test_cdp_accepts_native_and_flattened_argv(self):
        for separator in [b"\0", b" "]:
            argv = separator.join(
                [
                    b"chromium",
                    f"--class={self.owner}".encode(),
                    f"--user-data-dir=/runtime/chromium-agent/{self.owner}".encode(),
                    b"about:blank",
                    b"",
                ]
            )
            with (
                patch.object(bridge, "browser_pid", return_value=123),
                patch.object(bridge.Path, "read_bytes", return_value=argv),
                patch.object(
                    bridge.Path, "read_text", return_value="34567\n/browser/uuid"
                ),
            ):
                self.assertEqual(
                    bridge.cdp_endpoint(self.owner), "http://127.0.0.1:34567"
                )

    def test_cdp_rejects_reused_pid(self):
        with (
            patch.object(bridge, "browser_pid", return_value=123),
            patch.object(
                bridge.Path, "read_bytes", return_value=b"unrelated-process\0"
            ),
            self.assertRaisesRegex(bridge.Error, "not running"),
        ):
            bridge.cdp_endpoint(self.owner)

    def test_devtools_outside_herdr_keeps_global_port(self):
        with patch.object(bridge.os, "execvp") as execute:
            bridge.main(["devtools", "--no-usage-statistics"])
        self.assertIn("--browser-url=http://127.0.0.1:9222", execute.call_args.args[1])

    def test_devtools_inside_herdr_uses_owned_port(self):
        os.environ["HERDR_WORKSPACE_ID"] = "wA"
        with (
            patch.object(
                bridge, "context", return_value=(self.workspace, self.owner, "/socket")
            ),
            patch.object(bridge, "cdp_endpoint", return_value="http://127.0.0.1:34567"),
            patch.object(bridge.os, "execvp") as execute,
        ):
            bridge.main(["devtools", "--no-usage-statistics"])
        self.assertIn("--browser-url=http://127.0.0.1:34567", execute.call_args.args[1])

    def test_selectors(self):
        self.assertEqual(bridge.selector({"id": 7, "name": "7"}), "7")
        self.assertEqual(bridge.selector({"id": 8, "name": "project"}), "name:project")
        self.assertEqual(
            bridge.selector({"id": -1, "name": "special:trial"}), "special:trial"
        )


if __name__ == "__main__":
    unittest.main()
