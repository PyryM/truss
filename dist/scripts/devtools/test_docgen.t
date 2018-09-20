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

  -- local minimarkdown = require("devtools/minimarkdown.t")
  -- local test_p = [[
  -- asdfas adklfja dflja;dlsf jadfkj aldfk as `code goes here` asdkalsjdflaskdjf
  -- {{link.png}}{{otherlink.png}} *emphasis*

  -- this is paragraph *#2*: {{linkadoodle}}  
  -- ]]

  -- local resolver = function(t)
  --   return t, t .. ".html"
  -- end

  -- local generated_html = minimarkdown.to_html(test_p, resolver)
  -- print(tostring(generated_html))

  -- if true then return end

  local docgen = require("devtools/docgen.t")
  local htmlgen = require("devtools/htmldocgen.t")

  local parser = docgen.LiterateParser()
  --parser:parse_string(test_doc_string)
  local sections = parser:parse_file("scripts/examples/new_basic.t")

  -- log.info(json:encode(parser:get_modules()))
  local genhtml = parser:generate_html(sections, {
    css = {"trusslit.css", "prism.css"},
    scripts = {"prism.js"}
  })

  local dest = io.open("../docs/lit.html", "w")
  dest:write(genhtml)
  dest:close()
end

function update()
  truss.quit()
end