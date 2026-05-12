from pathlib import Path


path = Path("src/modules/hyprland/workspace.cpp")
text = path.read_text()

old_namespace = "namespace waybar::modules::hyprland {\n\n"
new_namespace = r'''namespace waybar::modules::hyprland {

namespace {
std::string quoteLuaString(std::string value) {
  size_t pos = 0;
  while ((pos = value.find('\\', pos)) != std::string::npos) {
    value.replace(pos, 1, "\\\\");
    pos += 2;
  }

  pos = 0;
  while ((pos = value.find('"', pos)) != std::string::npos) {
    value.replace(pos, 1, "\\\"");
    pos += 2;
  }

  return "\"" + value + "\"";
}
}  // namespace

'''

replacements = {
    old_namespace: new_namespace,
    "          m_ipc.getSocket1Reply(\"dispatch focusworkspaceoncurrentmonitor \" + std::to_string(id()));": "          auto command = \"hl.dsp.focus({ workspace = \" + quoteLuaString(std::to_string(id())) + \", on_current_monitor = true })\";\n          m_ipc.getSocket1Reply(\"dispatch \" + command);",
    "          m_ipc.getSocket1Reply(\"dispatch workspace \" + std::to_string(id()));": "          auto command = \"hl.dsp.focus({ workspace = \" + quoteLuaString(std::to_string(id())) + \" })\";\n          m_ipc.getSocket1Reply(\"dispatch \" + command);",
    "          m_ipc.getSocket1Reply(\"dispatch focusworkspaceoncurrentmonitor name:\" + name());": "          auto command = \"hl.dsp.focus({ workspace = \" + quoteLuaString(\"name:\" + name()) + \", on_current_monitor = true })\";\n          m_ipc.getSocket1Reply(\"dispatch \" + command);",
    "          m_ipc.getSocket1Reply(\"dispatch workspace name:\" + name());": "          auto command = \"hl.dsp.focus({ workspace = \" + quoteLuaString(\"name:\" + name()) + \" })\";\n          m_ipc.getSocket1Reply(\"dispatch \" + command);",
    "        m_ipc.getSocket1Reply(\"dispatch togglespecialworkspace \" + name());": "        m_ipc.getSocket1Reply(\"dispatch hl.dsp.workspace.toggle_special(\" + quoteLuaString(name()) + \")\");",
    "        m_ipc.getSocket1Reply(\"dispatch togglespecialworkspace\");": "        m_ipc.getSocket1Reply(\"dispatch hl.dsp.workspace.toggle_special(\\\"special\\\")\");",
}

for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"expected Waybar source snippet not found: {old}")
    text = text.replace(old, new, 1)

path.write_text(text)
