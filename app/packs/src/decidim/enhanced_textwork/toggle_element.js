$(() => {
  const $showButton = $("[data-toggle='show']")
  const $hideButton = $("[data-toggle='hide']")
  const $toggleElements = $(".toggle--hidden:not(button)")

  $showButton.on("click", (e) => {
    e.preventDefault()
    $toggleElements.removeClass("toggle--hidden")

    $hideButton.removeClass("toggle--hidden")
    $(e.target).addClass("toggle--hidden")
  })

  $hideButton.on("click", (e) => {
    e.preventDefault()
    $toggleElements.addClass("toggle--hidden")

    $showButton.removeClass("toggle--hidden")
    $(e.target).addClass("toggle--hidden")
  })
});
