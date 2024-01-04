document.addEventListener('DOMContentLoaded', (event) => {
    function clearHighlights() {
        document.querySelectorAll('.diary-entry').forEach((el) => {
            el.classList.remove('diary-entry-highlighted');
        });
    }

    function highlightEntry(hash) {
        clearHighlights();
        const entry = document.querySelector(hash);
        if (entry) {
            entry.classList.add('diary-entry-highlighted');
            entry.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    }

    if(window.location.hash) {
        highlightEntry(window.location.hash);
    }

    document.querySelectorAll('.diary-entry-number').forEach((number) => {
        number.addEventListener('click', () => {
            highlightEntry(number.getAttribute('href'));
        });
    });

    window.addEventListener('hashchange', () => {
        highlightEntry(window.location.hash);
    }, false);
});
