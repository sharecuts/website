function sharecuts() {
    function download(shortcut) {
        window.location.href = "/download/" + shortcut;
    }

    document.querySelectorAll("div.shortcut-card").forEach(function(card){
        card.addEventListener("click", function(e) {
            var shortcut = e.target.dataset.shortcut;
            if (shortcut == undefined) return;
            download(shortcut);
        }, false);
    });
}

window.addEventListener("DOMContentLoaded", sharecuts, false);