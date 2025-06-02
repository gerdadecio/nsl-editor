let pendingHref = null;

function getFormState(form) {
  const formData = new FormData(form);
  return JSON.stringify(Array.from(formData.entries()));
}

function setInitialFormState(form) {
  form.dataset.initialState = getFormState(form);
}

function hasFormChanged(form) {
  return getFormState(form) !== form.dataset.initialState;
}

window.renderFormPrompt = function() {
  const forms = document.querySelectorAll("form.prompt-form-save");
  forms.forEach(form => {
    setInitialFormState(form);

    form.addEventListener("input", () => {
      form.dataset.changed = hasFormChanged(form);
    });

    form.addEventListener("change", () => {
      form.dataset.changed = hasFormChanged(form);
    });

    form.addEventListener("submit", () => {
      if (hasFormChanged(form)) {
        event.preventDefault();
        const submitMsg = "Are you sure you want to submit? This action will save your changes.";
        if (window.showUnsavedChangesModal) {
          window.showUnsavedChangesModal(() => {
            form.dataset.changed = "false";
            setInitialFormState(form);
            form.requestSubmit ? form.requestSubmit() : form.submit();
          }, submitMsg);
        } else if (confirm(submitMsg)) {
          form.dataset.changed = "false";
          setInitialFormState(form);
          form.requestSubmit ? form.requestSubmit() : form.submit();
        }
        return false;
      }
      form.dataset.changed = "false";
      setInitialFormState(form);
    });
  });

  const modal = document.getElementById('unsaved-changes-modal');
  const continueBtn = document.getElementById('unsaved-continue');
  const backBtn = document.getElementById('unsaved-back');

  document.querySelectorAll('a.tab').forEach(tab => {
    tab.addEventListener('click', event => {
      if (hasUnsavedFormChanges()) {
        event.preventDefault();
        pendingHref = tab.getAttribute('href');
        if (modal) modal.style.display = 'flex';
      }
    });
  });

  if (continueBtn) {
    continueBtn.onclick = () => {
      if (modal) modal.style.display = 'none';
      if (pendingHref) {
        window.location.href = pendingHref;
        pendingHref = null;
      }
    };
  }

  if (backBtn) {
    backBtn.onclick = () => {
      if (modal) modal.style.display = 'none';
      pendingHref = null;
    };
  }
}

window.showUnsavedChangesModal = function(onContinue, message) {
  const modal = document.getElementById('unsaved-changes-modal');
  const continueBtn = document.getElementById('unsaved-continue');
  const backBtn = document.getElementById('unsaved-back');
  const messageElem = document.getElementById('unsaved-changes-message');
  if (modal) modal.style.display = 'flex';
  if (messageElem && message) messageElem.textContent = message;

  if (continueBtn) {
    continueBtn.onclick = () => {
      modal.style.display = 'none';
      if (messageElem) messageElem.textContent = "You have unsaved changes. Continue?"; // reset
      if (onContinue) onContinue();
    };
  }
  if (backBtn) {
    backBtn.onclick = () => {
      modal.style.display = 'none';
      if (messageElem) messageElem.textContent = "You have unsaved changes. Continue?"; // reset
    };
  }
}

window.hasUnsavedFormChanges = function() {
  return Array.from(document.querySelectorAll("form.prompt-form-save"))
    .some(form => hasFormChanged(form));
}
