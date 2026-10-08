(() => {
  const cards = ".v-MessageCard:not(.v-MessageCard--draft)";
  const buttonClass = "fastmail-message-id-copy";
  const copyLabel = "Copy this message's RFC Message-ID for notmuch";
  const resetTimers = new WeakMap();

  function queryForMessage(button) {
    return new Promise((resolve, reject) => {
      const requestId = crypto.randomUUID();
      const responseEvent = "webmail-message-id:fastmail-response";
      const timeout = setTimeout(() => {
        button.removeEventListener(responseEvent, receive);
        reject(new Error("Fastmail message lookup timed out. Reload and retry."));
      }, 15000);
      function receive(event) {
        const result = event.detail;
        if (result?.requestId !== requestId) return;
        clearTimeout(timeout);
        button.removeEventListener(responseEvent, receive);
        if (result.error) reject(new Error(result.error));
        else if (typeof result.query === "string" && /^id:[^<>\s"']+@[^<>\s"']+$/.test(result.query)) resolve(result.query);
        else reject(new Error("Fastmail response lacked a valid RFC Message-ID."));
      }
      button.addEventListener(responseEvent, receive);
      button.dispatchEvent(new CustomEvent("webmail-message-id:fastmail-request", {
        bubbles: true,
        detail: requestId,
      }));
    });
  }

  async function copyMessage(event, card, button) {
    event.preventDefault();
    event.stopPropagation();
    if (button.disabled) return;
    clearTimeout(resetTimers.get(button));
    button.disabled = true;
    button.textContent = "…";
    button.title = copyLabel;
    button.setAttribute("aria-label", "Copying Message-ID");
    try {
      const query = await queryForMessage(button);
      if (!card.isConnected) throw new Error("Conversation changed. Select the message again.");
      try {
        await navigator.clipboard.writeText(query);
      } catch {
        throw new Error("Clipboard write failed. Focus Fastmail and retry.");
      }
      button.textContent = "Copied";
      button.setAttribute("aria-label", "Message-ID copied");
      resetTimers.set(button, setTimeout(() => {
        button.textContent = "ID";
        button.setAttribute("aria-label", copyLabel);
      }, 2000));
    } catch (error) {
      button.textContent = "Failed";
      button.title = error.message;
      button.setAttribute("aria-label", `Copy failed: ${error.message} Click to retry.`);
      console.error("Webmail Message-ID: Fastmail copy failed", {
        cardId: card.id,
        reason: error.message,
      });
    } finally {
      button.disabled = false;
    }
  }

  function scan() {
    for (const card of document.querySelectorAll(cards)) {
      // Collapsed cards overlap their hidden action rows. Use the visible date instead.
      const slot = card.querySelector(card.classList.contains("is-collapsed")
        ? ".v-MessageCard-time" : ".v-MessageCard-actions");
      if (!slot) continue;
      let button = card.querySelector(`button.${buttonClass}`);
      if (!button) {
        button = document.createElement("button");
        button.type = "button";
        button.className = buttonClass;
        button.textContent = "ID";
        button.title = copyLabel;
        button.setAttribute("aria-label", copyLabel);
        button.setAttribute("aria-live", "polite");
      }
      if (button.parentElement !== slot) slot.append(button);
    }
  }

  // Fastmail dispatches shortcuts during document capture, before button handlers.
  // Capture only our controls at the window; all native Fastmail targets pass through.
  for (const type of ["click", "pointerdown", "mousedown", "mouseup", "dblclick", "keydown", "keyup"]) {
    window.addEventListener(type, (event) => {
      const button = event.target.closest?.(`button.${buttonClass}`);
      if (!button) return;
      event.stopPropagation();
      if (type === "click" || (type === "keydown" && (event.key === "Enter" || event.key === " "))) {
        copyMessage(event, button.closest(cards), button);
      }
    }, true);
  }

  let scheduled = false;
  new MutationObserver(() => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      scan();
    });
  }).observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ["class"] });
  scan();
})();
