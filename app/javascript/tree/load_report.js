(function() {
  var replaceDates, loadHtml, linkNames, linkSynonyms, linkName, loadReport;

  // "just now", "5 minutes ago", "Yesterday", "3 weeks ago", "1 year and 2
  // months ago"... Ported from jquery-dateformat's prettyDate, with the same
  // wording, so that plugin no longer has to be loaded.
  function prettyDate(value) {
    var date = new Date(value);
    var now = new Date();
    var seconds = (now.getTime() - date.getTime()) / 1000;
    var abs = Math.abs(seconds);
    var days = Math.floor(abs / 86400);
    if (isNaN(days)) return undefined;

    var totalMonths = Math.abs(12 * (date.getFullYear() - now.getFullYear()) +
                               (date.getMonth() - now.getMonth()));
    var years = Math.floor(totalMonths / 12);
    var months = totalMonths % 12;
    var suffix = seconds < 0 ? " from now" : " ago";
    var count = function (unit, n) { return n > 1 ? n + unit + "s" : n + unit; };

    if (abs < 60) return seconds >= 0 ? "just now" : "in a moment";
    if (abs < 120) return "1 minute" + suffix;
    if (abs < 3600) return Math.floor(abs / 60) + " minutes" + suffix;
    if (abs < 7200) return "1 hour" + suffix;
    if (abs < 86400) return Math.floor(abs / 3600) + " hours" + suffix;
    if (days === 1) return seconds >= 0 ? "Yesterday" : "Tomorrow";
    if (days < 7) return days + " days" + suffix;
    if (days === 7) return "1 week" + suffix;
    if (days < 31) return Math.ceil(days / 7) + " weeks" + suffix;
    if (years === 0) return count(" month", months) + suffix;
    if (months > 0) return count(" year", years) + " and " + count(" month", months) + suffix;
    return count(" year", years) + suffix;
  }

  function replaceDates() {
    document.querySelectorAll("date").forEach(function (element) {
      var pretty = prettyDate(element.textContent);
      if (pretty !== undefined) element.textContent = pretty;
    });
  }
  
  window.replaceDates = replaceDates;
  
  function loadHtml(element, url, success) {
    debug("loadHtml into element");
    console.log(JSON.stringify(element));
    if (success == null) {
      success = function (data) {
        element.html(data);
        replaceDates();
      }
    }
    $.ajax({
      url: url,
      contentType: "text/html",
      beforeSend: function (jqXHR, settings) {
        jqXHR.setRequestHeader("Accept", "text/html");
      },
      complete: function (jqXHR, textStatus) {
        debug(textStatus);
      },
      success: success,
      error: function (jqXHR) {
        element.html("Data not available.")
      }
    });
  }
  
  function linkNames(selector) {
    var container = $(selector);
    container.find('data > scientific > name').each(function () {
      linkName(this)
    });
  }
  
  window.linkNames = linkNames;
  
  function linkSynonyms(selector) {
    var container = $(selector);
    container.find('nom > scientific > name').each(function () {
      linkName(this)
    });
    container.find('tax > scientific > name').each(function () {
      linkName(this)
    });
    container.find('mis > scientific > name').each(function () {
      linkName(this)
    });
    container.find('syn > scientific > name').each(function () {
      linkName(this)
    });
  }
  
  function linkName(name) {
    var name_id = $(name).data('id');
    var search_url = window.relative_url_root + '/search?query_string=id%3A+' + name_id + '+show-instances%3A&query_target=name';
    $(name).wrap('<a href="' + search_url + '" title="search" target="_blank">');
  }
  
  function loadReport(element, url) {
    element.html('<h2>Loading <i class="fa fa-refresh fa-spin"</h2>');
    loadHtml(element, url, function (data) {
      element.html(data);
      replaceDates();
      linkNames(element);
      linkSynonyms(element);
      $('.toggleNext').unbind('click').click(function () {
        toggleNext(this);
      });
      debug('loaded report.');
      $(this).find('i').removeClass('fa-spin');
    });
  }
  
  window.loadReport = loadReport;
  
  var toggleNext = function (el) {
    $(el).find('i').toggle();
    $(el).next('div').toggle(200);
  };
  
  window.toggleNext = toggleNext;
  
}).call(this);
  
  
