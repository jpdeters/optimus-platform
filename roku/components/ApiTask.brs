sub init()
    m.top.functionName = "executeRequest"
end sub

sub executeRequest()
    m.top.responseComplete = false
    m.top.responseData = {}
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("User-Agent", "OptimusRoku/1.0 (Roku)")
    if m.top.authToken <> "" then transfer.AddHeader("Authorization", "Bearer " + m.top.authToken)
    transfer.EnableEncodings(true)
    transfer.RetainBodyOnError(true)
    transfer.SetUrl(m.top.requestUrl)
    transfer.SetConnectionTimeout(15)

    ' Use the asynchronous API with a hard deadline. GetToString() can block
    ' indefinitely on some network failures, leaving the Roku UI on its spinner.
    method = m.top.requestMethod
    if method = "" then method = "GET"
    if method = "GET"
        started = transfer.AsyncGetToString()
    else
        transfer.SetRequest(method)
        transfer.AddHeader("Content-Type", "application/json")
        started = transfer.AsyncPostFromString(m.top.requestBody)
    end if
    if not started
        m.top.responseBody = "Could not start network request."
        m.top.responseCode = -1
        m.top.responseComplete = true
        return
    end if

    msg = wait(20000, port)
    if type(msg) = "roUrlEvent"
        m.top.responseBody = msg.GetString()
        m.top.responseCode = msg.GetResponseCode()
    else
        transfer.AsyncCancel()
        m.top.responseBody = "Request timed out after 20 seconds."
        m.top.responseCode = -1000
    end if
    parsed = {}
    if m.top.responseBody <> ""
        parsed = ParseJson(m.top.responseBody)
        if type(parsed) <> "roAssociativeArray" then parsed = {}
    end if
    m.top.responseData = parsed
    m.top.responseComplete = true
end sub
