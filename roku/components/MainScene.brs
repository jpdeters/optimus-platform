sub init()
    m.status = m.top.findNode("status")
    m.list = m.top.findNode("titles")
    m.browseGroup = m.top.findNode("browseGroup")
    m.detailGroup = m.top.findNode("detailGroup")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailMeta = m.top.findNode("detailMeta")
    m.detailGenres = m.top.findNode("detailGenres")
    m.detailSynopsis = m.top.findNode("detailSynopsis")
    m.detailAvailability = m.top.findNode("detailAvailability")

    m.apiTask = CreateObject("roSGNode", "ApiTask")
    m.apiTask.observeField("responseBody", "onApiResponse")
    m.top.appendChild(m.apiTask)

    m.list.observeField("itemSelected", "onTitleSelected")
    m.list.setFocus(true)
    m.currentRequest = "catalog"
    m.titleIds = []
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
    m.currentRequest = "catalog"
    m.apiTask.requestUrl = base + OptimusApiPath()
    m.apiTask.control = "RUN"
end sub

sub onApiResponse()
    if m.currentRequest = "detail"
        showTitleDetail(m.apiTask.responseCode, m.apiTask.responseBody)
    else
        showCatalogResponse(m.apiTask.responseCode, m.apiTask.responseBody)
    end if
end sub

sub showCatalogResponse(code as Integer, body as String)
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
    m.titleIds = []
    for each item in items
        title = readString(item, "name")
        if title = "" then title = readString(item, "title")
        if title <> ""
            child = content.createChild("ContentNode")
            child.title = title
            child.description = readString(item, "synopsis")
            m.titleIds.Push(readString(item, "id"))
        end if
    end for

    m.list.content = content
    m.list.setFocus(true)
    m.status.text = "Connected to OPTIMUS · " + content.getChildCount().ToStr() + " titles"
end sub

sub onTitleSelected()
    index = m.list.itemSelected
    if index = invalid then return
    node = m.list.content.getChild(index)
    if node = invalid then return

    m.selectedTitleId = ""
    if m.titleIds <> invalid and index < m.titleIds.Count() then m.selectedTitleId = m.titleIds[index]
    if m.selectedTitleId = invalid or m.selectedTitleId = ""
        m.detailTitle.text = node.title
        m.detailMeta.text = "DEMO TITLE"
        m.detailGenres.text = ""
        m.detailSynopsis.text = "This is a sample catalog item. Connect the Roku client to the OPTIMUS API to load full title details."
        m.detailAvailability.text = "Availability data will appear here when supplied by the catalog."
        openDetailView()
        return
    end if

    base = OptimusApiBase()
    if base = "" or Instr(1, base, "YOUR-OPTIMUS-API-HOST") > 0
        m.detailTitle.text = node.title
        m.detailMeta.text = "DEMO TITLE"
        m.detailGenres.text = ""
        m.detailSynopsis.text = node.description
        m.detailAvailability.text = "Configure the API to load availability."
        openDetailView()
        return
    end if

    m.detailTitle.text = node.title
    m.detailMeta.text = "Loading title information..."
    m.detailGenres.text = ""
    m.detailSynopsis.text = ""
    m.detailAvailability.text = ""
    openDetailView()

    m.currentRequest = "detail"
    m.apiTask.requestUrl = base + "/api/catalog/" + m.selectedTitleId
    m.apiTask.control = "RUN"
end sub

sub showTitleDetail(code as Integer, body as String)
    if code < 200 or code >= 300
        m.detailMeta.text = "Title details unavailable (" + code.ToStr() + ")"
        m.detailSynopsis.text = "The catalog returned an error while loading this title."
        m.detailAvailability.text = ""
        return
    end if

    item = ParseJson(body)
    if item = invalid
        m.detailMeta.text = "Unable to read title details"
        return
    end if

    name = readString(item, "name")
    if name <> "" then m.detailTitle.text = name

    titleType = UCase(readString(item, "type"))
    year = readString(item, "year")
    rating = readString(item, "rating")
    runtime = readString(item, "runtime")
    seasons = readString(item, "seasons")

    meta = titleType
    if year <> "" then meta = meta + "  ·  " + year
    if rating <> "" then meta = meta + "  ·  " + rating
    if runtime <> "" then meta = meta + "  ·  " + runtime
    if seasons <> "" then meta = meta + "  ·  " + seasons + " season(s)"
    m.detailMeta.text = meta

    genresText = joinArray(item.genres, "  ·  ")
    m.detailGenres.text = genresText
    m.detailSynopsis.text = readString(item, "synopsis")
    m.detailAvailability.text = formatOffers(item.offers)
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

function joinArray(values as Dynamic, separator as String) as String
    if values = invalid then return ""
    result = ""
    for each value in values
        if result <> "" then result = result + separator
        result = result + value.ToStr()
    end for
    return result
end function

function formatOffers(offers as Dynamic) as String
    if offers = invalid then return "No availability information supplied."
    result = ""
    for each offer in offers
        providerId = readString(offer, "providerId")
        providerName = providerId
        if providerId = "stream-a" then providerName = "Stream A"
        if providerId = "stream-b" then providerName = "Stream B"
        if providerId = "stream-c" then providerName = "Stream C"

        offerType = readString(offer, "offerType")
        region = readString(offer, "region")
        line = providerName + "  ·  " + offerType
        if region <> "" then line = line + "  ·  " + region
        if result <> "" then result = result + Chr(10)
        result = result + line
    end for
    if result = "" then return "No availability information supplied."
    return result
end function

sub openDetailView()
    m.browseGroup.visible = false
    m.detailGroup.visible = true
    m.top.setFocus(true)
end sub

sub closeDetailView()
    m.detailGroup.visible = false
    m.browseGroup.visible = true
    m.list.setFocus(true)
end sub

sub showDemoTitles()
    content = CreateObject("roSGNode", "ContentNode")
    m.titleIds = []
    samples = ["Chad Powers  |  Demo catalog item", "Cobra Kai  |  Demo catalog item", "The Bear  |  Demo catalog item", "Only Murders in the Building  |  Demo catalog item", "Severance  |  Demo catalog item"]
    for each sample in samples
        child = content.createChild("ContentNode")
        child.title = sample
        m.titleIds.Push("")
    end for
    m.list.content = content
    m.list.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.detailGroup.visible and key = "back"
        closeDetailView()
        return true
    end if
    return false
end function
