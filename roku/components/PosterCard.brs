sub init()
  m.poster = m.top.findNode("poster")
  m.cardTitle = m.top.findNode("cardTitle")
  m.cardMeta = m.top.findNode("cardMeta")
  m.focusLine = m.top.findNode("focusLine")
  m.top.observeField("itemContent", "showContent")
  m.top.observeField("itemHasFocus", "showFocus")
end sub

sub showContent()
  item = m.top.itemContent
  if item = invalid then return
  m.cardTitle.text = item.title
  m.cardMeta.text = item.shortDescriptionLine1
  if item.hdPosterUrl <> invalid and item.hdPosterUrl <> ""
    m.poster.uri = item.hdPosterUrl
    m.poster.visible = true
  else
    m.poster.uri = ""
    m.poster.visible = false
  end if
end sub
sub showFocus()
  m.focusLine.visible = m.top.itemHasFocus
end sub
