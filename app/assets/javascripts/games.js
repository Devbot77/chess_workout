$(function() {
  initPage();
});
$(window).bind('page:change', function() {
  initPage();
  $("#reverse_view").on("click", function() {
    // Reverse board columns
    $("tr").each(function(elem, index) {
      var arr_cols = $.makeArray($("td", this).detach());
      arr_cols.reverse();
      $(this).append(arr_cols);
    });
    // Reverse board rows
    $("tbody").each(function(elem, index) {
      var arr_rows = $.makeArray($("tr", this).detach());
      arr_rows.reverse();
      $(this).append(arr_rows);
    });
  });
});

function initPage() {
  "use strict";

  $.ajaxSetup({
    headers: {
      'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
    }
  });

  var top_z = 100;
  var start_sq = 99;
  var pieceColor = '';

  if (userID == whiteID) {
    pieceColor = 'white_piece'
  } else {
    pieceColor = 'black_piece'
  };
  $('.' + pieceColor).draggable({
    cursor: "pointer",
    containment: ".board",
    snap: ".board td",
    snapTolerance: 20,
    revert: "invalid",
    start: function() {
      $(this).data("oldPosition", $(this).offset());
      start_sq = this.closest("td").id;
    }
  }).on("mousedown", function() {
    this.style.zIndex = ++top_z;
  });


  $(".board td").droppable({
    accept: ".piece",
    tolerance: "fit",
    drop: handleDrop
  });

  function revertAnimate(ui, oldPosition, speed){
    var newPosition = ui.draggable.offset();
    var leftOffset = null;
    var topOffset = null;
    if (oldPosition.left > newPosition.left) {
      leftOffset = (oldPosition.left - newPosition.left);
    } else {
      leftOffset = -(newPosition.left - oldPosition.left);
    }
    if (oldPosition.top > newPosition.top) {
      topOffset = (oldPosition.top - newPosition.top);
    } else {
      topOffset = -(newPosition.top - oldPosition.top);
    }
    ui.draggable.animate({
      left: '+=' + leftOffset,
      top: '+=' + topOffset,
    }, speed)
  };

  function handleDrop(event, ui) {
    if (this.id != start_sq) {
      $.ajax({
        context: this,
        type: 'PUT',
        url: ui.draggable.data('piece-url'),
        dataType: 'json',
        data: { piece: {x_position: Number(this.id.charAt(1)), y_position: Number(this.id.charAt(0))} },
        error: function(){
          var oldPosition = ui.draggable.data().oldPosition;
          revertAnimate(ui, oldPosition, 'fast');
          return;
        },
        success: function(){
          $(".board td").removeClass("moved_sq");
          if ($(this).find(".piece").hasClass("white_piece")) {
            $(this).find(".piece").appendTo("#white_captured");
          } else {
            $(this).find(".piece").appendTo("#dark_captured");
          }
          $(this).empty();
          ui.draggable.draggable("option", "revert", false);
          var oldPosition = ui.draggable.offset();
          $(ui.draggable).appendTo(this);
          revertAnimate(ui, oldPosition, 0);
          ui.draggable.draggable("option", "revert", true);
          $("#" + start_sq).addClass("moved_sq");
          $(this).addClass("moved_sq");
          $("#moves").prepend("<li>" + ui.draggable.attr("id") + ": " + start_sq + " --> " + this.id + "</li>");
        }
      })
    } else {
      return;
    }
  };
}
