// Gmail's original-message endpoint needs this page-global account key.
// Only this read runs in MAIN. Fetching and clipboard access stay isolated.
(() => {
  document.addEventListener("gmail-message-id:key-request", () => {
    document.dispatchEvent(new CustomEvent("gmail-message-id:key-response", {
      detail: typeof window.GM_ID_KEY === "string" ? window.GM_ID_KEY : "",
    }));
  });
})();
