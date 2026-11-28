sub init()
    m.top.functionName = "executeRequest"
end sub

sub executeRequest()
    m.top.responseComplete = false
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("User-Agent", "OptimusRoku/1.0 (Roku)")
    transfer.EnableEncodings(true)
    transfer.RetainBodyOnError(true)
    transfer.SetUrl(m.top.requestUrl)
    transfer.SetConnectionTimeout(15)

    ' Use the asynchronous API with a hard deadline. GetToString() can block
    ' indefinitely on some network failures, leaving the Roku UI on its spinner.
    started = transfer.AsyncGetToString()
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
    m.top.responseComplete = true
end sub
