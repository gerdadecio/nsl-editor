(function() {
  var showResourceEditForm, hideResourceEditForm, saveResourceEdit;
  var showAddResourceForm, hideAddResourceForm, saveNewResource;

  $(document).on("turbo:load", function() {

    // Show edit form when clicking Edit button
    $('body').on('click', 'a.show-resource-edit-form', function(event) {
      return showResourceEditForm(event, $(this));
    });

    // Cancel edit form
    $('body').on('click', 'a.cancel-resource-edit-btn', function(event) {
      return hideResourceEditForm(event, $(this));
    });

    // Save resource edit
    $('body').on('click', 'a.save-resource-btn', function(event) {
      return saveResourceEdit(event, $(this));
    });

    // Show add resource form when clicking Add Resource button
    $('body').on('click', '#add-resource-button', function(event) {
      return showAddResourceForm(event, $(this));
    });

    // Cancel adding new resource
    $('body').on('click', '#cancel-new-resource-btn', function(event) {
      return hideAddResourceForm(event);
    });

    // Save new resource
    $('body').on('click', '#save-new-resource-btn', function(event) {
      return saveNewResource(event);
    });

  });

  showResourceEditForm = function(event, $element) {
    debug('showResourceEditForm');
    const targetId = $element.data('target-id');
    const displayId = $element.data('display-id');

    // Hide the display view
    $(`#${displayId}`).addClass('hidden');

    // Show the edit form
    $(`#${targetId}`).removeClass('hidden');

    $('.message-container').html('');
    return event.preventDefault();
  };

  hideResourceEditForm = function(event, $element) {
    debug('hideResourceEditForm');
    const targetId = $element.data('target-id');
    const displayId = $element.data('display-id');

    // Hide the edit form
    $(`#${targetId}`).addClass('hidden');

    // Show the display view
    $(`#${displayId}`).removeClass('hidden');

    $('.message-container').html('');
    $('.error-container').html('');
    return event.preventDefault();
  };

  saveResourceEdit = function(event, $element) {
    debug('saveResourceEdit');
    const targetId = $element.data('target-id');
    const displayId = $element.data('display-id');

    // TODO: Add AJAX call to save the resource data here
    // For now, just hide the form and show the display

    // Hide the edit form
    $(`#${targetId}`).addClass('hidden');

    // Show the display view
    $(`#${displayId}`).removeClass('hidden');

    // Show success message
    $('#search-result-details-info-message-container').html('Resource updated successfully');

    return event.preventDefault();
  };

  showAddResourceForm = function(event, $element) {
    debug('showAddResourceForm');

    // Get selected resource type from dropdown
    const selectedResourceId = $('#resource-type-select').val();
    const selectedResourceText = $('#resource-type-select option:selected').text();

    // Validate selection
    if (!selectedResourceId) {
      $('#search-result-details-error-message-container').html('Please select a resource type first');
      return event.preventDefault();
    }

    // Populate the form fields
    $('#new-resource-host').val(selectedResourceText);
    $('#new-resource-host').data('resource-host-id', selectedResourceId);

    // Set the hidden resource_host_id field for form submission
    $('#resource-host-id-hidden').val(selectedResourceId);

    // Get the resolving URL from the selected option's data attribute
    const resolvingUrl = $('#resource-type-select option:selected').data('resolving-url') || '';
    $('#new-resource-url').val(resolvingUrl);

    // Clear previous values
    $('#new-resource-value').val('');
    $('#new-resource-note').val('');

    // Hide the dropdown and button
    $('.add-resource-form').addClass('hidden');

    // Show the add form
    $('#add-resource-form-container').removeClass('hidden');

    // Focus on the value field
    $('#new-resource-value').focus();

    // Clear messages
    $('.message-container').html('');

    return event.preventDefault();
  };

  hideAddResourceForm = function(event) {
    debug('hideAddResourceForm');

    // Hide the add form
    $('#add-resource-form-container').addClass('hidden');

    // Show the dropdown and button again
    $('.add-resource-form').removeClass('hidden');

    // Clear form fields
    $('#new-resource-host').val('');
    $('#new-resource-value').val('');
    $('#new-resource-note').val('');
    $('#new-resource-url').val('');

    // Clear messages
    $('.message-container').html('');

    return event.preventDefault();
  };

  saveNewResource = function(event) {
    debug('saveNewResource');

    const resourceValue = $('#new-resource-value').val();
    if (!resourceValue) {
      $('#search-result-details-error-message-container').html('Resource value is required');
      return event.preventDefault();
    }
  };

}).call(this);
