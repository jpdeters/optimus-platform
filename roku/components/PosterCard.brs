sub init()
  m.poster = m.top.findNode("poster")
  m.cardTitle = m.top.findNode("cardTitle")
  m.cardMeta = m.top.findNode("cardMeta")
  m.focusLine = m.top.findNode("focusLine")
  m.top.observeField("itemContent", "showContent")
end sub

sub showContent()
  item = m.top.itemContent
  if item = invalid then return
  m.cardTitle.text = item.title
  m.cardMeta.text = item.metaText
  if item.posterUrl <> invalid and item.posterUrl <> ""
    m.poster.uri = item.posterUrl
    m.poster.visible = true
  else
    m.poster.uri = ""
    m.poster.visible = false
  end if
end sub