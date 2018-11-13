var timer = null;
var currentFrame = 1;
var interval = 300;

function flashImage(url) {
  $('.app-preview div').addClass('d-none');
  $('.app-preview').attr('style', 'background-image: url('+url+')');
  setTimeout(function() {
    $('.app-preview').attr('style', 'background-image: none');
    showFrame($('.app-thumbs .thumb:first-child'));
  }, 3000);
}

function showFrame(thumb) {
  var next = thumb.find('img').attr('src');
  $('.app-preview div').addClass('d-none');
  $('.app-preview div[data-src="'+next+'"]').removeClass('d-none');
  $('.app-thumbs .thumb').removeClass('active');
  thumb.addClass('active');
  $('.app-thumbs').scrollTo(thumb, interval / 2);
}

function play(repeat) {
  $('.app-btn.play').addClass('disabled');
  $('.app-btn.share').addClass('disabled');
  $('.app-btn.camera').addClass('disabled');
  $('.app-btn.pause').removeClass('disabled');
  var i = 1;
  timer = setInterval(function () { 
    // console.log(i, $('.app-thumbs .thumb').length);
    showFrame($('.app-thumbs .thumb:nth-child('+i+')'));
    if (i === $('.app-thumbs .thumb').length) stop();
    i++;
  }, interval);
}

function stop() {
  $('.app-btn.pause').addClass('disabled');
  $('.app-btn.play').removeClass('disabled');
  $('.app-btn.share').removeClass('disabled');
  $('.app-btn.camera').removeClass('disabled');
  clearInterval(timer);
  timer = null;
}

$( document ).ready(function () {

  $('.app-thumbs .thumb').each(function (i, v) { 
    $('.app-preview').append( 
      $( '<div>')
        .attr('style', 'background-image: url(' + $(v).find('img').attr('src') + ')') 
        .attr('data-src', $(v).find('img').attr('src'))
        .addClass('d-none')
    );
  });

  $('.app-thumbs .thumb').click(function () {
    showFrame($(this));
  });

  play(false);

  $('.app-btn.play').click(function(e) {
    e.preventDefault()
    play(true);
  });

  $('.app-btn.pause').click(function(e) {
    e.preventDefault();
    stop();
  });

  $('.app-btn.share').click(function(e) {
    e.preventDefault();
    if (timer !== null) return;
    flashImage('https://media.giphy.com/media/aQUGAeZ1fBWpy/giphy.gif');
  });

  $('.app-btn.camera').click(function(e) {
    e.preventDefault();
    if (timer !== null) return;
    flashImage('https://media.giphy.com/media/10SPpae7SQxpe/giphy.gif');
  });

});