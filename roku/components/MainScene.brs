sub init()
    m.status = m.top.findNode("status")
    m.list = m.top.findNode("titles")
    m.detail = m.top.findNode("detail")

    m.apiTask = CreateObject("roSGNode", "ApiTask")
    m.apiTask.observeField("responseBody", "onCatalogResponse")
    m.top.appendChild(m.apiTask)

    m.list.observeField("itemSelected", "onTitleSelected")
    m.top.setFocus(true)
    loadCatalog()
end sub

sub loadCatalog()
    base = OptimusApiBase()
    if base = "" or Instr(1, base, "YOUR-OPTIMUS-API-HOST") > 0
        m.status.text = "API not configured. Edit source/config.brs."
        showDemoTitles()
        return
    end if

    m.status.text = "Loading the OPTIMUS catalog..."
    m.apiTask.requestUrl = base + OptimusApiPath()
    m.apiTask.control = "RUN"
end sub

sub onCatalogResponse()
    code = m.apiTask.responseCode
    body = m.apiTask.responseBody

    if code < 200 or code >= 300
        m.status.text = "API request failed (" + code.ToStr() + "). Showing demo titles."
        showDemoTitles()
        return
    end if

    parsed = ParseJson(body)
    items = extractItems(parsed)
    if items = invalid or items.Count() = 0
        m.status.text = "No catalog items returned. Showing demo titles."
        showDemoTitles()
        return
    end if

    content = CreateObject("roSGNode", "ContentNode")
    for each item in items
        title = readString(item, "name")
        if title = "" then title = readString(item, "title")
        if title <> ""
            child = content.createChild("ContentNode")
            child.title = title
            overview = readString(item, "synopsis")
            if overview = "" then overview = readString(item, "overview")
            if overview = "" then overview = readString(item, "description")
            child.description = overview
        end if
    end for

    m.list.content = content
    m.status.text = "Connected to OPTIMUS · " + content.getChildCount().ToStr() + " titles"
end sub

function extractItems(payload as Dynamic) as Dynamic
    if type(payload) = "roArray" then return payload
    if type(payload) = "roAssociativeArray"
        if payload.items <> invalid then return payload.items
        if payload.results <> invalid then return payload.results
        if payload.data <> invalid
            if type(payload.data) = "roArray" then return payload.data
            if type(payload.data) = "roAssociativeArray"
                if payload.data.items <> invalid then return payload.data.items
                if payload.data.results <> invalid then return payload.data.results
            end if
        end if
    end if
    return invalid
end function

function readString(item as Dynamic, key as String) as String
    if type(item) = "roAssociativeArray"
        value = item[key]
        if value <> invalid then return value.ToStr()
    end if
    return ""
end function

sub onTitleSelected()
    index = m.list.itemSelected
    if index = invalid then return
    node = m.list.content.getChild(index)
    if node <> invalid
        if node.description <> invalid and node.description <> ""
            m.detail.text = node.description
        else
            m.detail.text = node.title
        end if
    end if
end sub

sub showDemoTitles()
    content = CreateObject("roSGNode", "ContentNode")
    samples = ["Chad Powers  |  Demo catalog item", "Cobra Kai  |  Demo catalog item", "The Bear  |  Demo catalog item", "Only Murders in the Building  |  Demo catalog item", "Severance  |  Demo catalog item"]
    for each sample in samples
        child = content.createChild("ContentNode")
        child.title = sample
    end for
    m.list.content = content
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    return false
end function
