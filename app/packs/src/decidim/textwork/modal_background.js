// Preserve pre-existing inert states while blocking every branch outside the
// active sheet, including the site's header, breadcrumbs and footer.
export class ModalBackground {
  constructor(onChange) {
    this.original = new Map();
    this.dialogHandler = (event) => {
      if (!this.original.size) {
        return;
      }
      this.dialog = event.type === "open.dialog"
        ? event.target
        : null;
      onChange(true);
    };
    document.addEventListener("open.dialog", this.dialogHandler, true);
    document.addEventListener("close.dialog", this.dialogHandler, true);
    this.observer = new MutationObserver(() => onChange(false));
    this.observer.observe(document.body, { childList: true });
  }

  activate(target, exceptions = []) {
    this.release();
    let branch = target;
    while (branch && branch !== document.body) {
      for (const sibling of branch.parentElement.children) {
        if (sibling !== branch && !exceptions.includes(sibling)) {
          this.original.set(sibling, sibling.inert);
          sibling.inert = true;
        }
      }
      branch = branch.parentElement;
    }
  }

  update(target, modal, exceptions) {
    if (this.dialog && (!this.dialog.isConnected || this.dialog.getAttribute("aria-hidden") !== "false")) {
      this.dialog = null;
    }
    if (modal) {
      this.activate(this.dialog || target, exceptions);
    } else {
      this.release();
    }
  }

  release() {
    this.original.forEach((inert, element) => {
      element.inert = inert;
    });
    this.original.clear();
  }

  disconnect() {
    document.removeEventListener("open.dialog", this.dialogHandler, true);
    document.removeEventListener("close.dialog", this.dialogHandler, true);
    this.observer.disconnect();
    this.release();
  }
}
