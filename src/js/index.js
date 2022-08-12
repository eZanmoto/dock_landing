// Copyright 2022 Sean Kelleher. All rights reserved.
// Use of this source code is governed by an MIT
// licence that can be found in the LICENCE file.

function main() {
  enableHighlighting(document.querySelectorAll('.getting-started li'), 'mouseover');
  enableHighlighting(document.querySelectorAll('.installation li'), 'click');
}

function enableHighlighting(items, trigger) {
  for (const item of items) {
    item.addEventListener(trigger, (e) => {
      for (const item of items) {
        item.classList.remove('highlighted');
      }
      item.classList.add('highlighted');
    });
  }
}

main();
