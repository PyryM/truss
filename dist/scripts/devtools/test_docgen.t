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

  func "foobars"
  args { string 'black_box', enum{'thingy', options={'petrol', 'cheese'}, default='cheese'} }
  returns { string 'mystery' }
  description "who knows what this function does"

  module "testmodule"
  func "solve_something_else"
  description "Solve something else"
  args {
    bool{'obvious_arg', default = 12.0},
    number{'another_arg', optional = true},
    string{'arg3: tokyo drift', default = 'vin diesel'}
  }
  returns {string 'hmmmm'}

  func "something_complicated"
  table_args{
    rbg_write = bool{'write color to target', default = true},
    depth_write = bool{'write depth to target', default = true},
    alpha_write = bool{'write alpha to target', default = true},
    should_petrol = enum{'whether to petrol', options={'petrol', 'cheese'}, default='cheese'}
  }
  description "Has complicated arguments"
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
  parser:parse_file("scripts/gfx/doc.lua")

  -- log.info(json:encode(parser:get_modules()))
  log.info(htmlgen(parser:get_modules(), {
    css = {"testo.css", "prism.css"},
    scripts = {"prism.js"}
  }))
end

function update()
  truss.quit()
end