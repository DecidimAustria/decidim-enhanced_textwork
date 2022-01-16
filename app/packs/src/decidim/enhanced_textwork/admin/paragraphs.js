/* eslint-disable no-invalid-this */
/* eslint no-unused-vars: 0 */
/* eslint id-length: ["error", { "exceptions": ["e"] }] */

$(() => {
  const selectedParagraphsCount = function() {
    return $(".table-list .js-check-all-paragraph:checked").length
  }

  const selectedParagraphsNotPublishedAnswerCount = function() {
    return $(".table-list [data-published-state=false] .js-check-all-paragraph:checked").length
  }

  const selectedParagraphsCountUpdate = function() {
    const selectedParagraphs = selectedParagraphsCount();
    const selectedParagraphsNotPublishedAnswer = selectedParagraphsNotPublishedAnswerCount();
    if (selectedParagraphs === 0) {
      $("#js-selected-paragraphs-count").text("")
    } else {
      $("#js-selected-paragraphs-count").text(selectedParagraphs);
    }

    if (selectedParagraphs >= 2) {
      $('button[data-action="merge-paragraphs"]').parent().show();
    } else {
      $('button[data-action="merge-paragraphs"]').parent().hide();
    }

    if (selectedParagraphsNotPublishedAnswer > 0) {
      $('button[data-action="publish-answers"]').parent().show();
      $("#js-form-publish-answers-number").text(selectedParagraphsNotPublishedAnswer);
    } else {
      $('button[data-action="publish-answers"]').parent().hide();
    }
  }

  const showBulkActionsButton = function() {
    if (selectedParagraphsCount() > 0) {
      $("#js-bulk-actions-button").removeClass("hide");
    }
  }

  const hideBulkActionsButton = function(force = false) {
    if (selectedParagraphsCount() === 0 || force === true) {
      $("#js-bulk-actions-button").addClass("hide");
      $("#js-bulk-actions-dropdown").removeClass("is-open");
    }
  }

  const showOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").removeClass("hide");
  }

  const hideOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").addClass("hide");
  }

  const hideBulkActionForms = function() {
    $(".js-bulk-action-form").addClass("hide");
  }

  // Expose functions to make them avaialble in .js.erb templates
  window.selectedParagraphsCount = selectedParagraphsCount;
  window.selectedParagraphsNotPublishedAnswerCount = selectedParagraphsNotPublishedAnswerCount;
  window.selectedParagraphsCountUpdate = selectedParagraphsCountUpdate;
  window.showBulkActionsButton = showBulkActionsButton;
  window.hideBulkActionsButton = hideBulkActionsButton;
  window.showOtherActionsButtons = showOtherActionsButtons;
  window.hideOtherActionsButtons = hideOtherActionsButtons;
  window.hideBulkActionForms = hideBulkActionForms;

  if ($(".js-bulk-action-form").length) {
    hideBulkActionForms();
    $("#js-bulk-actions-button").addClass("hide");

    $("#js-bulk-actions-dropdown ul li button").click(function(e) {
      e.preventDefault();
      let action = $(e.target).data("action");

      if (action) {
        $(`#js-form-${action}`).submit(function() {
          $(".layout-content > .callout-wrapper").html("");
        })

        $(`#js-${action}-actions`).removeClass("hide");
        hideBulkActionsButton(true);
        hideOtherActionsButtons();
      }
    })

    // select all checkboxes
    $(".js-check-all").change(function() {
      $(".js-check-all-paragraph").prop("checked", $(this).prop("checked"));

      if ($(this).prop("checked")) {
        $(".js-check-all-paragraph").closest("tr").addClass("selected");
        showBulkActionsButton();
      } else {
        $(".js-check-all-paragraph").closest("tr").removeClass("selected");
        hideBulkActionsButton();
      }

      selectedParagraphsCountUpdate();
    });

    // paragraph checkbox change
    $(".table-list").on("change", ".js-check-all-paragraph", function (e) {
      let paragraphId = $(this).val()
      let checked = $(this).prop("checked")

      // uncheck "select all", if one of the listed checkbox item is unchecked
      if ($(this).prop("checked") === false) {
        $(".js-check-all").prop("checked", false);
      }
      // check "select all" if all checkbox paragraphs are checked
      if ($(".js-check-all-paragraph:checked").length === $(".js-check-all-paragraph").length) {
        $(".js-check-all").prop("checked", true);
        showBulkActionsButton();
      }

      if ($(this).prop("checked")) {
        showBulkActionsButton();
        $(this).closest("tr").addClass("selected");
      } else {
        hideBulkActionsButton();
        $(this).closest("tr").removeClass("selected");
      }

      if ($(".js-check-all-paragraph:checked").length === 0) {
        hideBulkActionsButton();
      }

      $(".js-bulk-action-form").find(`.js-paragraph-id-${paragraphId}`).prop("checked", checked);
      selectedParagraphsCountUpdate();
    });

    $(".js-cancel-bulk-action").on("click", function (e) {
      hideBulkActionForms()
      showBulkActionsButton();
      showOtherActionsButtons();
    });
  }
});
