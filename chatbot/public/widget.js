// GovWifi AI Support Assistant — embeddable widget.
//
// Embed on any page with:
//   <script src="https://assistant.wifi.service.gov.uk/widget.js" defer></script>
//
// The widget derives its API URL from its own <script src>, so it works
// unchanged from any host. All state lives in this closure; the widget
// never touches window.* apart from the `govwifiAssistant` public API.
//
// Class names are prefixed .gwa- to avoid collisions with GOV.UK
// Design System or host-page styles.

(function () {
  "use strict";

  // ---------------------------------------------------------------- Styles
  const CSS = `
    .gwa-container {
      position: fixed; bottom: 20px; right: 20px; z-index: 9999;
      font-family: "GDS Transport", Arial, Helvetica, sans-serif;
      color: #0b0c0c;
    }
    .gwa-launcher {
      background: #00703c; color: #ffffff; border: 2px solid #002d18;
      border-radius: 50%; width: 60px; height: 60px;
      font-size: 28px; font-weight: 700; cursor: pointer;
      box-shadow: 0 4px 12px rgba(0,0,0,0.25);
      display: flex; align-items: center; justify-content: center;
    }
    .gwa-launcher:hover  { background: #005a30; }
    .gwa-launcher:focus  { outline: 3px solid #ffdd00; outline-offset: 0; }

    .gwa-panel {
      position: fixed; bottom: 90px; right: 20px;
      width: 380px; max-width: calc(100vw - 40px);
      height: 560px; max-height: calc(100vh - 120px);
      background: #ffffff; border: 2px solid #0b0c0c;
      display: flex; flex-direction: column;
      box-shadow: 0 6px 24px rgba(0,0,0,0.25);
    }
    .gwa-panel[hidden] { display: none; }

    .gwa-header {
      background: #0b0c0c; color: #ffffff;
      padding: 12px 16px;
      display: flex; align-items: center; justify-content: space-between;
    }
    .gwa-title  { margin: 0; font-size: 18px; font-weight: 700; }
    .gwa-close  {
      background: transparent; color: #ffffff; border: 0;
      font-size: 24px; line-height: 1; cursor: pointer; padding: 4px 8px;
    }
    .gwa-close:focus { outline: 3px solid #ffdd00; }

    .gwa-messages {
      flex: 1 1 auto; overflow-y: auto; padding: 16px;
      background: #f3f2f1;
    }
    .gwa-msg { margin: 0 0 12px 0; }
    .gwa-msg-user      { text-align: right; }
    .gwa-msg-user  .gwa-bubble {
      background: #1d70b8; color: #ffffff;
      display: inline-block; padding: 8px 12px; border-radius: 4px;
      max-width: 85%; text-align: left;
    }
    .gwa-msg-assistant .gwa-bubble {
      background: #ffffff; border: 1px solid #b1b4b6;
      padding: 12px; border-radius: 4px;
    }
    .gwa-msg-assistant .gwa-bubble p:last-child { margin-bottom: 0; }

    .gwa-input-row {
      border-top: 1px solid #b1b4b6; padding: 12px;
      display: flex; gap: 8px; background: #ffffff;
    }
    .gwa-input {
      flex: 1 1 auto; padding: 8px 12px;
      font-family: inherit; font-size: 16px;
      border: 2px solid #0b0c0c; background: #ffffff; color: #0b0c0c;
    }
    .gwa-input:focus { outline: 3px solid #ffdd00; outline-offset: 0; }
    .gwa-send {
      background: #00703c; color: #ffffff; border: 2px solid #002d18;
      padding: 8px 16px; font-size: 16px; font-weight: 700; cursor: pointer;
    }
    .gwa-send:disabled { opacity: 0.5; cursor: not-allowed; }
    .gwa-send:focus { outline: 3px solid #ffdd00; outline-offset: 0; }

    @media (max-width: 640px) {
      .gwa-panel {
        top: 0; right: 0; bottom: 0; left: 0;
        width: 100%; max-width: 100%; height: 100%; max-height: 100%;
      }
    }
  `;

  // ---------------------------------------------------------------- DOM
  function template() {
    const el = document.createElement("div");
    el.className = "gwa-container";
    el.innerHTML = `
      <button
        class="gwa-launcher"
        type="button"
        aria-label="Open GovWifi Support Assistant"
        aria-expanded="false"
        aria-controls="gwa-panel"
      >?</button>
      <div
        class="gwa-panel"
        id="gwa-panel"
        role="dialog"
        aria-modal="false"
        aria-labelledby="gwa-title"
        hidden
      >
        <div class="gwa-header">
          <h2 class="gwa-title" id="gwa-title">GovWifi Support Assistant</h2>
          <button class="gwa-close" type="button" aria-label="Close">&times;</button>
        </div>
        <div class="gwa-messages" role="log" aria-live="polite" aria-atomic="false"></div>
        <form class="gwa-input-row" novalidate>
          <label class="gwa-visually-hidden" for="gwa-input">Type your question</label>
          <input
            class="gwa-input"
            id="gwa-input"
            type="text"
            autocomplete="off"
            placeholder="Ask a question…"
          />
          <button class="gwa-send" type="submit">Send</button>
        </form>
      </div>
    `;
    return el;
  }

  // ---------------------------------------------------------------- Boot
  function boot() {
    if (document.querySelector(".gwa-container")) return; // idempotent

    injectStyles();
    const root = template();
    document.body.appendChild(root);

    const launcher = root.querySelector(".gwa-launcher");
    const panel    = root.querySelector(".gwa-panel");
    const closeBtn = root.querySelector(".gwa-close");

    function open()  {
      panel.hidden = false;
      launcher.setAttribute("aria-expanded", "true");
      root.querySelector(".gwa-input").focus();
    }
    function close() {
      panel.hidden = true;
      launcher.setAttribute("aria-expanded", "false");
      launcher.focus();
    }

    launcher.addEventListener("click", open);
    closeBtn.addEventListener("click", close);

    window.govwifiAssistant = { open: open, close: close };
  }

  function injectStyles() {
    const style = document.createElement("style");
    style.textContent = CSS;
    document.head.appendChild(style);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
