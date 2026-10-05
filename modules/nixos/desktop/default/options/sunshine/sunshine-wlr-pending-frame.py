"""Compile the request block from Sunshine's patched snapshot function."""

import subprocess
import sys
import tempfile
from pathlib import Path

source = Path(sys.argv[1]).read_text()
snapshot = source.split("inline platf::capture_e snapshot(", 1)[1]
request = snapshot.split("auto to = std::chrono::steady_clock::now() + timeout;", 1)[
    1
].split("do {", 1)[0]
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    (root / "test.cpp").write_text(
        """struct dmabuf_t {
  enum { INITIAL, WAITING, READY, REINIT } status = INITIAL;
  int requests = 0;
  void listen(int, int, int*, int, bool) { ++requests; status = WAITING; }
};
struct {
  int screencopy_manager = 0, dmabuf_interface = 0, supported_modifiers = 0;
} interface;
int main() {
  dmabuf_t dmabuf;
  int output = 0;
  bool cursor = false;
  auto snapshot_request = [&]() {
"""
        + request
        + """
  };
  snapshot_request();
  if (dmabuf.requests != 1) return 1;
  for (int timeout = 0; timeout < 30; ++timeout) snapshot_request();
  if (dmabuf.requests != 1) return 1;
  dmabuf.status = dmabuf_t::READY;
  snapshot_request();
  if (dmabuf.requests != 2) return 1;
  dmabuf.status = dmabuf_t::REINIT;
  snapshot_request();
  if (dmabuf.requests != 3) return 1;
}
"""
    )
    subprocess.run(
        [
            "c++",
            "-std=c++17",
            "-Wall",
            "-Wextra",
            "-Werror",
            str(root / "test.cpp"),
            "-o",
            str(root / "test"),
        ],
        check=True,
    )
    subprocess.run([str(root / "test")], check=True)
print("First, pending, completed and reinitialized frame request checks passed")
