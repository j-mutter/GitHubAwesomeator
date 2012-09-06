// Saves options to localStorage.
function save_options() {
  var select = document.getElementById("gitfolder");
  var gitfolderValue = select.value;
  localStorage["gitfolder"] = gitfolderValue;
  // Update status to let user know options were saved.
  var status = document.getElementById("status");
  status.innerHTML = "Options Saved.";
  setTimeout(function() {
    status.innerHTML = "";
  }, 750);
}
// Restores select box state to saved value from localStorage.
function restore_options() {
  var gitfolderValue = localStorage["gitfolder"];
  if (!gitfolderValue) {
    return;
  }
  var select = document.getElementById("gitfolder");
  select.value = gitfolderValue;

}

function saveHandler(e) {
  setTimeout(save_options, 1);
}

function loadHandler(e) {
  setTimeout(restore_options, 1);
}


document.addEventListener('DOMContentLoaded', function () {
  document.getElementById('save').addEventListener('click', saveHandler);
});

document.addEventListener('DOMContentLoaded', function () {
  loadHandler();
});