window.addEventListener("DOMContentLoaded", function(){
    async function checkUsername(username) {
        let url = `/api/users/usernamecheck?username=${username}`
        let response = await fetch(url);

        return await response.json();
    };

    $("input#username").blur(async function(){
        let errorContainer = $(this).siblings("small");

        let username = $(this).val();

        if (username.length == 0) {
            $(this).removeClass("is-valid").removeClass("is-invalid");
            errorContainer.text("");
            return;
        }

        let result = await checkUsername(username);

//         console.log(result);

        if (!result.isAvailable) {
            $(this).removeClass("is-valid").addClass("is-invalid");
            errorContainer.text(result.message);
                                  }
      else
        {
            $(this).removeClass("is-invalid").addClass("is-valid");
            errorContainer.text("");
        }
    });
}, false);
