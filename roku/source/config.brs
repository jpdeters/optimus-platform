' Point this at the same API used by the OPTIMUS web client.
' Local development example: http://192.168.1.20:8787
' Deployed example: https://optimus-api.<your-account>.workers.dev
' Do not include a trailing slash.
function OptimusApiBase() as String
    return "https://YOUR-OPTIMUS-API-HOST"
end function

' Existing Hono API route used by apps/web.
function OptimusApiPath() as String
    return "/api/catalog"
end function
