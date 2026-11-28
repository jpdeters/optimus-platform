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
    m.detailWatchHeader = m.top.findNode("detailWatchHeader")
    m.launchOptions = m.top.findNode("launchOptions")
    m.pairCodeLabel = m.top.findNode("pairCode")
    m.pairTimer = m.top.findNode("pairTimer")
    m.pairTimer.observeField("fire", "onPairTimer")
    m.authToken = ""
    m.profileNeedsInit = false
    m.pairDeviceCode = ""
    m.pairPolling = false
    m.watchlistTitles = []
    m.searchDialog = m.top.findNode("searchDialog")
    m.searchDialog.visible = false
    m.searchDialog.buttons = ["Search", "Cancel"]
    m.searchDialog.observeField("buttonSelected", "onSearchButton")
    m.searchQuery = ""

    m.launchIds = []
    m.launchTask = CreateObject("roSGNode", "LaunchTask")
    m.launchTask.observeField("responseCode", "onLaunchResponse")
    m.top.appendChild(m.launchTask)

    m.apiTask = CreateObject("roSGNode", "ApiTask")
    m.apiTask.observeField("responseComplete", "onApiResponse")
    m.top.appendChild(m.apiTask)
    m.list.observeField("itemSelected", "onListSelected")
    m.launchOptions.observeField("itemSelected", "onLaunchSelected")

    m.registry = CreateObject("roRegistrySection", "optimus")
    m.services = loadRegistryList("services", [])
    m.watchlist = loadRegistryList("watchlist", [])
    savedToken = m.registry.Read("authToken")
    if savedToken <> invalid then m.authToken = savedToken
    m.providers = []
    m.catalogItems = []
    m.visibleIds = []
    m.currentView = "discover"
    m.currentRequest = "providers"
    m.list.setFocus(true)
    loadProviders()
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

sub loadProviders()
    base = OptimusApiBase()
    if base = "" or Instr(1, base, "YOUR-OPTIMUS-API-HOST") > 0
        m.status.text = "Configure the OPTIMUS API to load real streaming services."
        m.catalogItems = []
        renderCurrentView()
        return
    end if
    m.status.text = "Loading streaming services..."
    runApiRequest("providers", base + "/api/providers")
end sub

sub showProvidersResponse(code as Integer, parsed as Dynamic)
    if code < 200 or code >= 300
        m.status.text = "Could not load streaming services (" + code.ToStr() + ")."
        return
    end if
    items = extractItems(parsed)
    if items = invalid then return
    m.providers = items
    valid = []
    for each id in m.services
        for each provider in m.providers
            if provider.id = id then valid.Push(id)
        end for
    end for
    m.services = valid
    saveRegistryList("services", m.services)
    if m.authToken <> ""
        loadProfile()
        return
    end if
    if m.services.Count() = 0 and m.providers.Count() > 0
        m.currentView = "services"
        renderCurrentView()
        return
    end if
    loadCatalog()
end sub

sub loadCatalog()
    base = OptimusApiBase()
    if base = "" or Instr(1, base, "YOUR-OPTIMUS-API-HOST") > 0
        m.status.text = "Configure the OPTIMUS API to load real listings."
        m.catalogItems = []
        renderCurrentView()
        return
    end if
    if m.services.Count() = 0
        m.catalogItems = []
        if m.providers.Count() > 0 then m.currentView = "services"
        renderCurrentView()
        return
    end if
    serviceQuery = ""
    for each id in m.services
        if serviceQuery <> "" then serviceQuery = serviceQuery + ","
        serviceQuery = serviceQuery + id
    end for
    m.status.text = "Finding titles on your services..."
    searchSuffix = ""
    if m.searchQuery <> ""
        encoder = CreateObject("roUrlTransfer")
        searchSuffix = "&q=" + encoder.Escape(m.searchQuery)
    end if
    runApiRequest("catalog", base + OptimusApiPath() + "?providers=" + serviceQuery + searchSuffix)
end sub

sub runApiRequest(requestType as String, url as String, method = "GET" as String, body = "" as String)
    print "[OPTIMUS] Request (" + requestType + "): " + url
    m.currentRequest = requestType
    m.apiTask.control = "STOP"
    m.apiTask.requestUrl = url
    m.apiTask.requestMethod = method
    m.apiTask.requestBody = body
    m.apiTask.authToken = m.authToken
    m.apiTask.responseComplete = false
    m.apiTask.control = "RUN"
end sub

sub onApiResponse()
    if not m.apiTask.responseComplete then return
    print "[OPTIMUS] Response (" + m.currentRequest + ") code=" + m.apiTask.responseCode.ToStr() + " body=" + Left(m.apiTask.responseBody, 160)
    if m.currentRequest = "providers"
        showProvidersResponse(m.apiTask.responseCode, m.apiTask.responseData)
    else if m.currentRequest = "catalog"
        showCatalogResponse(m.apiTask.responseCode, m.apiTask.responseData)
    else if m.currentRequest = "pair_start"
        showPairStart(m.apiTask.responseCode, m.apiTask.responseData)
    else if m.currentRequest = "pair_poll"
        showPairPoll(m.apiTask.responseCode, m.apiTask.responseData)
    else if m.currentRequest = "profile"
        showProfile(m.apiTask.responseCode, m.apiTask.responseData)
    else if m.currentRequest = "profile_save"
        if m.apiTask.responseCode >= 200 and m.apiTask.responseCode < 300 then m.status.text = "Your OPTIMUS account is synchronized."
    end if
end sub

sub showCatalogResponse(code as Integer, parsed as Dynamic)
    if code < 200 or code >= 300
        m.status.text = "API request failed (" + code.ToStr() + "). Check the API connection."
        m.catalogItems = []
        renderCurrentView()
        return
    end if
    items = extractItems(parsed)
    if items = invalid then items = []
    m.catalogItems = items
    m.status.text = items.Count().ToStr() + " titles available across your selected services"
    if m.profileNeedsInit and m.authToken <> ""
        m.watchlistTitles = []
        for each savedId in m.watchlist
            savedTitle = findCatalogItem(savedId)
            if savedTitle <> invalid then m.watchlistTitles.Push(savedTitle)
        end for
        m.profileNeedsInit = false
        saveProfile()
    end if
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

    if m.currentView = "account"
        m.section.text = "YOUR OPTIMUS ACCOUNT"
        m.status.text = "Connect this Roku to the account you use on the OPTIMUS website."
        m.pairCodeLabel.visible = false
        child = content.createChild("ContentNode")
        child.title = "Connect your OPTIMUS account"
        child.shortDescriptionLine1 = "Select to generate a secure pairing code"
        m.visibleIds.Push("connect")
    else if m.currentView = "services"
        m.pairCodeLabel.visible = false
        m.section.text = "MY SERVICES  ·  SELECT YOUR SUBSCRIPTIONS"
        m.status.text = "OK toggles a service. Selection is saved on this Roku."
        for each provider in m.providers
            child = content.createChild("ContentNode")
            selectionLabel = "ADD SERVICE"
            if hasValue(m.services, provider.id) then selectionLabel = "✓ SELECTED"
            child.title = provider.name
            child.shortDescriptionLine1 = selectionLabel
            m.visibleIds.Push(provider.id)
        end for
        if m.visibleIds.Count() = 0
            child = content.createChild("ContentNode")
            child.title = "No streaming services returned by API."
            m.visibleIds.Push("")
        end if
    else
        m.pairCodeLabel.visible = false
        if m.currentView = "watchlist"
            m.section.text = "MY WATCHLIST"
            m.status.text = "Your saved titles on this Roku"
        else
            m.section.text = "DISCOVER"
            if m.services.Count() = 0
                m.status.text = "Choose your streaming services to begin."
            else
                m.status.text = "Catalog · availability matched to My Services"
            end if
        end if

        itemsToRender = m.catalogItems
        if m.currentView = "watchlist" then itemsToRender = m.watchlistTitles
        for each item in itemsToRender
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
                posterPath = readString(item, "imageUrl")
                if posterPath <> "" and Left(posterPath, 4) <> "http"
                    child.hdPosterUrl = "https://image.tmdb.org/t/p/w500" + posterPath
                else if posterPath <> ""
                    child.hdPosterUrl = posterPath
                end if
                child.shortDescriptionLine1 = readString(item, "year") + "  ·  " + readString(item, "rating")
                m.visibleIds.Push(id)
            end if
        end for

        if m.visibleIds.Count() = 0
            child = content.createChild("ContentNode")
            if m.currentView = "watchlist"
                child.title = "Your watchlist is empty. Save a title from its detail page."
            else if m.services.Count() = 0
                child.title = "No services selected. Choose My Services to get started."
            else
                child.title = "No titles found for your selected services."
            end if
            m.visibleIds.Push("")
        end if
        if m.currentView = "watchlist" and m.visibleIds.Count() = 0
            child = content.createChild("ContentNode")
            child.title = "Your watchlist is empty. Save a title from its detail page."
            m.visibleIds.Push("")
        end if
    end if

    m.list.content = content
    m.list.visible = true
    m.list.setFocus(true)
end sub

sub onListSelected()
    index = m.list.itemSelected
    if index = invalid or index < 0 or index >= m.visibleIds.Count() then return

    if m.currentView = "account"
        startPairing()
        return
    end if

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
        if m.authToken <> "" then saveProfile()
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
        renderLaunchOptions(item)
    else
        m.detailTitle.text = "Loading title..."
        m.detailMeta.text = ""
        m.detailGenres.text = ""
        m.detailSynopsis.text = ""
        m.detailAvailability.text = ""
        m.launchIds = []
        m.launchOptions.content = CreateObject("roSGNode", "ContentNode")
        m.launchOptions.visible = false
        m.detailWatchHeader.text = "NO STREAMING APP MATCH AVAILABLE"
    end if
    openDetailView()

end sub

function findCatalogItem(id as String) as Dynamic
    for each item in m.catalogItems
        if readString(item, "id") = id then return item
    end for
    for each item in m.watchlistTitles
        if readString(item, "id") = id then return item
    end for
    return invalid
end function



function rokuChannelId(providerId as String, name as String) as String
    ' Roku channel IDs for common US streaming apps.
    if providerId = "8" then return "12"       ' Netflix
    if providerId = "9" then return "13"       ' Prime Video
    if providerId = "15" then return "2285"   ' Hulu
    if providerId = "337" then return "291097" ' Disney+
    if providerId = "350" then return "551012" ' Apple TV
    if providerId = "386" then return "593099" ' Peacock
    if providerId = "531" then return "31440"  ' Paramount+
    if providerId = "1899" then return "61322" ' Max
    normalized = LCase(name)
    if normalized = "netflix" then return "12"
    if normalized = "prime video" or normalized = "amazon prime video" then return "13"
    if normalized = "hulu" then return "2285"
    if normalized = "disney+" or normalized = "disney plus" then return "291097"
    if normalized = "apple tv+" or normalized = "apple tv plus" then return "551012"
    if normalized = "peacock" then return "593099"
    if normalized = "paramount+" or normalized = "paramount plus" then return "31440"
    if normalized = "max" or normalized = "hbo max" then return "61322"
    return ""
end function

sub renderLaunchOptions(item as Object)
    content = CreateObject("roSGNode", "ContentNode")
    m.launchIds = []
    if item.offers <> invalid
        for each offer in item.offers
            pid = readString(offer, "providerId")
            kind = readString(offer, "offerType")
            if kind = "subscription" and hasValue(m.services, pid)
                channelId = rokuChannelId(pid, providerName(pid))
                if channelId <> ""
                    child = content.createChild("ContentNode")
                    child.title = "Open " + providerName(pid)
                    m.launchIds.Push(channelId)
                end if
            end if
        end for
    end if
    m.launchOptions.content = content
    m.launchOptions.visible = m.launchIds.Count() > 0
    if m.launchIds.Count() > 0
        m.detailWatchHeader.text = "OPEN A STREAMING SERVICE"
    else
        m.detailWatchHeader.text = "APP LAUNCH NOT YET AVAILABLE FOR THESE SERVICES"
    end if
end sub

sub onLaunchSelected()
    index = m.launchOptions.itemSelected
    if index = invalid or index < 0 or index >= m.launchIds.Count() then return
    channelId = m.launchIds[index]
    m.detailEyebrow.text = "OPENING " + UCase(providerNameForChannel(channelId))
    m.launchTask.requestUrl = "http://127.0.0.1:8060/launch/" + channelId
    m.launchTask.control = "RUN"
end sub

function providerNameForChannel(channelId as String) as String
    if channelId = "12" then return "Netflix"
    if channelId = "13" then return "Prime Video"
    if channelId = "2285" then return "Hulu"
    if channelId = "291097" then return "Disney+"
    if channelId = "551012" then return "Apple TV"
    if channelId = "593099" then return "Peacock"
    if channelId = "31440" then return "Paramount+"
    if channelId = "61322" then return "Max"
    return "STREAMING APP"
end function

sub onLaunchResponse()
    code = m.launchTask.responseCode
    if code >= 200 and code < 400
        m.detailEyebrow.text = "STREAMING APP OPENED"
    else
        m.detailEyebrow.text = "COULD NOT OPEN APP — CHECK ROKU APP INSTALLATION"
    end if
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
        nextTitles = []
        for each savedItem in m.watchlistTitles
            if readString(savedItem, "id") <> m.selectedTitleId then nextTitles.Push(savedItem)
        end for
        m.watchlistTitles = nextTitles
        m.detailEyebrow.text = "REMOVED FROM WATCHLIST"
    else
        m.watchlist.Push(m.selectedTitleId)
        savedItem = findCatalogItem(m.selectedTitleId)
        if savedItem <> invalid then m.watchlistTitles.Push(savedItem)
        m.detailEyebrow.text = "SAVED TO WATCHLIST"
    end if
    saveRegistryList("watchlist", m.watchlist)
    if m.authToken <> "" then saveProfile()
end sub

sub openDetailView()
    m.browseGroup.visible = false
    m.detailGroup.visible = true
    if m.launchIds.Count() > 0
        m.launchOptions.setFocus(true)
    else
        m.top.setFocus(true)
    end if
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

    if key = "search" and m.browseGroup.visible and m.currentView <> "account"
        m.searchDialog.visible = false
        m.searchDialog.text = m.searchQuery
        m.top.dialog = m.searchDialog
        m.searchDialog.visible = true
        m.searchDialog.setFocus(true)
        return true
    else if key = "options"
        if m.currentView = "discover"
            m.currentView = "services"
        else if m.currentView = "services"
            m.currentView = "watchlist"
        else if m.currentView = "watchlist"
            m.currentView = "account"
        else
            m.currentView = "discover"
            loadCatalog()
            return true
        end if
        renderCurrentView()
        return true
    else if key = "back" and m.currentView = "account" and m.pairDeviceCode <> ""
        m.pairTimer.control = "STOP"
        m.pairDeviceCode = ""
        m.pairPolling = false
        m.pairCodeLabel.visible = false
        m.list.visible = true
        m.status.text = "Pairing cancelled."
        return true
    else if key = "back" and m.currentView <> "discover"
        m.currentView = "discover"
        loadCatalog()
        return true
    end if
    return false
end function


sub startPairing()
    base = OptimusApiBase()
    m.status.text = "Creating a secure device pairing code..."
    runApiRequest("pair_start", base + "/api/device/pair", "POST", "{}")
end sub

sub showPairStart(code as Integer, data as Dynamic)
    if code < 200 or code >= 300
        m.status.text = "Could not start account pairing (" + code.ToStr() + ")."
        return
    end if
    m.pairDeviceCode = readString(data, "deviceCode")
    userCode = readString(data, "userCode")
    if m.pairDeviceCode = "" or userCode = ""
        m.status.text = "The server returned an incomplete pairing code."
        return
    end if
    m.pairCodeLabel.text = "GO TO OPTIMUS ON YOUR PHONE OR COMPUTER\nOPEN YOUR ACCOUNT → CONNECT YOUR ROKU\n\n" + userCode
    m.pairCodeLabel.visible = true
    m.list.visible = false
    m.top.setFocus(true)
    m.status.text = "This code expires in 10 minutes. Waiting for approval..."
    m.pairPolling = false
    m.pairTimer.control = "START"
end sub

sub onPairTimer()
    if m.pairDeviceCode = "" or m.pairPolling then return
    m.pairPolling = true
    body = FormatJson({ deviceCode: m.pairDeviceCode })
    runApiRequest("pair_poll", OptimusApiBase() + "/api/device/pair/token", "POST", body)
end sub

sub showPairPoll(code as Integer, data as Dynamic)
    m.pairPolling = false
    if code = 202 then return
    if code < 200 or code >= 300
        m.pairTimer.control = "STOP"
        m.pairPolling = false
        m.status.text = "Pairing expired or failed. Select Connect account to try again."
        m.pairDeviceCode = ""
        m.pairCodeLabel.visible = false
        m.list.visible = true
        return
    end if
    token = readString(data, "token")
    if token = "" then return
    m.pairTimer.control = "STOP"
    m.pairDeviceCode = ""
    m.pairPolling = false
    m.authToken = token
    m.registry.Write("authToken", token)
    m.registry.Flush()
    m.pairCodeLabel.visible = false
    m.list.visible = true
    m.status.text = "Account connected. Loading your services and watchlist..."
    loadProfile()
end sub

sub loadProfile()
    runApiRequest("profile", OptimusApiBase() + "/api/profile")
end sub

sub showProfile(code as Integer, data as Dynamic)
    if code = 401
        m.authToken = ""
        m.registry.Write("authToken", "")
        m.registry.Flush()
        m.currentView = "account"
        m.status.text = "Your OPTIMUS device session expired. Connect your account again."
        renderCurrentView()
        return
    else if code < 200 or code >= 300
        m.status.text = "Your account connected, but its profile could not be loaded."
        return
    end if
    profile = data.profile
    if profile = invalid
        m.profileNeedsInit = true
    else
        m.profileNeedsInit = false
        if profile.providers <> invalid then m.services = profile.providers
        m.watchlist = []
        m.watchlistTitles = []
        if profile.watchlist <> invalid
            for each item in profile.watchlist
                id = readString(item, "id")
                if id <> ""
                    m.watchlist.Push(id)
                    m.watchlistTitles.Push(item)
                end if
            end for
        end if
        saveRegistryList("services", m.services)
        saveRegistryList("watchlist", m.watchlist)
    end if
    m.currentView = "discover"
    loadCatalog()
end sub

sub saveProfile()
    payload = { providers: m.services, watchlist: m.watchlistTitles }
    runApiRequest("profile_save", OptimusApiBase() + "/api/profile", "PUT", FormatJson(payload))
end sub

sub onSearchButton()
    if m.searchDialog.buttonSelected = 0
        m.searchQuery = m.searchDialog.text
        m.currentView = "discover"
        loadCatalog()
    end if
    m.searchDialog.visible = false
    m.list.setFocus(true)
end sub
