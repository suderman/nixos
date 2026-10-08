(() => {
  // Gmail-specific selectors. Collapsed rows acquire message attributes on expansion.
  const gmail = {
    rows: '.h7[role="listitem"], .kv[role="listitem"]',
    message: '.adn[data-legacy-message-id]',
    headers: '.gE',
    collapsedHeader: '.gE.hI',
    expandedControls: '.gH.acX',
    collapsedControls: '.gH.VYc0jb',
  };
  const buttonClass = "gmail-message-id-copy";
  const copyLabel = "Copy this message's RFC Message-ID for notmuch";
  const resetTimers = new WeakMap();

  function sessionKey() {
    let key = "";
    const receive = (event) => {
      if (typeof event.detail === "string") key = event.detail;
    };
    document.addEventListener("gmail-message-id:key-response", receive, { once: true });
    document.dispatchEvent(new Event("gmail-message-id:key-request"));
    document.removeEventListener("gmail-message-id:key-response", receive);
    if (!/^[a-f0-9]+$/i.test(key)) throw new Error("Gmail account key unavailable. Reload Gmail and retry.");
    return key;
  }

  function messageInRow(row) {
    const message = row.querySelector(gmail.message);
    return message?.closest(gmail.rows) === row ? message : null;
  }

  async function expandMessage(row) {
    const message = messageInRow(row);
    if (message) return message;
    const header = row.querySelector(gmail.collapsedHeader);
    if (!header) throw new Error("Gmail message header changed. Expand the message and retry.");
    return new Promise((resolve, reject) => {
      const observer = new MutationObserver(check);
      const timeout = setTimeout(() => {
        observer.disconnect();
        reject(new Error("Message did not expand. Expand it manually and retry."));
      }, 10000);
      function check() {
        const message = messageInRow(row);
        if (!message) return;
        observer.disconnect();
        clearTimeout(timeout);
        resolve(message);
      }
      observer.observe(row, { childList: true, subtree: true, attributes: true });
      // Expand only the clicked row, never the thread's first/active message.
      header.click();
      check();
    });
  }

  function parseMessageId(html) {
    // Extract text from Gmail's original view without any TrustedHTML sinks.
    const raw = html.match(/<pre\b[^>]*\bid=["']raw_message_text["'][^>]*>([\s\S]*?)<\/pre\s*>/i)?.[1];
    if (!raw) throw new Error("Gmail original-message format changed. No raw headers found.");
    const entities = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'" };
    const text = raw.replace(/&(#x[0-9a-f]+|#\d+|amp|lt|gt|quot|apos);/gi, (_, entity) => {
      if (entity.startsWith("#")) {
        const hex = entity[1].toLowerCase() === "x";
        return String.fromCodePoint(parseInt(entity.slice(hex ? 2 : 1), hex ? 16 : 10));
      }
      return entities[entity.toLowerCase()];
    });
    // Stop at the first blank line so quoted headers in the body cannot win.
    const headers = text.replace(/\r\n?/g, "\n").split(/\n[ \t]*\n/, 1)[0].replace(/\n[ \t]+/g, " ");
    const matches = [...headers.matchAll(/^Message-ID:[ \t]*(.*)$/gim)];
    const id = matches.length === 1 && matches[0][1].trim().match(/^<([^<>\s]+@[^<>\s]+)>$/)?.[1];
    if (!id) throw new Error("No valid RFC Message-ID in this message's headers.");
    return `id:${id}`;
  }

  async function queryForMessage(message) {
    const id = message.getAttribute("data-legacy-message-id");
    if (!/^[a-f0-9]+$/i.test(id || "")) throw new Error("Gmail message identifier unavailable.");
    const accountPath = location.pathname.match(/^\/mail\/u\/\d+\//)?.[0];
    if (!accountPath) throw new Error("Gmail account URL changed. Open the account inbox and retry.");
    const url = new URL(accountPath, location.origin);
    url.search = new URLSearchParams({ ik: sessionKey(), view: "om", th: id });
    const response = await fetch(url, { credentials: "same-origin", signal: AbortSignal.timeout(15000) });
    if (!response.ok) throw new Error(`Gmail original request failed (${response.status}).`);
    return parseMessageId(await response.text());
  }

  async function copyMessage(event, row, button) {
    event.preventDefault();
    event.stopPropagation();
    if (button.disabled) return;
    clearTimeout(resetTimers.get(button));
    button.disabled = true;
    button.textContent = "…";
    button.title = copyLabel;
    button.setAttribute("aria-label", "Copying Message-ID");
    try {
      const query = await queryForMessage(await expandMessage(row));
      if (!row.isConnected) throw new Error("Conversation changed. Select the message again.");
      try {
        await navigator.clipboard.writeText(query);
      } catch {
        throw new Error("Clipboard write failed. Focus Gmail and retry.");
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
    } finally {
      button.disabled = false;
    }
  }

  function scan() {
    for (const row of document.querySelectorAll(gmail.rows)) {
      const header = [...row.querySelectorAll(gmail.headers)].find((element) => element.getClientRects().length);
      if (!header) continue;
      const controls = header.querySelector(gmail.expandedControls) || header.querySelector(gmail.collapsedControls);
      if (!controls) continue;
      let button = row.querySelector(`button.${buttonClass}`);
      if (!button) {
        button = document.createElement("button");
        button.type = "button";
        button.className = buttonClass;
        button.textContent = "ID";
        button.title = copyLabel;
        button.setAttribute("aria-label", copyLabel);
        button.setAttribute("aria-live", "polite");
        button.addEventListener("click", (event) => copyMessage(event, row, button));
        button.addEventListener("pointerdown", (event) => event.stopPropagation());
        button.addEventListener("keydown", (event) => {
          if (event.key === "Enter" || event.key === " ") event.stopPropagation();
        });
      }
      // Move the same control when Gmail switches between collapsed/expanded headers.
      if (button.parentElement !== controls) controls.prepend(button);
    }
  }

  let scheduled = false;
  new MutationObserver(() => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      scan();
    });
  }).observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["class", "style", "data-legacy-message-id"],
  });
  scan();
})();
