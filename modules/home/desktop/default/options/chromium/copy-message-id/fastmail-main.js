// Fastmail's view/model mapping and session-aware JMAP helper live in MAIN.
// No token access, traffic interception, or changes to Fastmail's models.
(() => {
  document.addEventListener("webmail-message-id:fastmail-request", async (event) => {
    const button = event.target;
    const requestId = event.detail;
    if (!(button instanceof HTMLButtonElement) || !button.matches(".fastmail-message-id-copy") || typeof requestId !== "string") return;
    const card = button.closest(".v-MessageCard");
    try {
      const fm = window.FM;
      const email = card && fm?.getViewFromNode(card)?.get("content");
      if (!email || !(email instanceof fm.classes.Message)) {
        throw new Error("Fastmail message mapping changed. Reload and retry.");
      }
      let ids = email.get("messageId");
      if (ids == null) {
        // Collapsed cards may have only summary data. Fetch this Email, not its thread.
        const id = email.get("id");
        const result = await fm.callJMAPMethod("Email/get", {
          accountId: email.get("accountId"),
          ids: [id],
          properties: ["id", "messageId"],
        });
        ids = result.list?.find((item) => item.id === id)?.messageId;
      }
      if (!card.isConnected || fm.getViewFromNode(card)?.get("content") !== email) {
        throw new Error("Conversation changed. Select the message again.");
      }
      if (!Array.isArray(ids) || ids.length !== 1 || typeof ids[0] !== "string") {
        throw new Error("Fastmail did not return one RFC Message-ID for this message.");
      }
      const messageId = ids[0].trim().replace(/^<([^<>]+)>$/, "$1");
      if (!/^[^<>\s"']+@[^<>\s"']+$/.test(messageId)) {
        throw new Error("Fastmail returned an invalid RFC Message-ID.");
      }
      button.dispatchEvent(new CustomEvent("webmail-message-id:fastmail-response", {
        detail: { requestId, query: "id:" + messageId },
      }));
    } catch (error) {
      button.dispatchEvent(new CustomEvent("webmail-message-id:fastmail-response", {
        detail: { requestId, error: error.message || error.description || "Fastmail message lookup failed. Reload and retry." },
      }));
    }
  });
})();
