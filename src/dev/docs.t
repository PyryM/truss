-- dev/docs.t
--
-- 'main' file to generate docs

local futils = require("util/file.t")
local docgen = require("dev/docgen.t")
local htmlgen = require("dev/htmldocgen.t")

function init()
  local parser = docgen.DocParser()

  local file_filter = futils.filter_file_prefix("_doc")
  local path = {"scripts", truss.args[3]}
  for path in futils.iter_walk_files(path, nil, file_filter) do
    parser:parse_file(table.concat(path, "/"))
  end

  --<link href="https://fonts.googleapis.com/css?family=Fira+Mono" rel="stylesheet"> 

  local generated_html = htmlgen(
    parser:get_modules(), {
      css = {"trussdoc.css", "prism.css", "https://fonts.googleapis.com/css?family=Fira+Mono"},
      scripts = {"prism.js"}
    }
  )

  local dest = io.open("../docs/testo.html", "w")
  dest:write(generated_html)
  dest:close()
end

function update()
  truss.quit()
end