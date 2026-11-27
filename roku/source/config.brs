' Set this to the deployed OPTIMUS API origin before sideload testing.
' Example: https://optimus-api.example.workers.dev
' Do not include a trailing slash.
function OptimusApiBase() as String
    return "https://YOUR-OPTIMUS-API-HOST"
end function

function OptimusApiPath() as String
    return "/catalog/trending"
end function
