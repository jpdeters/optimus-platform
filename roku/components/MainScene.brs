sub init()
    m.status = m.top.findNode("status")
    m.section = m.top.findNode("section")
    m.list = m.top.findNode("titles")
    m.browseGroup = m.top.findNode("browseGroup")
    m.detailGroup = m.top.findNode("detailGroup")
    m.detailEyebrow = m.top.findNode("detailEyebrow")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailMeta = m.top.findNode("detailMeta")
    m.detailGenres = m.top.findNode("detailGenres")
    m.detailSynopsis = m.top.findNode("detailSynopsis")
    m.detailAvailability = m.top.findNode("detailAvailability")

    m.apiTask = CreateObject("roSGNode", "ApiTask")
    m.apiTask.observeField("responseBody", "onApiResponse")
    m.top.appendChild(m.apiTask)
    m.list.observeField("itemSelected", "onListSelected")

    m.registry = CreateObject("roRegistrySection", "optimus")
    m.services = loadRegistryList("services", ["stream-a", "stream-b"])
    m.watchlist = loadRegistryList("watchlist", [])
    m.providers = [
        {id:"stream-a", name:"Stream A"},
        {id:"stream-b", name:"Stream B"},
        {id:"stream-c", name:"Stream C"}
    ]
    m.catalogItems = []
    m.visibleIds = []
    m.currentView = "discover"
    m.currentRequest = "catalog"
    m.list.setFocus(true)
    loadCatalog()
end sub

function loadRegistryList(key as String, fallback as Object) as Object
    value = m.registry.Read(key)
    if value = invalid or value = "" then return fallback
    return value.Split(",")
end function

sub saveRegistryList(key as String, values as Object)
    value = ""
    for each entry in values
        if value <> "" then value = value + ","
        value = value + entry
    end for
    m.registry.Write(key, value)
    m.registry.Flush()
end sub

function hasValue(values as Object, target as String) as Boolean
    for each value in values
        if value = target then return true
    end for
    return false
end function

sub loadCatalog()
    base = OptimusApiBase()
    if base = "" or Instr(1, base, "YOUR-OPTIMUS-API-HOST") > 0
        m.status.text = "API not configured. Showing local demo catalog."
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
        m.status.text = "API request failed (" + code.ToStr() + "). Showing demo catalog."
        showDemoTitles()
        return
    end if
    parsed = ParseJson(body)
    items = extractItems(parsed)
    if items = invalid or items.Count() = 0
        m.status.text = "No catalog items returned."
        showDemoTitles()
        return
    end if
    m.catalogItems = items
    m.status.text = "Connected to OPTIMUS · " + items.Count().ToStr() + " titles"
    renderCurrentView()
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

function providerName(providerId as String) as String
    for each provider in m.providers
        if provider.id = providerId then return provider.name
    end for
    return providerId
end function

function availabilityLabel(item as Object) as String
    offers = item.offers
    if offers = invalid then return "AVAILABILITY UNKNOWN"
    included = []
    other = []
    for each offer in offers
        pid = readString(offer, "providerId")
        kind = readString(offer, "offerType")
        if kind = "subscription" and hasValue(m.services, pid)
            included.Push(providerName(pid))
        else
            other.Push(providerName(pid) + " " + UCase(kind))
        end if
    end for
    if included.Count() > 0 then return "INCLUDED: " + joinArray(included, ", ")
    if other.Count() > 0 then return "OTHER OPTIONS: " + joinArray(other, ", ")
    return "AVAILABILITY UNKNOWN"
end function

sub renderCurrentView()
    content = CreateObject("roSGNode", "ContentNode")
    m.visibleIds = []

    if m.currentView = "services"
        m.section.text = "MY SERVICES  ·  SELECT YOUR SUBSCRIPTIONS"
        m.status.text = "OK toggles a service. Selection is saved on this Roku."
        for each provider in m.providers
            child = content.createChild("ContentNode")
            prefix = "[ ] "
            if hasValue(m.services, provider.id) then prefix = "[X] "
            child.title = prefix + provider.name
            m.visibleIds.Push(provider.id)
        end for
    else
        if m.currentView = "watchlist"
            m.section.text = "MY WATCHLIST"
            m.status.text = "Your saved titles on this Roku"
        else
            m.section.text = "DISCOVER"
            m.status.text = "Catalog · availability matched to My Services"
        end if

        for each item in m.catalogItems
            id = readString(item, "id")
            showItem = true
            if m.currentView = "watchlist" and not hasValue(m.watchlist, id) then showItem = false
            if showItem
                child = content.createChild("ContentNode")
                title = readString(item, "name")
                if title = "" then title = readString(item, "title")
                if m.currentView = "discover"
                    title = title + "   ·   " + availabilityLabel(item)
                end if
                if hasValue(m.watchlist, id) then title = "★  " + title
                child.title = title
                child.description = readString(item, "synopsis")
                m.visibleIds.Push(id)
            end if
        end for
        if m.currentView = "watchlist" and m.visibleIds.Count() = 0
            child = content.createChild("ContentNode")
            child.title = "Your watchlist is empty. Save a title from its detail page."
            m.visibleIds.Push("")
        end if
    end if

    m.list.content = content
    m.list.setFocus(true)
end sub

sub onListSelected()
    index = m.list.itemSelected
    if index = invalid or index < 0 or index >= m.visibleIds.Count() then return

    if m.currentView = "services"
        id = m.visibleIds[index]
        if hasValue(m.services, id)
            nextServices = []
            for each service in m.services
                if service <> id then nextServices.Push(service)
            end for
            m.services = nextServices
        else
            m.services.Push(id)
        end if
        saveRegistryList("services", m.services)
        renderCurrentView()
        return
    end if

    id = m.visibleIds[index]
    if id = "" then return
    m.selectedTitleId = id
    openSelectedTitle()
end sub

sub openSelectedTitle()
    item = findCatalogItem(m.selectedTitleId)
    if item <> invalid
        m.detailTitle.text = readString(item, "name")
        m.detailMeta.text = UCase(readString(item, "type")) + "  ·  " + readString(item, "year") + "  ·  " + readString(item, "rating")
        runtime = readString(item, "runtime")
        seasons = readString(item, "seasons")
        if runtime <> "" then m.detailMeta.text = m.detailMeta.text + "  ·  " + runtime
        if seasons <> "" then m.detailMeta.text = m.detailMeta.text + "  ·  " + seasons + " season(s)"
        m.detailGenres.text = joinArray(item.genres, "  ·  ")
        m.detailSynopsis.text = readString(item, "synopsis")
        m.detailAvailability.text = formatOffers(item.offers)
    else
        m.detailTitle.text = "Loading title..."
        m.detailMeta.text = ""
        m.detailGenres.text = ""
        m.detailSynopsis.text = ""
        m.detailAvailability.text = ""
    end if
    openDetailView()

    base = OptimusApiBase()
    if base <> "" and Instr(1, base, "YOUR-OPTIMUS-API-HOST") = 0
        m.currentRequest = "detail"
        m.apiTask.requestUrl = base + "/api/catalog/" + m.selectedTitleId
        m.apiTask.control = "RUN"
    end if
end sub

function findCatalogItem(id as String) as Dynamic
    for each item in m.catalogItems
        if readString(item, "id") = id then return item
    end for
    return invalid
end function

sub showTitleDetail(code as Integer, body as String)
    if code < 200 or code >= 300 then return
    item = ParseJson(body)
    if item = invalid then return
    m.detailTitle.text = readString(item, "name")
    m.detailMeta.text = UCase(readString(item, "type")) + "  ·  " + readString(item, "year") + "  ·  " + readString(item, "rating")
    runtime = readString(item, "runtime")
    seasons = readString(item, "seasons")
    if runtime <> "" then m.detailMeta.text = m.detailMeta.text + "  ·  " + runtime
    if seasons <> "" then m.detailMeta.text = m.detailMeta.text + "  ·  " + seasons + " season(s)"
    m.detailGenres.text = joinArray(item.genres, "  ·  ")
    m.detailSynopsis.text = readString(item, "synopsis")
    m.detailAvailability.text = formatOffers(item.offers)
end sub

function formatOffers(offers as Dynamic) as String
    if offers = invalid then return "No availability information supplied."
    result = ""
    for each offer in offers
        pid = readString(offer, "providerId")
        kind = readString(offer, "offerType")
        if kind = "subscription" and hasValue(m.services, pid)
            line = providerName(pid) + "  ·  INCLUDED WITH YOUR SERVICES"
        else if kind = "subscription"
            line = providerName(pid) + "  ·  SUBSCRIPTION REQUIRED"
        else if kind = "rent"
            line = providerName(pid) + "  ·  RENT"
        else if kind = "buy"
            line = providerName(pid) + "  ·  BUY"
        else
            line = providerName(pid) + "  ·  " + UCase(kind)
        end if
        if result <> "" then result = result + Chr(10)
        result = result + line
    end for
    if result = "" then return "No availability information supplied."
    return result
end function

sub toggleWatchlist()
    if m.selectedTitleId = invalid or m.selectedTitleId = "" then return
    if hasValue(m.watchlist, m.selectedTitleId)
        nextList = []
        for each id in m.watchlist
            if id <> m.selectedTitleId then nextList.Push(id)
        end for
        m.watchlist = nextList
        m.detailEyebrow.text = "REMOVED FROM WATCHLIST"
    else
        m.watchlist.Push(m.selectedTitleId)
        m.detailEyebrow.text = "SAVED TO WATCHLIST"
    end if
    saveRegistryList("watchlist", m.watchlist)
end sub

sub openDetailView()
    m.browseGroup.visible = false
    m.detailGroup.visible = true
    m.top.setFocus(true)
end sub

sub closeDetailView()
    m.detailGroup.visible = false
    m.browseGroup.visible = true
    m.currentRequest = "catalog"
    renderCurrentView()
end sub

sub showDemoTitles()
    m.catalogItems = [
        {id:"demo-001", name:"The Last Meridian", type:"series", year:2025, rating:"TV-14", seasons:2, genres:["Drama","Mystery"], synopsis:"A remote coastal town discovers its newest arrival knows more about its history than anyone should.", offers:[{providerId:"stream-a",offerType:"subscription"},{providerId:"stream-c",offerType:"rent"}]},
        {id:"demo-002", name:"Orbit of Ash", type:"movie", year:2024, rating:"PG-13", runtime:"2h 08m", genres:["Science Fiction","Adventure"], synopsis:"A salvage crew follows a mysterious signal beyond the edge of a mapped solar system.", offers:[{providerId:"stream-b",offerType:"subscription"}]},
        {id:"demo-003", name:"Small Hours", type:"series", year:2026, rating:"TV-MA", seasons:1, genres:["Comedy","Drama"], synopsis:"Three night-shift coworkers build an unlikely friendship while keeping a city hotel running.", offers:[{providerId:"stream-a",offerType:"subscription"}]}
    ]
    renderCurrentView()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.detailGroup.visible
        if key = "back"
            closeDetailView()
            return true
        else if key = "options"
            toggleWatchlist()
            return true
        end if
        return false
    end if

    if key = "options"
        if m.currentView = "discover"
            m.currentView = "services"
        else if m.currentView = "services"
            m.currentView = "watchlist"
        else
            m.currentView = "discover"
        end if
        renderCurrentView()
        return true
    else if key = "back" and m.currentView <> "discover"
        m.currentView = "discover"
        renderCurrentView()
        return true
    end if
    return false
end function
