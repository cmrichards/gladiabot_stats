function addDatePicker(id) {
    var picker = new Pikaday({
        field: document.getElementById(id),
        format: 'DD MMM YYYY'
    });
}

var options = {
    url: function(name) { return "/players.json?name="+name; } ,
    getValue: "name",
    requestDelay: 300,
    list: {
        match: {
            enabled: true
        }
    },
    theme: "square"
};

$(function() {
    addDatePicker('date-from');
    addDatePicker('date-to');
    $(".player_autocomplete").easyAutocomplete(options);
    $(".player_autocomplete").easyAutocomplete(options);
    $(".easy-autocomplete").prop("style", "");
});
