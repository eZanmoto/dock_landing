function main() {
  const items = document.querySelectorAll('.getting-started li');
  for (const item of items) {
    item.addEventListener('mouseover', (e) => {
      for (const item of items) {
        item.classList.remove('highlighted');
      }
      item.classList.add('highlighted');
    });
  }
}

main();
