jQuery(document).ready(function($) {
	$(document).on("dblclick", ".editable", function(event) {
		var div = $(this);
		var form_url = div.data("form-url");
		var update_url = div.data("update-url");
		var show_url = div.data("show-url");
		var old_html = div.html();
		var form = $('<div class="editableform"><div class="element"></div><a class="ok button">Ok</a><a class="cancel button">Cancel</a></div>');

		div.html(form);
		form.find(".element").load(form_url, function() {
			form.find(".ok").click(function(event) {
				values = form.find(":input").serialize();
				$.post(update_url, values, function(data) {
					div.html(data);
				});
			});
			form.find(".cancel").click(function(event) {
				div.html(old_html);
			});
			form.registerModifications();
		});
		console.log(this, event);
	});
});
