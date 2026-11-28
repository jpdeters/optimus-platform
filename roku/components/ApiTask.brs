sub init()
    m.top.functionName = "executeRequest"
end sub

sub executeRequest()
    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.AddHeader("Accept", "application/json")
    transfer.SetUrl(m.top.requestUrl)

    body = transfer.GetToString()
    code = transfer.GetResponseCode()

    m.top.responseBody = body
    m.top.responseCode = code
end sub
