// This controller owns one panel lifecycle, including its draft and focus state.
/* eslint max-lines: ["error", {"max": 800, "skipBlankLines": true, "skipComments": true}] */
import { Controller } from "@hotwired/stimulus";
import { renderDiff } from "src/decidim/textwork/diff.mjs";
import { panelComments } from "src/decidim/textwork/panel_comments";

export default class extends Controller {
  static targets = [
    "panel",
    "document",
    "toc",
    "intro",
    "overlay",
    "status",
    "login",
    "confirm"
  ];
  static values = { panelUrl: String, signedIn: Boolean, labels: Object };

  connect() {
    this.mobile = window.matchMedia("(max-width: 1023px)");
    this.clickHandler = (event) => {
      const trigger = event.target.closest("[data-open-block]");
      if (!trigger) {
        return;
      }
      event.preventDefault();
      this.open(
        trigger.dataset.openBlock,
        trigger.dataset.mode,
        trigger.dataset.suggestionId,
        trigger
      );
    };
    this.popHandler = () => this.fromLocation(true);
    this.resizeHandler = () => this.responsive();
    this.keyHandler = (event) => this.keydown(event);
    this.unloadHandler = (event) => {
      if (this.dirty) {
        event.preventDefault();
        event.returnValue = "";
      }
    };
    this.pendingCommentWrites = new Set();
    this.commentWriteHandler = (event) => {
      if (!event.target.closest("[data-decidim-comments]")) {
        return;
      }
      const pending = new Promise((resolve) =>
        event.target.addEventListener("ajax:complete", resolve, { once: true })
      );
      this.pendingCommentWrites.add(pending);
      pending.finally(() => this.pendingCommentWrites.delete(pending));
    };
    this.element.addEventListener("ajax:beforeSend", this.commentWriteHandler);
    this.element.addEventListener("click", this.clickHandler);
    window.addEventListener("popstate", this.popHandler);
    window.addEventListener("beforeunload", this.unloadHandler);
    window.addEventListener("keydown", this.keyHandler);
    this.mobile.addEventListener("change", this.resizeHandler);
    this.lastUrl = window.location.href;
    this.fromLocation();
    this.observeChapters();
  }

  disconnect() {
    this.abort?.abort();
    this.unmountComments();
    this.observer?.disconnect();
    this.commentObserver?.disconnect();
    this.element.removeEventListener(
      "ajax:beforeSend",
      this.commentWriteHandler
    );
    this.element.removeEventListener("click", this.clickHandler);
    window.removeEventListener("popstate", this.popHandler);
    window.removeEventListener("beforeunload", this.unloadHandler);
    window.removeEventListener("keydown", this.keyHandler);
    this.mobile.removeEventListener("change", this.resizeHandler);
    this.releaseBackground();
  }

  async fromLocation(pop = false) {
    const url = new URL(window.location.href);
    if (pop && this.dirty && !(await this.confirmDiscard())) {
      history.pushState({}, "", this.lastUrl);
      return;
    }
    if (url.searchParams.has("block")) {
      await this.open(
        url.searchParams.get("block"),
        url.searchParams.get("suggestion")
          ? "suggestions"
          : "comments",
        url.searchParams.get("suggestion"),
        null,
        false
      );
      document.
        getElementById(`block-${url.searchParams.get("block")}`)?.
        scrollIntoView({ block: "center" });
    } else {
      this.hide(false);
    }
    this.lastUrl = window.location.href;
  }

  // URL, presentation mode and focus origin are independent navigation inputs.
  // eslint-disable-next-line max-params
  async open(
    block,
    mode = "comments",
    suggestion = null,
    trigger = null,
    push = true
  ) {
    if (!(await this.confirmDiscard())) {
      return;
    }
    await Promise.all(this.pendingCommentWrites);
    if (mode === "edit" && !this.signedInValue) {
      this.setUrl(block, suggestion);
      this.loginTarget.click();
      return;
    }
    this.returnFocus = trigger || this.returnFocus;
    this.block = String(block);
    this.mode = mode;
    this.abort?.abort();
    const abort = new AbortController();
    this.abort = abort;
    this.clearEditor();
    this.unmountComments();
    this.panelTarget.hidden = false;
    this.panelTarget.setAttribute("aria-busy", "true");
    this.panelTarget.textContent = this.labelsValue.loading;
    this.panelTarget.focus({ preventScroll: true });
    this.element.classList.add("tw-is-open");
    this.tocTarget.open = false;
    this.element.
      querySelectorAll(".tw-paragraph").
      forEach((element) =>
        element.classList.toggle(
          "tw-selected",
          element.dataset.block === this.block
        )
      );
    this.responsive();
    const url = new URL(this.panelUrlValue, window.location.origin);
    Object.entries({
      block,
      mode,
      suggestion,
      sort: this.order,
      original: new URL(location.href).searchParams.get("original")
    }).forEach(([key, value]) => {
      if (value) {
        url.searchParams.set(key, value);
      }
    });
    try {
      const response = await fetch(url, {
        signal: abort.signal,
        headers: { "X-Requested-With": "XMLHttpRequest" }
      });
      if (!response.ok) {
        throw new Error(this.labelsValue.error);
      }
      const html = await response.text();
      if (abort.signal.aborted) {
        return;
      }
      this.panelTarget.innerHTML = html;
      this.panelTarget.removeAttribute("aria-busy");
      if (push) {
        this.setUrl(block, suggestion);
      }
      this.panelTarget.
        querySelector("[data-panel-title]")?.
        focus({ preventScroll: true });
      this.mountComments();
      this.panelTarget.querySelectorAll("[data-suggestion]").forEach((card) => {
        const source = this.previewSource(card.dataset.suggestion);
        const output = card.querySelector("[data-diff-output]");
        if (source && output && source.dataset.translated !== "true") {
          renderDiff(output, source.dataset.original, source.dataset.replacement, output.dataset.compact === "true");
        }
      });
      this.syncCounts();
      const editor = this.panelTarget.querySelector("[data-editor]");
      if (editor) {
        this.editor = editor;
        this.form = this.panelTarget.querySelector("[data-suggestion-form]");
        this.initialDraft = this.draftSignature();
        this.responsive();
        this.changed();
      } else if (mode === "suggestions") {
        const selected = this.panelTarget.querySelector("[data-detail-id]").dataset.detailId;
        const source = selected
          ? this.previewSource(selected)
          : this.panelTarget.querySelector('[data-preview-suggestion][data-pending="true"]');
        this.showPreview(source);
      }
    } catch (error) {
      if (error.name !== "AbortError") {
        const message = document.createElement("p");
        message.textContent = this.labelsValue.error;
        const closeButton = document.createElement("button");
        closeButton.type = "button";
        closeButton.textContent = this.labelsValue.close;
        closeButton.dataset.action = "textwork#close";
        this.panelTarget.replaceChildren(message, closeButton);
        closeButton.focus({ preventScroll: true });
        this.panelTarget.removeAttribute("aria-busy");
        this.statusTarget.textContent = this.labelsValue.error;
      }
    }
  }

  setUrl(block, suggestion) {
    const url = new URL(window.location.href);
    ["block", "suggestion"].forEach((key) => url.searchParams.delete(key));
    if (block) {
      url.searchParams.set("block", block);
    }
    if (suggestion) {
      url.searchParams.set("suggestion", suggestion);
    }
    url.hash = "";
    if (url.href !== window.location.href) {
      history.pushState({}, "", url);
    }
    this.lastUrl = url.href;
  }

  async close() {
    if (await this.confirmDiscard()) {
      await Promise.all(this.pendingCommentWrites);
      this.hide(true);
    }
  }
  hide(push) {
    this.abort?.abort();
    this.unmountComments();
    this.clearEditor();
    this.panelTarget.hidden = true;
    this.element.classList.remove("tw-is-open");
    this.element.
      querySelectorAll(".tw-selected").
      forEach((element) => element.classList.remove("tw-selected"));
    this.releaseBackground();
    this.tocTarget.open = !this.mobile.matches;
    if (push) {
      this.setUrl(null, null);
    }
    this.returnFocus?.focus({ preventScroll: true });
  }

  releaseBackground() {
    this.documentTarget.inert = false;
    this.tocTarget.inert = false;
    this.introTarget.inert = false;
    this.overlayTarget.hidden = true;
    this.panelTarget.removeAttribute("aria-modal");
  }

  responsive() {
    const modal = this.mobile.matches && !this.panelTarget.hidden;
    this.documentTarget.inert = modal;
    this.tocTarget.inert = modal;
    this.introTarget.inert = modal;
    this.overlayTarget.hidden = !modal;
    this.panelTarget.setAttribute("role", modal
      ? "dialog"
      : "complementary");
    if (modal) {
      this.panelTarget.setAttribute("aria-modal", "true");
    } else {
      this.panelTarget.removeAttribute("aria-modal");
    }
    if (!this.editor && this.previewId) {
      const preview = this.element.querySelector(`#block-${this.block} [data-preview]`);
      const valid = this.element.querySelector(`#block-${this.block} [data-valid-text]`);
      if (this.mobile.matches) {
        if (preview) {
          preview.hidden = true;
        }
        if (valid) {
          valid.hidden = false;
        }
      } else {
        this.showPreview(this.previewSource(this.previewId));
      }
    }
    if (this.editor) {
      const host = this.mobile.matches
        ? this.panelTarget.querySelector("[data-editor-home]")
        : this.element.querySelector(
          `#block-${this.block} [data-inline-editor]`
        );
      host?.append(this.editor);
      const valid = this.element.querySelector(
        `#block-${this.block} [data-valid-text]`
      );
      if (valid) {
        valid.hidden = !this.mobile.matches;
      }
    }
  }

  clearEditor() {
    this.editor?.remove();
    this.editor = null;
    this.previewId = null;
    this.form = null;
    this.dirty = false;
    this.element.querySelectorAll("[data-preview]").forEach((element) => {
      element.hidden = true;
      element.replaceChildren();
    });
    this.element.querySelectorAll("[data-valid-text]").forEach((element) => {
      element.hidden = false;
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
    renderDiff(
      this.editor.querySelector("[data-live-diff]"),
      this.editor.dataset.original,
      body
    );
    this.panelTarget.querySelector("[data-submit]").disabled =
      body.trim() === this.editor.dataset.original.trim() || !body.trim();
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
        headers: { Accept: "application/json" }
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || this.labelsValue.error);
      }
      this.dirty = false;
      await this.open(data.block, "suggestions", data.suggestion);
      this.statusTarget.textContent = data.message;
    } catch (error) {
      form.querySelector("[data-form-error]").textContent = error.message;
      button.disabled = false;
    }
  }

  async interact(event) {
    const button = event.currentTarget;
    if (!this.signedInValue) {
      this.loginTarget.click();
      return;
    }
    const authorization = button.closest("[data-resource]").querySelector(`[data-tw-authorize="${button.dataset.kind}"]`);
    if (authorization) {
      authorization.click();
      return;
    }
    const key = button.closest("[data-resource]").dataset.resource;
    const buttons = [
      ...this.element.querySelectorAll(
        `[data-resource="${key}"] button[data-kind="${button.dataset.kind}"]`
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
        headers: {
          "X-CSRF-Token":
            document.querySelector('meta[name="csrf-token"]')?.content || "",
          Accept: "application/json"
        }
      });
      if (!response.ok) {
        throw new Error();
      }
      const data = await response.json();
      this.element.
        querySelectorAll(`[data-resource="${data.key}"]`).
        forEach((resource) => {
          resource.querySelectorAll('[data-kind="like"]').forEach((item) => {
            item.setAttribute("aria-pressed", data.liked);
            item.querySelector("[data-interaction-label]").textContent =
              this.labelsValue[data.liked
                ? "liked"
                : "like"];
          });
          resource.querySelectorAll("[data-likes-count]").forEach((item) => {
            item.textContent = data.likes;
          });
          resource.querySelectorAll('[data-kind="follow"]').forEach((item) => {
            item.setAttribute("aria-pressed", data.followed);
            item.setAttribute(
              "aria-label",
              this.labelsValue[data.followed
                ? "followed"
                : "follow"]
            );
            item.title = item.getAttribute("aria-label");
          });
        });
    } catch {
      this.statusTarget.textContent = this.labelsValue.error;
    } finally {
      buttons.forEach((item) => {
        item.disabled = false;
      });
    }
  }

  mountComments() {
    this.panelTarget.
      querySelectorAll("[data-decidim-comments]").
      forEach((element) => {
        panelComments(element);
      });
    this.commentObserver?.disconnect();
    this.commentObserver = new MutationObserver(() => {
      if (this.commentFocusPending) {
        this.focusComment();
      }
      if (this.mode !== "comments") {
        return;
      }
      const counter = this.panelTarget.querySelector(".comments-count");
      if (counter) {
        this.element.querySelector(
          `[data-comment-count="${this.block}"]`
        ).textContent = Number(counter.textContent.match(/\d+/)?.[0]) || "";
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
  unmountComments() {
    this.commentFocusPending = false;
    this.commentObserver?.disconnect();
    this.panelTarget.
      querySelectorAll("[data-decidim-comments]").
      forEach((element) =>
        window.$(element).data("comments")?.unmountComponent()
      );
  }
  syncCounts() {
    const state = this.panelTarget.querySelector("[data-panel-block]");
    if (!state) {
      return;
    }
    ["comment", "suggestion"].forEach((kind) => {
      const element = this.element.querySelector(
        `[data-${kind}-count="${this.block}"]`
      );
      if (element) {
        element.textContent = Number(state.dataset[`${kind}Total`]) || "";
      }
    });
  }
  sort(event) {
    this.order = event.target.value;
    this.open(this.block, "suggestions");
  }
  previewSource(id) {
    return this.panelTarget.querySelector(`[data-preview-suggestion="${id}"]`);
  }
  preview(event) {
    this.showPreview(this.previewSource(event.currentTarget.dataset.previewId));
    this.element.querySelector(`#block-${this.block} .tw-preview-label`)?.focus();
  }
  showPreview(source) {
    if (!source) {
      return;
    }
    this.previewId = source.dataset.previewSuggestion;
    if (this.mobile.matches) {
      return;
    }
    const host = this.element.querySelector(`#block-${this.block} [data-preview]`);
    if (!host) {
      return;
    }
    const heading = document.createElement("div");
    heading.className = "tw-preview-heading";
    const title = document.createElement("p");
    title.className = "tw-preview-label";
    title.tabIndex = -1;
    title.textContent = source.dataset.label;
    heading.append(title);
    const diff = document.createElement("div");
    diff.className = "tw-diff";
    if (source.dataset.translated === "true") {
      diff.append(source.content.cloneNode(true));
    } else {
      renderDiff(diff, source.dataset.original, source.dataset.replacement);
    }
    const sources = [...this.panelTarget.querySelectorAll('[data-preview-suggestion][data-pending="true"]')];
    const position = sources.indexOf(source);
    if (position >= 0 && sources.length > 1) {
      heading.append(this.previewControls(sources, position));
    }
    host.replaceChildren(heading, diff);
    host.hidden = false;
    this.panelTarget.querySelectorAll("[data-preview-id]").forEach((button) => {
      const selected = button.dataset.previewId === this.previewId;
      button.hidden = selected;
      button.setAttribute("aria-pressed", selected);
    });
    this.panelTarget.querySelectorAll("[data-marked-id]").forEach((label) => {
      label.hidden = label.dataset.markedId !== this.previewId;
    });
    this.element.querySelector(`#block-${this.block} [data-valid-text]`).hidden = true;
  }
  previewControls(sources, position) {
    const controls = document.createElement("div");
    controls.className = "tw-preview-controls";
    [-1, 1].forEach((direction) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "button button__sm button__transparent-secondary tw-preview-arrow";
      button.setAttribute("aria-label", this.labelsValue[direction < 0
        ? "previous"
        : "next"]);
      const arrow = document.createElement("span");
      arrow.setAttribute("aria-hidden", "true");
      arrow.textContent = direction < 0
        ? "‹"
        : "›";
      button.append(arrow);
      button.disabled = position + direction < 0 || position + direction >= sources.length;
      button.addEventListener("click", (event) => {
        event.stopPropagation();
        const next = sources[position + direction];
        if (this.panelTarget.querySelector("[data-detail-id]").dataset.detailId) {
          this.open(this.block, "suggestions", next.dataset.previewSuggestion);
        } else {
          this.showPreview(next);
          const focus = this.element.querySelector(`[data-preview] button[aria-label="${button.getAttribute("aria-label")}"]:not([disabled])`) || this.element.querySelector("[data-preview] button:not([disabled])");
          focus?.focus({ preventScroll: true });
        }
      });
      controls.append(button);
    });
    return controls;
  }
  commentSuggestion() {
    if (!this.signedInValue) {
      this.loginTarget.click();
      return;
    }
    this.commentFocusPending = true;
    this.focusComment();
  }
  focusComment() {
    const field = this.panelTarget.querySelector("[data-decidim-comments] textarea:not([disabled])");
    if (field) {
      this.commentFocusPending = false;
      field.focus();
      field.scrollIntoView({ block: "center" });
    }
  }
  async withdraw(event) {
    const url = event.currentTarget.dataset.url;
    if (!(await this.confirmDiscard(true, true))) {
      return;
    }
    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token":
          document.querySelector('meta[name="csrf-token"]')?.content || "",
        Accept: "application/json"
      }
    });
    if (!response.ok) {
      this.statusTarget.textContent = this.labelsValue.error;
      return;
    }
    const data = await response.json();
    await this.open(data.block, "suggestions");
    this.statusTarget.textContent = data.message;
  }
  async copy() {
    try {
      await navigator.clipboard.writeText(window.location.href);
      this.statusTarget.textContent = this.labelsValue.copied;
    } catch {
      this.statusTarget.textContent = window.location.href;
    }
  }
  paragraph(event) {
    if (
      this.mobile.matches ||
      window.getSelection().toString() ||
      event.target.closest("a,button,input,textarea,select,label,[data-editor]")
    ) {
      return;
    }
    this.open(
      event.currentTarget.dataset.block,
      "comments",
      null,
      event.currentTarget.querySelector("a")
    );
  }
  chapter(event) {
    event.preventDefault();
    const target = this.element.querySelector(event.currentTarget.hash);
    target?.scrollIntoView({
      behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches
        ? "instant"
        : "smooth",
      block: "start"
    });
    target?.focus({ preventScroll: true });
  }
  observeChapters() {
    this.observer = new IntersectionObserver(
      (entries) =>
        entries.forEach((entry) => {
          if (!entry.isIntersecting) {
            return;
          }
          this.tocTarget.querySelectorAll("a").forEach((link) => {
            if (link.hash === `#${entry.target.id}`) {
              link.setAttribute("aria-current", "location");
            } else {
              link.removeAttribute("aria-current");
            }
          });
        }),
      { rootMargin: "-5% 0px -70% 0px" }
    );
    this.element.
      querySelectorAll(".tw-heading").
      forEach((heading) => this.observer.observe(heading));
  }
  keydown(event) {
    if (this.panelTarget.hidden || this.confirmTarget.open) {
      return;
    }
    const activeDialog = document.activeElement?.closest(
      '[role="dialog"],dialog[open]'
    );
    if (
      activeDialog &&
      activeDialog !== this.panelTarget &&
      !this.panelTarget.contains(activeDialog)
    ) {
      return;
    }
    if (event.key === "Escape") {
      event.preventDefault();
      this.close();
    }
    if (event.key === "Tab" && this.mobile.matches) {
      const elements = [
        ...this.panelTarget.querySelectorAll(
          'a[href],button:not([disabled]),textarea,input,select,[tabindex="0"]'
        )
      ].filter((item) => item.getClientRects().length);
      const first = elements[0],
          last = elements.at(-1);
      if (
        event.shiftKey &&
        (document.activeElement === first ||
          !elements.includes(document.activeElement))
      ) {
        event.preventDefault();
        last?.focus();
      } else if (!event.shiftKey && (document.activeElement === last || !elements.includes(document.activeElement))) {
        event.preventDefault();
        first?.focus();
      }
    }
  }
}
