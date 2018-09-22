function Sharecuts() {

    const self = this;

    this.canOpenShortcutsDeepLinks = function() {
        return /iPhone|iPad|iPod/.test(navigator.platform);
    }
    
    this.install = function(e) {
        document.querySelector("a.card-shortcut").addEventListener("click", function(e){
            if (self.canOpenShortcutsDeepLinks()) return;
            
            e.preventDefault();

            alert("To download Shortcuts, open sharecuts.app on an iOS device with the Shortcuts app installed.");
        }, false);
    }

}

const SC = new Sharecuts();

window.addEventListener("DOMContentLoaded", SC.install, false);