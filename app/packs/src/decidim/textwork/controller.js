// One paragraph resource is mounted at a time; document text never moves into a form.
/* eslint max-lines: ["error", {"max": 800, "skipBlankLines": true, "skipComments": true}] */
import { Controller } from "@hotwired/stimulus";
import { renderDiff, normalizeText } from "src/decidim/textwork/diff.mjs";
import {
  resizeReadingImage,
  showImage,
  hideImage
} from "src/decidim/textwork/image_viewer";
import { panelComments } from "src/decidim/textwork/panel_comments";
export default class extends Controller {
  static targets = ["panel", "document", "toc", "intro", "rail", "overlay", "status", "login", "confirm", "imageDialog"];
  static values = {
    panelUrl: String,
    statisticsUrl: String,
    signedIn: Boolean,
    labels: Object
  };
  connect() {
    this.mobile = window.matchMedia("(max-width: 1023px)");
    this.pendingWrites = new Set();
    this.panelDialogs = new Set();
    this.dialogHandler = (event) => {
      if (event.detail && this.panelTarget.contains(event.detail)) {
        this.rememberDialogs(event.detail);
      }
    };
    document.addEventListener("ajax:loaded", this.dialogHandler, true);
    this.clickHandler = (event) => {
      const trigger = event.target.closest("[data-open-block]");
      if (trigger) {
        event.preventDefault();
        this.open(
          trigger.dataset.openBlock,
          trigger.dataset.mode,
          trigger.dataset.suggestionId,
          trigger
        );
      }
    };
    this.popHandler = () => this.fromLocation(true);
    this.keyHandler = (event) => this.keydown(event);
    this.resizeHandler = () => {
      this.responsive();
      this.element.
        querySelectorAll("[data-reading-image]").
        forEach((image) => this.imageLoaded({ currentTarget: image }));
    };
    this.scrollHandler = () => {
      cancelAnimationFrame(this.railFrame);
      this.railFrame = requestAnimationFrame(() => this.sizeRail());
    };
    this.unloadHandler = (event) => {
      if (this.dirty) {
        event.preventDefault();
        event.returnValue = "";
      }
    };
    this.writeHandler = (event) => {
      if (!event.target.closest("[data-decidim-comments]")) {
        return;
      }
      const pending = new Promise((resolve) =>
        event.target.addEventListener("ajax:complete", resolve, {
          once: true
        })
      );
      this.pendingWrites.add(pending);
      pending.finally(() => this.pendingWrites.delete(pending));
    };
    this.imageCancelHandler = (event) => {
      event.preventDefault();
      this.closeImage();
    };
    this.element.addEventListener("click", this.clickHandler);
    this.element.addEventListener("ajax:beforeSend", this.writeHandler);
    window.addEventListener("popstate", this.popHandler);
    window.addEventListener("keydown", this.keyHandler);
    window.addEventListener("beforeunload", this.unloadHandler);
    window.addEventListener("scroll", this.scrollHandler, {
      passive: true
    });
    window.addEventListener("resize", this.resizeHandler);
    this.imageDialogTarget.addEventListener("cancel", this.imageCancelHandler);
    this.sizeObserver = new ResizeObserver(this.scrollHandler);
    this.sizeObserver.observe(this.documentTarget);
    this.sizeObserver.observe(this.introTarget);
    this.lastUrl = location.href;
    this.configureOverview();
    this.fromLocation();
    this.responsive();
  }
  disconnect() {
    document.removeEventListener("ajax:loaded", this.dialogHandler, true);
    this.abort?.abort();
    this.statsAbort?.abort();
    this.unmountComments();
    this.sizeObserver?.disconnect();
    cancelAnimationFrame(this.railFrame);
    this.element.removeEventListener("click", this.clickHandler);
    this.element.removeEventListener("ajax:beforeSend", this.writeHandler);
    window.removeEventListener("popstate", this.popHandler);
    window.removeEventListener("keydown", this.keyHandler);
    window.removeEventListener("beforeunload", this.unloadHandler);
    window.removeEventListener("scroll", this.scrollHandler);
    window.removeEventListener("resize", this.resizeHandler);
    this.imageDialogTarget.removeEventListener(
      "cancel",
      this.imageCancelHandler
    );
    this.releaseBackground();
  }
  async fromLocation(pop = false) {
    if (pop && !(await this.confirmDiscard())) {
      history.pushState({}, "", this.lastUrl);
      return;
    }
    const url = new URL(location.href);
    const block = url.searchParams.get("block");
    if (block) {
      await this.open(
        block,
        "list",
        url.searchParams.get("suggestion"),
        null,
        false
      );
    } else if (this.block) {
      await this.overview(false);
    }
  }
  // eslint-disable-next-line max-params
  async open(
    block,
    mode = "list",
    suggestion = null,
    trigger = null,
    push = true
  ) {
    const paragraph = this.element.querySelector(
      `.tw-paragraph[data-block="${CSS.escape(String(block))}"]`
    );
    if (!paragraph) {
      if (this.block) {
        await this.overview(false);
      }
      this.setUrl(null, null, false);
      return;
    }
    if (!(await this.confirmDiscard())) {
      return;
    }
    await Promise.all(this.pendingWrites);
    if (mode === "edit" && !this.signedInValue) {
      this.loginTarget.click();
      return;
    }
    this.abort?.abort();
    const abort = new AbortController();
    this.abort = abort;
    this.panelTarget.setAttribute("aria-busy", "true");
    const url = new URL(this.panelUrlValue, location.origin);
    Object.entries({
      block,
      mode,
      suggestion,
      original: new URL(location.href).searchParams.get("original")
    }).forEach(([key, value]) => {
      if (value) {
        url.searchParams.set(key, value);
      }
    });
    try {
      const response = await fetch(url, {
        signal: abort.signal,
        headers: {
          "X-Requested-With": "XMLHttpRequest"
        }
      });
      if (!response.ok) {
        throw new Error();
      }
      const html = await response.text();
      if (abort.signal.aborted) {
        return;
      }
      this.unmountComments();
      this.panelTarget.innerHTML = html;
      this.block = String(block);
      this.mode =
        this.panelTarget.querySelector("[data-panel-mode]")?.dataset.
          panelMode || "list";
      this.lastBlock = this.block;
      this.lastNumber = this.panelTarget.querySelector(
        "[data-panel-number]"
      )?.dataset.panelNumber;
      this.returnFocus =
        paragraph.querySelector("[data-block-pill]") || trigger;
      this.form = this.panelTarget.querySelector("[data-suggestion-form]");
      this.initialDraft = this.draftSignature();
      this.dirty = false;
      this.element.
        querySelectorAll(".tw-paragraph").
        forEach((row) =>
          row.classList.toggle("tw-selected", row.dataset.block === this.block)
        );
      this.element.classList.toggle("tw-editing", this.mode === "edit");
      if (push) {
        this.setUrl(block, suggestion);
      }
      this.responsive();
      this.renderComparisons();
      this.rememberDialogs(this.panelTarget);
      document.dispatchEvent(
        new CustomEvent("ajax:loaded", { detail: this.panelTarget })
      );
      this.mountComments();
      this.panelTarget.querySelector("[data-panel-title]")?.focus({
        preventScroll: true
      });
      if (this.form) {
        this.changed();
        const field = this.form.elements.body;
        field.focus({
          preventScroll: true
        });
        field.setSelectionRange(field.value.length, field.value.length);
      }
      this.refreshStatistics();
    } catch (error) {
      if (error.name !== "AbortError") {
        this.statusTarget.textContent = this.labelsValue.error;
      }
    } finally {
      if (!abort.signal.aborted) {
        this.panelTarget.removeAttribute("aria-busy");
      }
    }
  }
  setUrl(block, suggestion, push = true) {
    const url = new URL(location.href);
    ["block", "suggestion"].forEach((key) => url.searchParams.delete(key));
    if (block) {
      url.searchParams.set("block", block);
    }
    if (suggestion) {
      url.searchParams.set("suggestion", suggestion);
    }
    url.hash = "";
    if (url.href !== location.href) {
      history[push
        ? "pushState"
        : "replaceState"]({}, "", url);
    }
    this.lastUrl = url.href;
  }
  async close() {
    if (this.mode === "edit" || this.mode === "detail") {
      await this.open(this.block);
    } else if (await this.confirmDiscard()) {
      await this.overview();
    }
  }
  async overview(push = true) {
    await Promise.all(this.pendingWrites);
    this.abort?.abort();
    const abort = new AbortController();
    this.abort = abort;
    try {
      const response = await fetch(this.panelUrlValue, {
        signal: abort.signal
      });
      if (!response.ok) {
        throw new Error();
      }
      const html = await response.text();
      if (abort.signal.aborted) {
        return;
      }
      this.unmountComments();
      this.panelTarget.innerHTML = html;
      this.block = null;
      this.mode = "overview";
      this.form = null;
      this.dirty = false;
      this.element.classList.remove("tw-editing");
      this.element.
        querySelectorAll(".tw-selected").
        forEach((row) => row.classList.remove("tw-selected"));
      if (push) {
        this.setUrl(null, null);
      }
      this.configureOverview();
      this.responsive();
      this.returnFocus?.focus({
        preventScroll: true
      });
      this.refreshStatistics();
    } catch (error) {
      if (error.name !== "AbortError") {
        this.statusTarget.textContent = this.labelsValue.error;
      }
    }
  }
  responsive() {
    const modal = this.mobile.matches && Boolean(this.block);
    this.panelTarget.hidden = this.mobile.matches && !this.block;
    this.panelTarget.setAttribute("aria-label", this.panelTarget.querySelector("[data-panel-title]").textContent);
    this.panelTarget.setAttribute("role", modal
      ? "dialog"
      : "complementary");
    if (modal) {
      this.panelTarget.setAttribute("aria-modal", "true");
    } else {
      this.panelTarget.removeAttribute("aria-modal");
    }
    this.documentTarget.inert = modal;
    this.introTarget.inert = modal;
    this.overlayTarget.hidden = !modal;
    document.documentElement.classList.toggle("tw-sheet-open", modal);
    this.sizeRail();
  }
  releaseBackground() {
    this.documentTarget.inert = false;
    this.introTarget.inert = false;
    document.documentElement.classList.remove("tw-sheet-open");
  }
  sizeRail() {
    if (this.mobile.matches) {
      this.panelTarget.style.removeProperty("visibility");
      this.panelTarget.style.removeProperty("height");
      return;
    }
    const top = this.railTarget.getBoundingClientRect().top;
    const footer = document.querySelector('footer[role="contentinfo"]');
    const bottom = Math.min(
      innerHeight,
      footer?.getBoundingClientRect().top ?? innerHeight
    );
    const available = bottom - Math.max(16, top) - 16;
    this.panelTarget.style.height = `${Math.max(0, available)}px`;
    this.panelTarget.style.visibility = available > 0
      ? ""
      : "hidden";
  }
  paragraph(event) {
    if (
      event.target.closest("a,button,input,textarea,select") ||
      window.getSelection()?.toString()
    ) {
      return;
    }
    this.open(event.currentTarget.dataset.block);
  }
  chapter(event) {
    event.preventDefault();
    document.
      querySelector(event.currentTarget.getAttribute("href"))?.
      scrollIntoView({
        block: "start"
      });
    this.tocTarget.open = false;
  }
  configureOverview() {
    const button = this.panelTarget.querySelector("[data-return-block]");
    if (button && this.lastBlock) {
      button.hidden = false;
      button.dataset.openBlock = this.lastBlock;
      button.textContent = this.labelsValue.returnBlock.replace(
        "%NUMBER%",
        this.lastNumber
      );
    }
    let hidden = false;
    try {
      hidden = localStorage.getItem("textwork-help-hidden") === "true";
    } catch {

      /* Restricted storage keeps help visible. */
    }
    this.setHelp(hidden);
  }
  setHelp(hidden) {
    const help = this.panelTarget.querySelector("[data-help]");
    const link = this.panelTarget.querySelector("[data-show-help]");
    if (help) {
      help.hidden = hidden;
    }
    if (link) {
      link.hidden = !hidden;
    }
  }
  hideHelp() {
    this.setHelp(true);
    try {
      localStorage.setItem("textwork-help-hidden", "true");
    } catch {

      /* Optional preference. */
    }
    this.panelTarget.querySelector("[data-show-help]")?.focus();
  }
  showHelp() {
    this.setHelp(false);
    try {
      localStorage.removeItem("textwork-help-hidden");
    } catch {

      /* Optional preference. */
    }
    this.panelTarget.querySelector("[data-help] button")?.focus();
  }
  showAll(event) {
    this.panelTarget.
      querySelectorAll("[data-extra-suggestion]").
      forEach((card) => {
        card.hidden = false;
      });
    event.currentTarget.hidden = true;
    this.panelTarget.querySelector("[data-extra-suggestion] button")?.focus();
  }
  renderComparisons() {
    this.panelTarget.
      querySelectorAll('[data-diff-output][data-translated="false"]').
      forEach((output) => {
        renderDiff(
          output,
          output.dataset.original,
          output.dataset.replacement,
          output.dataset.compact === "true",
          this.labelsValue
        );
      });
  }
  draftSignature() {
    return this.form
      ? JSON.stringify([
        this.form.elements.body.value,
        this.form.elements.justification.value
      ])
      : "";
  }
  changed() {
    if (!this.form) {
      return;
    }
    this.dirty = this.draftSignature() !== this.initialDraft;
    const body = this.form.elements.body.value;
    const original = this.form.querySelector("[data-editor]").dataset.original;
    renderDiff(
      this.form.querySelector("[data-live-diff]"),
      original,
      body,
      false,
      this.labelsValue
    );
    this.panelTarget.querySelector("[data-submit]").disabled =
      normalizeText(body) === normalizeText(original) || !body.trim();
  }
  confirmDiscard(force = false, withdrawal = false) {
    if (!this.dirty && !force) {
      return Promise.resolve(true);
    }
    return new Promise((resolve) => {
      const dialog = this.confirmTarget;
      dialog.querySelector("h2").textContent =
        this.labelsValue[withdrawal
          ? "withdrawQuestion"
          : "discard"];
      dialog.querySelector('[data-tw-choice="keep"]').textContent =
        this.labelsValue[withdrawal
          ? "cancel"
          : "keepEditing"];
      dialog.querySelector('[data-tw-choice="discard"]').textContent =
        this.labelsValue[withdrawal
          ? "withdraw"
          : "discardAction"];
      let click = null;
      let cancel = null;
      const finish = (discard) => {
        dialog.close();
        dialog.removeEventListener("click", click);
        dialog.removeEventListener("cancel", cancel);
        if (discard) {
          this.dirty = false;
        } else {
          this.form?.elements.body.focus({
            preventScroll: true
          });
        }
        resolve(discard);
      };
      click = (event) => {
        const button = event.target.closest("[data-tw-choice]");
        if (button) {
          finish(button.dataset.twChoice === "discard");
        }
      };
      cancel = (event) => {
        event.preventDefault();
        finish(false);
      };
      dialog.addEventListener("click", click);
      dialog.addEventListener("cancel", cancel);
      dialog.showModal();
      dialog.querySelector('[data-tw-choice="keep"]').focus();
    });
  }
  async submit(event) {
    event.preventDefault();
    const form = this.form;
    const button = this.panelTarget.querySelector("[data-submit]");
    button.disabled = true;
    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: new FormData(form),
        headers: {
          Accept: "application/json"
        }
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || this.labelsValue.error);
      }
      this.dirty = false;
      await this.open(data.block);
      this.notice(data.message);
    } catch (error) {
      form.querySelector("[data-form-error]").textContent = error.message;
      button.disabled = false;
    }
  }
  notice(message) {
    const notice = this.panelTarget.querySelector("[data-notice]");
    if (notice) {
      notice.textContent = message;
      notice.hidden = false;
    }
    this.panelTarget.querySelector(".tw-panel-body").scrollTop = 0;
  }
  async withdraw(event) {
    const url = event.currentTarget.dataset.url;
    if (!(await this.confirmDiscard(true, true))) {
      return;
    }
    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: this.requestHeaders()
      });
      if (!response.ok) {
        throw new Error();
      }
      const data = await response.json();
      await this.open(data.block);
      this.notice(data.message);
    } catch {
      this.statusTarget.textContent = this.labelsValue.error;
    }
  }
  requestHeaders() {
    return {
      "X-CSRF-Token":
        document.querySelector('meta[name="csrf-token"]')?.content || "",
      Accept: "application/json"
    };
  }
  async interact(event) {
    const button = event.currentTarget;
    if (!this.signedInValue) {
      this.loginTarget.click();
      return;
    }
    const resource = button.closest("[data-resource]");
    const authorization = resource.querySelector('[data-tw-authorize="like"]');
    if (authorization) {
      authorization.click();
      return;
    }
    const buttons = [
      ...this.element.querySelectorAll(
        `[data-resource="${resource.dataset.resource}"] [data-kind="like"]`
      )
    ];
    buttons.forEach((item) => {
      item.disabled = true;
    });
    try {
      const response = await fetch(button.dataset.url, {
        method:
          button.getAttribute("aria-pressed") === "true"
            ? "DELETE"
            : "POST",
        headers: this.requestHeaders()
      });
      if (!response.ok) {
        throw new Error();
      }
      const data = await response.json();
      this.element.
        querySelectorAll(`[data-resource="${data.key}"]`).
        forEach((container) => {
          container.querySelectorAll("[data-likes-label]").forEach((label) => {
            label.textContent = data.likes_label;
          });
          container.querySelectorAll("[data-likes-count]").forEach((count) => {
            count.textContent = data.likes;
          });
          container.
            querySelectorAll('[data-kind="like"]').
            forEach((control) => {
              control.setAttribute("aria-pressed", data.liked);
              const label = control.querySelector("[data-interaction-label]");
              if (label) {
                label.textContent =
                  this.labelsValue[data.liked
                    ? "liked"
                    : "like"];
              }
              if (control.hasAttribute("data-own-unlike") && !data.liked) {
                control.remove();
              }
            });
        });
      await this.refreshStatistics();
    } catch {
      this.statusTarget.textContent = this.labelsValue.error;
    } finally {
      buttons.forEach((item) => {
        item.disabled = false;
      });
    }
  }
  async refreshStatistics() {
    this.statsAbort?.abort();
    const abort = new AbortController();
    this.statsAbort = abort;
    try {
      const response = await fetch(this.statisticsUrlValue, {
        signal: abort.signal
      });
      if (!response.ok) {
        return;
      }
      const data = await response.json();
      this.element.querySelector("[data-summary]").textContent =
        data.summary_text;
      Object.entries(data.counts).forEach(([block, counts]) => {
        const label = this.labelsValue.openLabel.
          replace("%NUMBER%", data.numbers[block]).
          replace("%LIKES%", counts.likes).
          replace("%SUGGESTIONS%", counts.suggestions).
          replace("%COMMENTS%", counts.comments);
        this.element.
          querySelectorAll(
            `[data-open-block="${block}"][aria-label]:not(.tw-number)`
          ).
          forEach((item) => {
            item.setAttribute("aria-label", label);
          });
        Object.entries(counts).forEach(([kind, count]) =>
          this.element.
            querySelectorAll(
              `[data-block-count="${block}"][data-count-kind="${kind}"]`
            ).
            forEach((item) => {
              item.textContent = count;
            })
        );
      });
      this.element.querySelectorAll("[data-chapter-count]").forEach((item) => {
        item.textContent = data.chapters[item.dataset.chapterCount] || 0;
      });
    } catch {

      /* The next panel navigation retries counters without disturbing reading. */
    }
  }
  mountComments() {
    this.panelTarget.
      querySelectorAll("[data-decidim-comments]").
      forEach((element) => panelComments(element));
    this.lastCommentCount = null;
    this.commentObserver = new MutationObserver(() => {
      const counter = this.panelTarget.querySelector(".comments-count");
      const count = Number(
        counter?.textContent.match(/[\d.,]+/)?.[0].replace(/\D/g, "") || 0
      );
      const comments = this.panelTarget.querySelector("[data-comments-small]");
      if (comments) {
        comments.dataset.commentsSmall = count < 5;
      }
      if (count !== this.lastCommentCount) {
        this.lastCommentCount = count;
        this.refreshStatistics();
      }
      if (this.commentFocusPending) {
        this.focusComment();
      }
    });
    this.commentObserver.observe(this.panelTarget, {
      childList: true,
      subtree: true,
      characterData: true,
      attributes: true,
      attributeFilter: ["disabled"]
    });
  }
  rememberDialogs(element) {
    element.
      querySelectorAll("[data-dialog]").
      forEach((dialog) => this.panelDialogs.add(dialog.dataset.dialog));
  }
  unmountComments() {
    this.panelDialogs.forEach((id) => {
      const dialog = window.Decidim.currentDialogs?.[id];
      dialog?.destroy();
      dialog?.dialog.remove();
      if (window.Decidim.currentDialogs) {
        Reflect.deleteProperty(window.Decidim.currentDialogs, id);
      }
    });
    this.panelDialogs.clear();
    this.commentObserver?.disconnect();
    this.commentFocusPending = false;
    this.panelTarget.
      querySelectorAll("[data-decidim-comments]").
      forEach((element) =>
        window.$(element).data("comments")?.unmountComponent()
      );
  }
  focusComment() {
    if (!this.signedInValue) {
      this.loginTarget.click();
      return;
    }
    const field = this.panelTarget.querySelector("textarea:not([disabled])");
    if (!field) {
      this.commentFocusPending = true;
      return;
    }
    this.commentFocusPending = false;
    const body = this.panelTarget.querySelector(".tw-panel-body");
    body.scrollTop +=
      field.getBoundingClientRect().top -
      body.getBoundingClientRect().top -
      body.clientHeight / 3;
    field.focus({
      preventScroll: true
    });
  }
  imageLoaded(event) {
    resizeReadingImage(event.currentTarget);
  }
  imageBackdrop(event) {
    if (event.target === this.imageDialogTarget) {
      this.closeImage();
    }
  }
  openImage(event) {
    this.imageOrigin = event.currentTarget;
    showImage(this.imageDialogTarget, this.imageOrigin);
  }
  closeImage() {
    hideImage(this.imageDialogTarget, this.imageOrigin);
  }
  keydown(event) {
    if (
      this.confirmTarget.open ||
      this.imageDialogTarget.open ||
      document.querySelector('[data-dialog][aria-hidden="false"]')
    ) {
      return;
    }
    if (event.key === "Escape" && this.block) {
      event.preventDefault();
      this.close();
      return;
    }
    if (event.key !== "Tab" || !this.mobile.matches || !this.block) {
      return;
    }
    const controls = [
      ...this.panelTarget.querySelectorAll(
        'button:not([disabled]),a[href],textarea:not([disabled]),input:not([disabled]):not([type="hidden"]),select:not([disabled])'
      )
    ].filter((control) => control.getClientRects().length > 0);
    const first = controls[0];
    const last = controls.at(-1);
    if (
      event.shiftKey &&
      (document.activeElement === first ||
        document.activeElement.hasAttribute("data-panel-title"))
    ) {
      event.preventDefault();
      last?.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first?.focus();
    }
  }
}
