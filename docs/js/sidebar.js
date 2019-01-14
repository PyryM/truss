const docLinkSelector = '.docs-link';
const docSublinkSelector = '.docs-sublink';
const docContentSelector = '#content';
const titleBase = document.title + ' - ';

let $currentHeader = $();
let $currentSubheader = $();

// Highlight the current section of the documentation that we are in.
jQuery(function() {
  const docFirstHref = $(docLinkSelector)
    .first()
    .attr('href');

  if (docFirstHref !== undefined && docFirstHref.charAt(0) === '#') {
    addSublinks();

    setActiveSidebarLink();
    setActiveSidebarSublink($currentHeader);

    $(window).on('scroll', function(evt) {
      setActiveSidebarLink();
      setActiveSidebarSublink($currentHeader);
    });
  }
});

// Creates menu entries containing subheaders for entire document.
function addSublinks() {
  const $links = $(docLinkSelector);
  $links.each(function() {
    const $heading = $(this);
    const $subheadings = $($heading.attr('href'))
      .closest('.ui.vertical.segment')
      .children('h2');

    const $subheadingMenu = $('<div class="menu" />').appendTo($heading);
    $subheadings.each(function() {
      $subheadingMenu.append(
        `<a class="ui item docs-sublink" href="#${this.id}">${$(
          this,
        ).text()}</div>`,
      );
    });
  });
}

// Modifies the class on closest menu header to the current scroll location.
function setActiveSidebarLink() {
  const $closest = getClosestHeader(docLinkSelector);

  if ($currentHeader === $closest) return;
  $currentHeader = $closest;

  $(docLinkSelector).removeClass('active');
  $(docLinkSelector)
    .children('.menu')
    .hide();

  $closest.addClass('active');
  $closest.children('.menu').show();

  document.title =
    titleBase +
    $closest
      .clone()
      .children()
      .remove()
      .end()
      .text();
}

// Modifies the class on closest secondary header for current scroll location.
// We include the main header such that if it is the closest, no subheader will
// be selected at all.
function setActiveSidebarSublink($heading) {
  const $subheadings = $heading.find(docSublinkSelector).add($heading);
  const $closest = getClosestHeader($subheadings);

  if ($currentSubheader === $closest) return;
  $currentSubheader = $closest;

  $(docSublinkSelector).removeClass('active');
  $closest.addClass('active');
}

// Looks for a link that contains the specified selector and uses the position
// of its reference to determine if it is the closest anchor to the user.
function getClosestHeader(selector) {
  const $links = $(selector);
  const top = window.scrollY;
  let $last = $links.first();

  if (top < 200) {
    return $last;
  }

  if (top + window.innerHeight >= $(docContentSelector).height()) {
    return $links.last();
  }

  for (let i = 0; i < $links.length; i++) {
    const $link = $links.eq(i);
    const href = $link.attr('href');

    if (href !== undefined && href.charAt(0) === '#' && href.length > 1) {
      const $anchor = $(href);

      if ($anchor.length > 0) {
        const offset = $anchor.offset();

        if (top < offset.top - 200) {
          return $last;
        }

        $last = $link;
      }
    }
  }
  return $last;
}
