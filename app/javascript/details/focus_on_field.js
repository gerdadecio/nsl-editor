
(function() {
  var focusOnField;

  focusOnField = function(field_id) {
    let field = document.getElementById(field_id);
      //if (field) {
        field.focus()
      //};
  };
  window.focusOnField = focusOnField;

}).call(this);
