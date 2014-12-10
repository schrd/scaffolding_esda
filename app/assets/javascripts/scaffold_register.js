jQuery.noConflict();
jQuery(document).ready( function($) {
  $(document).registerModifications();
  $(".content input:first").focus();
  $(document).on("keyup", "table.cellnav", tableCellNavigation);
  $(document).on("click", ".livegrid a.searchbutton", function(event) {
    findLiveGridAround(this).grid.search();
  });
});

