function Sharecuts() {

    const self = this;

    this.canOpenShortcutsDeepLinks = function() {
        return /iPhone|iPad|iPod/.test(navigator.platform);
    }

    this.downloadShortcut = function(e) {
        if (self.canOpenShortcutsDeepLinks()) return;
                
        e.preventDefault();

        alert("To download Shortcuts, open sharecuts.app on an iOS device with the Shortcuts app installed.");
    }

    this.likeShortcut = async function(e) {
        e.stopPropagation();
        e.preventDefault();

        let shortcutID = $(this).data("shortcut");

        let url = `/api/shortcuts/${shortcutID}/vote`;

        $(this).prop("disabled", true);

        let ratingContainer = $(this).children("span.card-like-label");
        let value = parseInt(ratingContainer.text()) + 1;

        ratingContainer.text(value);

        let request = new Request(url, {"method": "PUT"});
        let result = await fetch(request);

        let response = await result.json();

        ratingContainer.text(response.rating);
    }
    
    this.install = function(e) {
        $("a.card-shortcut").click(self.downloadShortcut);
        $("button.btn-like").click(self.likeShortcut);
    }

}

const SC = new Sharecuts();

window.addEventListener("DOMContentLoaded", SC.install, false);