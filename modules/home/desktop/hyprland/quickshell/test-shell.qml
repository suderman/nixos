import Quickshell
import Quickshell.Io

Scope {
  Herdr { id: herdr }
  MiniMaxQuota { id: mini }
  CodexLb { id: codex }

  IpcHandler {
    target: "theme-test"

    function openPinned(): void {
      [herdr, mini, codex].forEach(popup => {
        popup.show();
        popup.pinned = true;
      });
      codex.accountActionMessage = "Probe in progress";
    }

    function showOnly(name: string): void {
      [herdr, mini, codex].forEach(popup => popup.hide());
      let popup = name === "herdr" ? herdr : name === "mini" ? mini : codex;
      popup.show();
      popup.pinned = true;
    }

    function snapshot(): string {
      return JSON.stringify({
        mode: Theme.mode,
        colors: Theme.colors,
        text: { heading: Theme.headingText, detail: Theme.detailText,
          muted: Theme.mutedText, selected: Theme.selectedText },
        popups: [herdr, mini, codex].map(popup => ({
          open: popup.open,
          pinned: popup.pinned,
          background: popup.base00,
          foreground: popup.base05,
          accent: popup.base0D,
          data: popup.data
        })),
        actionMessage: codex.accountActionMessage
      });
    }
  }
}
