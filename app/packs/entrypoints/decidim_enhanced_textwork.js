import "stylesheets/decidim/enhanced_textwork.scss";
import TextworkController from "src/decidim/textwork/controller";
const register = () => {
  if (window.Stimulus) {
    window.Stimulus.register("textwork", TextworkController);
  }
};
if (window.Stimulus) {
  register();
} else {
  document.addEventListener("DOMContentLoaded", register, { once: true });
}
