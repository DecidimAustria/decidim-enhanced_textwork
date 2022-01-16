$(() => {
  const $content = $(".picker-content"),
      pickerMore = $content.data("picker-more"),
      pickerPath = $content.data("picker-path"),
      toggleNoParagraphs = () => {
        const showNoParagraphs = $("#paragraphs_list li:visible").length === 0
        $("#no_paragraphs").toggle(showNoParagraphs)
      }

  let jqxhr = null

  toggleNoParagraphs()

  $(".data_picker-modal-content").on("change keyup", "#paragraphs_filter", (event) => {
    const filter = event.target.value.toLowerCase()

    if (pickerMore) {
      if (jqxhr !== null) {
        jqxhr.abort()
      }

      $content.html("<div class='loading-spinner'></div>")
      jqxhr = $.get(`${pickerPath}?q=${filter}`, (data) => {
        $content.html(data)
        jqxhr = null
        toggleNoParagraphs()
      })
    } else {
      $("#paragraphs_list li").each((index, li) => {
        $(li).toggle(li.textContent.toLowerCase().indexOf(filter) > -1)
      })
      toggleNoParagraphs()
    }
  })
})
