(function () {
  var refreshPageLinkClick;

  $(document).on("turbo:load", function () {
    $("body").on("click", "#refresh-page-from-details-link", function (event) {
      return refreshPageLinkClick(event, $(this));
    });
    $("body").on("click", ".refresh-page-link", function (event) {
      return refreshPageLinkClick(event, $(this));
    });
  });

  refreshPageLinkClick = function (event, $element) {
    var data = $element.data();
    var paramMapping = {
      id: "id",
      showProfiles: "show_profiles",
      focusId: "focus_id",
      queryTarget: "query_target"
    };
    var hasParams = Object.keys(paramMapping).some(function (key) {
      return data[key] !== undefined;
    });

    if (hasParams) {
      var url = new URL(window.location.href);
      Object.keys(paramMapping).forEach(function (dataKey) {
        if (data[dataKey] !== undefined) {
          url.searchParams.set(paramMapping[dataKey], data[dataKey]);
        }
      });
      window.location.href = url.toString();
    } else {
      location.reload();
    }
  };
}).call(this);
