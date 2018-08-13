local json = require("lib/json.lua")

function init()
  local test_doc_string = [=[
  module "testmodule"
  func "solve_quadratic"
  description "Solve a quadratric equation"
  args {
    number 'a: first coeff', 
    number 'b: second coeff', 
    number 'c: third coeff'
  }
  returns {number 'first root or nil', number 'second root or nil'}

  module "othermodule"
  func "whatever"
  description "has some mysterious side effects"

  module "testmodule"
  func "solve_something_else"
  description "Solve something else"
  args {
    bool 'obvious_arg'
  }
  returns {string 'hmmmm'}
  ]=]

  local docgen = require("devtools/docgen.t")
  local htmlgen = require("devtools/htmldocgen.t")

  local html = require("devtools/htmlgen.t")
  local doc = html.body{
    html.section{
      html.h1{"Hello there!"},
      html.p{"This is some text inside of a paragraph."},
      html.p{"This is also inside of a paragraph."},
      html.ul{
        html.li{"Item 1"},
        html.li("Item 2"),
        html.li{"Item 3", " continuation?"}
      }
    }
  }

  log.info(tostring(doc))

  local parser = docgen.DocParser()
  parser:parse_string(test_doc_string)

  -- log.info(json:encode(parser:get_modules()))
  log.info(htmlgen(parser:get_modules()))
end

function update()
  truss.quit()
end