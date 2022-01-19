import "src/decidim/enhanced_textwork/utils"
import "src/decidim/enhanced_textwork/add_paragraph"
import "src/decidim/enhanced_textwork/toggle_element.js"

// Images
require.context("../images", true)

// Documents
require.context("../documents", true)

// Add proposals-overview class to elements with the class "off-canvas-wrapper"
$(() => {
  var elements = document.getElementsByClassName("off-canvas-wrapper");
  for (let element of elements) {
    element.classList.add("paragraphs-overview");
  }
});
