function Sharecuts() {

    const self = this;

    this.canOpenShortcutsDeepLinks = function() {
        return /iPhone|iPad|iPod/.test(navigator.platform);
    }

    this.downloadShortcut = function(e) {
        if (self.canOpenShortcutsDeepLinks()) return;
                
        e.preventDefault();
        e.stopPropagation();

        var downloadURL = $(this).data("downloadurl");

        if (window.location.href.indexOf("indigo") !== -1) {
            downloadURL.replace("sharecuts.app", "indigo.sharecuts.app");
        }

        window.location.href = downloadURL;
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
	
	this.navigateToUser = function(e) {
        e.stopPropagation();
        e.preventDefault();

        let username = $(this).data("username");
		
		window.location.href = `/users/${username}`;
	}
    
    this.install = function(e) {
        $("a.card-shortcut").click(self.downloadShortcut);
        $("button.btn-like").click(self.likeShortcut);
        $(".card-author").click(self.navigateToUser);
    }

}

const SC = new Sharecuts();

window.addEventListener("DOMContentLoaded", SC.install, false);