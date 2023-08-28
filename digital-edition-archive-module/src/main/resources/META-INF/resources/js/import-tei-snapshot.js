
document.addEventListener('DOMContentLoaded', function() {

    document.querySelectorAll('.import-tei-snapshot').forEach(function(element) {
        mycore.upload.enable(element.parentElement, (result) => {

        });
    });

});