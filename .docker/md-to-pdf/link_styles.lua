function Link(el)
  local text = pandoc.utils.stringify(el.content)

  return pandoc.RawInline(
    "latex",
    "{\\textcolor[HTML]{2F5D8A}{\\href{" .. el.target .. "}{" .. text .. "}}}"
  )
end
