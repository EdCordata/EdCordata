function Header(el)
  if el.level == 2 then
    local start = pandoc.RawInline("latex", "{\\color[HTML]{8E44AD}")
    local finish = pandoc.RawInline("latex", "}")
    local inlines = {start}

    for _, inline in ipairs(el.content) do
      table.insert(inlines, inline)
    end

    table.insert(inlines, finish)

    return pandoc.Header(el.level, inlines, el.attr)
  end
end
