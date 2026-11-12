// Copilot-authored: Begin video library filters.
(function () {
  function initializeVideoLibrary() {
    var library = document.querySelector("[data-video-library]");
    if (!library || library.dataset.initialized) return;

    library.dataset.initialized = "true";

    var search = library.querySelector("[data-video-search]");
    var channelFilter = library.querySelector("[data-channel-filter]");
    var watchedFilter = library.querySelector("[data-watched-filter]");
    var cards = Array.prototype.slice.call(library.querySelectorAll("[data-video-card]"));

    function updateResults() {
      var query = search.value.trim().toLocaleLowerCase();
      var channel = channelFilter.value.toLocaleLowerCase();
      var watched = watchedFilter.value;

      cards.forEach(function (card) {
        var matchesQuery = !query ||
          card.dataset.title.indexOf(query) !== -1 ||
          card.dataset.channel.indexOf(query) !== -1;
        var matchesChannel = !channel || card.dataset.channel === channel;
        var matchesWatched = watched === "all" ||
          (watched === "watched" && card.dataset.watched === "true") ||
          (watched === "unwatched" && card.dataset.watched === "false");
        var isVisible = matchesQuery && matchesChannel && matchesWatched;

        card.hidden = !isVisible;
      });
    }

    function saveFilters() {
      var token = document.querySelector('meta[name="csrf-token"]');
      var body = new URLSearchParams();
      body.set("channel", channelFilter.value);
      body.set("watched", watchedFilter.value);

      fetch(library.dataset.saveFilterUrl, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
          "X-CSRF-Token": token ? token.content : ""
        },
        body: body.toString()
      }).then(function (response) {
        if (!response.ok) throw new Error("Unable to save video filters.");
      }).catch(function (error) {
        console.error(error);
      });
    }

    search.addEventListener("input", updateResults);
    channelFilter.addEventListener("change", function () {
      updateResults();
      saveFilters();
    });
    watchedFilter.addEventListener("change", function () {
      updateResults();
      saveFilters();
    });

    updateResults();
  }

  document.addEventListener("turbolinks:load", initializeVideoLibrary);
  document.addEventListener("DOMContentLoaded", initializeVideoLibrary);
})();
// Copilot-authored: End video library filters.
