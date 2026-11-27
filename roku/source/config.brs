' Point this at the deployed OPTIMUS API used by the web client.
' The TMDB token stays on the API Worker and is never shipped to Roku.
' Do not include a trailing slash.
function OptimusApiBase() as String
    return "https://optimus-api.jpdeters1.workers.dev"
end function

' Existing Hono API route used by apps/web.
function OptimusApiPath() as String
    return "/api/catalog"
end function
