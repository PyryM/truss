// Update search results when text in search box changes.
jQuery(function() {
  // Get references to elements used by the search layout.
  const searchInputEl = document.getElementById('search-input');
  const searchResultsEl = document.getElementById('search-results');
  const searchSuccessEl = document.getElementById('search-success');
  const searchProgressEl = document.getElementById('search-progress');
  const searchQueryEl = document.getElementById('search-query');
  const searchQueryContainerEl = document.getElementById(
    'search-query-container',
  );

  // Function to render a preview of current search results.
  function displaySearchResults(results, query) {
    if (results.length) {
      let resultsHTML = '';
      results.forEach(function(result) {
        let item = window.data[result.ref],
          contentPreview = getPreview(query, item.content, 170),
          titlePreview = getPreview(query, item.title);

        resultsHTML += `
          <a href="${item.url}" class="item">
            <div class="content">
              <div class="header">${titlePreview}</div>
              <div class="description">${contentPreview}</div>
            </div>
          </a>`;
      });

      searchResultsEl.innerHTML = resultsHTML;
      searchSuccessEl.innerText = 'Showing';
      $(searchProgressEl).removeClass('loading');
    } else {
      searchResultsEl.style.display = 'none';
      searchSuccessEl.innerText = 'No';
      $(searchProgressEl).hide();
    }
  }

  // Initialize LUNR to have certain search categories.
  window.index = lunr(function() {
    this.field('id');
    this.field('title', { boost: 10 });
    this.field('category');
    this.field('url');
    this.field('content');

    // For each key in the window data, add this to the index.
    for (const key in window.data) {
      this.add(window.data[key]);
    }
  });

  // Extract existing search queries from the query string of the URL.
  const query = decodeURIComponent(
    (getQueryVariable('q') || '').replace(/\+/g, '%20'),
  );

  // Fill in the existing query parameters in the search layout.
  searchInputEl.value = query;
  searchQueryEl.innerText = query;
  searchQueryContainerEl.style.display = 'inline';

  // Kick off processing of initial search results.
  displaySearchResults(window.index.search(query), query);
});

function getQueryVariable(variable) {
  const query = window.location.search.substring(1),
    vars = query.split('&');

  for (const i = 0; i < vars.length; i++) {
    const pair = vars[i].split('=');

    if (pair[0] === variable) {
      return pair[1];
    }
  }
}

function getPreview(query, content, previewLength) {
  previewLength = previewLength || content.length * 2;

  const parts = query.split(' ');
  let match = content.toLowerCase().indexOf(query.toLowerCase());
  let matchLength = query.length;
  let preview;

  // Find a relevant location in content
  for (var i = 0; i < parts.length; i++) {
    if (match >= 0) {
      break;
    }

    match = content.toLowerCase().indexOf(parts[i].toLowerCase());
    matchLength = parts[i].length;
  }

  // Create preview
  if (match >= 0) {
    var start = match - previewLength / 2,
      end = start > 0 ? match + matchLength + previewLength / 2 : previewLength;

    preview = content.substring(start, end).trim();

    if (start > 0) {
      preview = '...' + preview;
    }

    if (end < content.length) {
      preview = preview + '...';
    }

    // Highlight query parts
    preview = preview.replace(
      new RegExp('(' + parts.join('|') + ')', 'gi'),
      '<strong>$1</strong>',
    );
  } else {
    // Use start of content if no match found
    preview =
      content.substring(0, previewLength).trim() +
      (content.length > previewLength ? '...' : '');
  }

  return preview;
}
