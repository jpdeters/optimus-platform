sub init()
  m.poster = m.top.findNode("poster")
  m.cardBack = m.top.findNode("cardBack")
  m.cardTitle = m.top.findNode("cardTitle")
  m.cardMeta = m.top.findNode("cardMeta")
  m.captionBack = m.top.findNode("captionBack")
  m.focusLine = m.top.findNode("focusLine")
  m.fallbackPanel = m.top.findNode("fallbackPanel")
  m.fallbackMark = m.top.findNode("fallbackMark")
  updateLayout()
end sub

sub updateLayout()
  w = m.top.width
  h = m.top.height
  if w <= 0 or h <= 0 then return
  posterHeight = h * 0.70
  captionHeight = h - posterHeight
  m.cardBack.width = w
  m.cardBack.height = h
  m.fallbackPanel.width = w
  m.fallbackPanel.height = posterHeight
  m.fallbackMark.width = w
  m.fallbackMark.height = posterHeight
  m.fallbackMark.translation = [0, (posterHeight - 100) / 2]
  m.poster.width = w
  m.poster.height = posterHeight
  m.captionBack.translation = [0, posterHeight]
  m.captionBack.width = w
  m.captionBack.height = captionHeight
  m.cardTitle.translation = [13, posterHeight + 10]
  m.cardTitle.width = w - 26
  m.cardMeta.translation = [13, posterHeight + 46]
  m.cardMeta.width = w - 26
  m.focusLine.translation = [0, h - 4]
  m.focusLine.width = w
end sub

sub showContent()
  item = m.top.itemContent
  if item = invalid then return
  m.cardTitle.text = item.title
  m.cardMeta.text = item.shortDescriptionLine1
  if item.hdPosterUrl <> invalid and item.hdPosterUrl <> ""
    m.poster.uri = item.hdPosterUrl
    m.poster.visible = true
    m.fallbackPanel.visible = false
    m.fallbackMark.visible = false
  else
    m.poster.uri = ""
    m.poster.visible = false
    m.fallbackPanel.visible = true
    m.fallbackMark.visible = true
    if item.title <> invalid and item.title <> "" then m.fallbackMark.text = Left(item.title, 1)
  end if
end sub

sub showFocus()
  m.focusLine.visible = m.top.itemHasFocus
end sub
