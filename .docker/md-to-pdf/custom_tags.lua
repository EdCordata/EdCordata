local function get_attr(el, key)
  return el.attributes and el.attributes[key]
end

local function is_spacer(html)
  return html:match('class="spacer"') or html:match("class='spacer'")
end

local function is_pagebreak(html)
  return html:match('class="pagebreak"') or html:match("class='pagebreak'")
end

function Div(el)
  if el.classes:includes("pagebreak") then
    return pandoc.RawBlock("latex", "\\newpage")
  end

  if el.classes:includes("spacer") then
    local lines = tonumber(el.attributes["data-lines"]) or 2
    return pandoc.RawBlock(
      "latex",
      "\\vspace*{" .. lines .. "\\baselineskip}"
    )
  end
end

function RawInline(el)
  if el.format == "html" then
    if is_pagebreak(el.text) then
      return pandoc.RawInline("latex", "\\newpage")
    end

    if is_spacer(el.text) then
      local lines = el.text:match('data%-lines="(%d+)"') or "2"
      return pandoc.RawInline(
        "latex",
        "\\vspace*{" .. lines .. "\\baselineskip}"
      )
    end
  end
end

function RawBlock(el)
  if el.format == "html" then
    if is_pagebreak(el.text) then
      return pandoc.RawBlock("latex", "\\newpage")
    end

    if is_spacer(el.text) then
      local lines = el.text:match('data%-lines="(%d+)"') or "2"
      return pandoc.RawBlock(
        "latex",
        "\\vspace*{" .. lines .. "\\baselineskip}"
      )
    end
  end
end
