import attachGeocoding from "src/decidim/geocoding/attach_input"

$(() => {
  const $form = $(".paragraph_form_admin");

  if ($form.length > 0) {
    const $paragraphCreatedInMeeting = $form.find("#paragraph_created_in_meeting");
    const $paragraphMeeting = $form.find("#paragraph_meeting");

    const toggleDisabledHiddenFields = () => {
      const enabledMeeting = $paragraphCreatedInMeeting.prop("checked");
      $paragraphMeeting.find("select").attr("disabled", "disabled");
      $paragraphMeeting.hide();

      if (enabledMeeting) {
        $paragraphMeeting.find("select").attr("disabled", !enabledMeeting);
        $paragraphMeeting.show();
      }
    };

    $paragraphCreatedInMeeting.on("change", toggleDisabledHiddenFields);
    toggleDisabledHiddenFields();

    const $paragraphAddress = $form.find("#paragraph_address");
    if ($paragraphAddress.length !== 0) {
      attachGeocoding($paragraphAddress);
    }
  }
});
