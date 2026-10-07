// Images keep their native dimensions; the enlarged view always uses the blob.
export const resizeReadingImage = (image) => {
  if (!image.complete || !image.naturalWidth) {
    return;
  }
  const displayed = image.getBoundingClientRect();
  image.closest(".tw-image").querySelector("button").hidden =
    displayed.width >= image.naturalWidth - 1 &&
    displayed.height >= image.naturalHeight - 1;
};

export const showImage = (dialog, trigger) => {
  const image = dialog.querySelector("img");
  image.src = trigger.dataset.imageUrl;
  image.alt = trigger.dataset.imageAlt || "";
  dialog.showModal();
  dialog.querySelector("button").focus();
};

export const hideImage = (dialog, trigger) => {
  dialog.close();
  dialog.querySelector("img").removeAttribute("src");
  trigger?.focus({ preventScroll: true });
};
