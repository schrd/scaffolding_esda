jQuery(document).ready(function($) {
  $(document).on("submit", 'body[data-action="versand"] #lieferscheinauswahl form', function(event) {
    var action = $(this).attr("action");
    $("#lieferscheinauswahl").load(action, $(this).serialize(), function() {
      $('#lieferscheinauswahl').registerModifications();
    });
  });
});
