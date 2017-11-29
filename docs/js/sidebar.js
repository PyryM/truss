const docLinkSelector = '.docs-link';
const docContentSelector = '#content';

// Highlight the current section of the documentation that we are in.
jQuery(function() {
  const docFirstHref = $(docLinkSelector)
    .first()
    .attr('href');

  if (docFirstHref !== undefined && docFirstHref.charAt(0) === '#') {
    setActiveSidebarLink();

    $(window).on('scroll', function(evt) {
      setActiveSidebarLink();
    });
  }
});

// Modifies the class on closest menu header to the current scroll location.
function setActiveSidebarLink() {
  $(docLinkSelector).removeClass('active');
  const $closest = getClosestHeader();
  $closest.addClass('active');
  document.title = $closest.text();
}

// Looks for a link that contains the `docs-link` class and uses the position
// of its reference to determine if it is the closest header to the user.
function getClosestHeader() {
  const $links = $(docLinkSelector);
  const top = window.scrollY;
  let $last = $links.first();

  if (top < 300) {
    return $last;
  }

  if (top + window.innerHeight >= $(docContentSelector).height()) {
    return $links.last();
  }

  for (var i = 0; i < $links.length; i++) {
    var $link = $links.eq(i),
      href = $link.attr('href');

    if (href !== undefined && href.charAt(0) === '#' && href.length > 1) {
      var $anchor = $(href);

      if ($anchor.length > 0) {
        var offset = $anchor.offset();

        if (top < offset.top - 300) {
          return $last;
        }

        $last = $link;
      }
    }
  }
  return $last;
}
