$(document).ready(function() {
	
	$('.piece').draggable( {
		containment: '.board',
		cursor: 'move',
		snap: '.ui-droppable'
	});
});
