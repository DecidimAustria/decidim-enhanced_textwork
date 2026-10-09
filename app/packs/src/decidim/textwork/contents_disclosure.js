// Native details keeps its toggle/keyboard semantics. Add light-dismiss behavior
// without swallowing the outside click or moving focus away from its destination.
export const contentsDisclosure = (contents) => {
  const outside = (event) => {
    if (!contents.contains(event.target)) {
      contents.open = false;
    }
  };
  const escape = (event) => {
    if (event.key !== "Escape" || !contents.open) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    const restoreFocus = contents.contains(document.activeElement);
    contents.open = false;
    if (restoreFocus) {
      contents.querySelector("summary").focus();
    }
  };
  document.addEventListener("click", outside, true);
  document.addEventListener("focusin", outside);
  document.addEventListener("keydown", escape, true);
  return () => {
    document.removeEventListener("click", outside, true);
    document.removeEventListener("focusin", outside);
    document.removeEventListener("keydown", escape, true);
  };
};

export const contentsChapter = (event, contents) => {
  event.preventDefault();
  const chapter = document.querySelector(event.currentTarget.getAttribute("href"));
  contents.open = false;
  chapter?.scrollIntoView({ block: "start" });
  chapter?.focus({ preventScroll: true });
};
