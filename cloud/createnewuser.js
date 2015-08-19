Parse.Cloud.define("createNewUser", function(request, response) {

    // extract passed in details 
    var username = request.params.username
    var name = request.params.name

    // cloud local calls
    var user = new Parse.User();
    user.set("username", username);
    user.set("password", username);

    user.signUp(null, {
        success: function(user) {
			user.set("name", name)
			user.save(null, {
				success: function(gameScore) {
					// Execute any logic that should take place after the object is saved.
					response.success(user.id);
				},
				error: function(gameScore, error) {
					// Execute any logic that should take place if the save fails.
					// error is a Parse.Error with an error code and message.
					response.error("Sorry! " + error.message);
				}
			})
		},
		error: function(user, error) {
		    response.error("Sorry! " + error.message);
		}
	});

});