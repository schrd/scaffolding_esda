function tableCellNavigation(evt) {
	//alert(evt.target);
	if (evt.keyCode < 37 || evt.keyCode > 40) {
		return;
	}
	// from here only cursor keys are relevant
	var field = evt.target;
	if (field.tagName != 'INPUT' && field.tagName != 'SELECT') {
		return;
	}
	var cell = field.parentNode;
	while (cell != null && (cell.tagName != 'TD' && cell.tagName != 'TH')) {
		cell = cell.parentNode;
	}
	var row = cell.parentNode;
	while (row != null && row.tagName != 'TR') {
		row = row.parentNode;
	}
	if (evt.keyCode==37) { // left
		if (field.selectionStart==0) {
			// find input element that is left of this one
			for (var i=cell.cellIndex-1; i >= 0; i--) {
				var newcell = row.cells[i];
				//var newinputs = newcell.getElementsByTagName('INPUT');
				var newinputs = findInputsBelow(newcell);
				if (newinputs.length > 0) {
					var newinput = newinputs[newinputs.length - 1];
					newinput.focus();
					evt.preventDefault();
					newinput.select();
					return;
				}
			}
		}
	}
	
	if (evt.keyCode==39) { // right
		if (field.selectionEnd==field.value.length) {
			// find input element that is left of this one
			for (var i=cell.cellIndex+1; i < row.cells.length; i++) {
				var newcell = row.cells[i];
				//var newinputs = newcell.getElementsByTagName('INPUT');
				var newinputs = findInputsBelow(newcell);
				if (newinputs.length > 0) {
					var newinput = newinputs[0];
					newinput.focus();
					evt.preventDefault();
					newinput.setSelectionRange(0, newinput.value.length);
					return;
				}
			}
		}
	}
	
	if (evt.keyCode==40 || evt.keyCode==38) { // down
		// find element that is below this one
		var move = 1;
		if (evt.keyCode==38) {
			move = -1;
		}
		evt.preventDefault();
		var cellIdx = cellIndexInRow(cell);
		//alert(cellIdx);
		var table = row.parentNode;
		while (table != null && table.tagName.toUpperCase() != 'TABLE') {
			table = table.parentNode;
		}
		//var newcell = table.rows[row.rowIndex+1].cells[cellIdx];
		for (var i = row.rowIndex+move; i >= 0 && i < table.rows.length; i = i + move) {
		var newcell = find_cell_idx_in_row(table.rows[i], cellIdx);
		//var newinputs = newcell.getElementsByTagName('INPUT');
		var newinputs = findInputsBelow(newcell);
		if (newinputs.length > 0) {
			newinputs[0].focus();
			newinputs[0].select();
			evt.preventDefault();
			return;
		}
		}

	}
	
}

function findInputsBelow(n) {
	var newinputs = new Array();
	var tw = document.createTreeWalker(n, NodeFilter.SHOW_ELEMENT, {
		acceptNode: function(node) { 
			if (node.tagName.toUpperCase() =='SELECT' || (node.tagName.toUpperCase() =='INPUT' && node.getAttribute('type').toUpperCase() == 'TEXT')) {
				return NodeFilter.FILTER_ACCEPT; 
			} else {
				return NodeFilter.FILTER_SKIP;
			}
		}
	}, false);
	while(tw.nextNode()) newinputs.push(tw.currentNode);
	return newinputs;
}

function cellIndexInRow(cell) {
	var row = cell.parentNode;
	var start=0;
	for (var i=0; i < cell.cellIndex; i++) {
		if (row.cells[i].hasAttribute('colspan')) {
			start = start + Number(row.cells[i].getAttribute('colspan'));
		} else {
			start++;
		}
	}
	return start;
}
function find_cell_idx_in_row(row, cellnum) {
	var start=-1;
	for (var i=0; i < row.cells.length; i++) {
		if (row.cells[i].hasAttribute('colspan')) {
			start = start + Number(row.cells[i].getAttribute('colspan'));
		} else {
			start = start + 1;
		}
		if (start >= cellnum)
			return row.cells[i];
	}
}

