// Scoped lifecycle adapter for the unchanged Decidim 0.32 comment views/forms.
// Core's GET requests are not cancellable through unmountComponent and its sort
// handlers use document-wide selectors. Keep these two concerns local to a panel;
// no Core prototype or global handler is changed.
// Core endpoint query keys deliberately retain Rails naming.
/* eslint camelcase: ["error", {"allow": ["commentable_gid", "root_depth", "toggle_translations"]}] */
export const panelComments = (element) => {
  class PanelComments extends window.Decidim.CommentsComponent {
    _fetchComments(callback = null) {
      this.pendingRead?.abort();
      window.Rails.ajax({
        url: this.commentsUrl,
        type: "GET",
        data: new URLSearchParams({
          commentable_gid: this.commentableGid,
          root_depth: this.rootDepth,
          order: this.order,
          ...(this.toggleTranslations && {
            toggle_translations: this.toggleTranslations
          })
        }),
        beforeSend: (xhr) => {
          this.pendingRead = xhr;
          return true;
        },
        success: () => {
          if (this.mounted) {
            return callback?.();
          }
          return null;
        }
      });
    }
    _initializeSortDropdown() {
      this.sortListeners = [];
      this.$element[0].
        querySelectorAll(
          "[data-desktop-order-comment-select],[data-mobile-order-comment-select]"
        ).
        forEach((select) => {
          const handler = () => {
            this.order = select.value;
            this.reloadAllComments();
          };
          select.addEventListener("change", handler);
          this.sortListeners.push([select, handler]);
        });
    }
    unmountComponent() {
      this.pendingRead?.abort();
      this.sortListeners?.forEach(([select, handler]) =>
        select.removeEventListener("change", handler)
      );
      super.unmountComponent();
    }
  }
  const wrapped = window.$(element);
  const instance = new PanelComments(wrapped, wrapped.data("decidim-comments"));
  wrapped.data("comments", instance);
  instance.mountComponent();
  return instance;
};
