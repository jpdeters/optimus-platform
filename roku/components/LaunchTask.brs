sub init()
    m.top.functionName = "launchProviderApp"
end sub

sub launchProviderApp()
    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(m.top.requestUrl)
    transfer.SetRequest("POST")
    transfer.AddHeader("Content-Length", "0")
    transfer.PostFromString("")
    m.top.responseCode = transfer.GetResponseCode()
end sub
