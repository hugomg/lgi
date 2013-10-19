--[[--------------------------------------------------------------------------

  LGI testsuite, GLib test suite.

  Copyright (c) 2013 Pavel Holejsovsky
  Licensed under the MIT license:
  http://www.opensource.org/licenses/mit-license.php

--]]--------------------------------------------------------------------------

local lgi = require 'lgi'

local check = testsuite.check

-- Basic GLib testing
local glib = testsuite.group.new('glib')

function glib.timer()
   local Timer = lgi.GLib.Timer
   check(Timer.new)
   check(Timer.start)
   check(Timer.stop)
   check(Timer.continue)
   check(Timer.elapsed)
   check(Timer.reset)
   check(not Timer.destroy)

   local timer = Timer()
   check(Timer:is_type_of(timer))
   timer = Timer.new()
   check(Timer:is_type_of(timer))

   local el1, ms1 = timer:elapsed()
   check(type(el1) == 'number')
   check(type(ms1) == 'number')

   for i = 1, 1000000 do end

   local el2, ms2 = timer:elapsed()
   check(el1 < el2)

   timer:stop()
   el2 = timer:elapsed()
   for i = 1, 1000000 do end
   check(timer:elapsed() == el2)
end

function glib.markup_base()
   local MarkupParser = lgi.GLib.MarkupParser
   local MarkupParseContext = lgi.GLib.MarkupParseContext

   local p = MarkupParser()
   local el, at = {}, {}
   function p.start_element(context, element_name, attrs_names, attrs_values)
      el[#el + 1] = element_name
      at[#at + 1] = { names = attrs_names, values = attrs_values }
   end
   function p.end_element(context)
   end
   function p.text(context, text, len)
   end
   function p.passthrough(context, text, len)
   end

   local pc = MarkupParseContext(p, {})
   local ok, err = pc:parse([[
<map>
 <entry key='method' value='printf' />
</map>
]])
   check(ok)
   check(#el == 2)
   check(el[1] == 'map')
   check(el[2] == 'entry')
   check(#at == 2)
   check(#at[1].names == 0)
   check(#at[1].values == 0)
   check(#at[2].names == 2)
   check(at[2].names[1] == 'key')
   check(at[2].names[2] == 'value')
   check(at[2].names.key == 'method')
   check(at[2].names.value == 'printf')
   check(#at[2].values == 2)
   check(at[2].values[1] == 'method')
   check(at[2].values[2] == 'printf')
end

function glib.markup_error1()
   local MarkupParser = lgi.GLib.MarkupParser
   local MarkupParseContext = lgi.GLib.MarkupParseContext

   local saved_err
   local parser = MarkupParser {
      error = function(context, error)
	 saved_err = error
      end,
   }
   local context = MarkupParseContext(parser, 0)
   local ok, err = context:parse('invalid>uh')
   check(not ok)
   check(err == saved_err.message)
end

function glib.markup_error2()
   local MarkupParser = lgi.GLib.MarkupParser
   local MarkupParseContext = lgi.GLib.MarkupParseContext

   local saved_err
   local parser = MarkupParser {
      error = function(context, error)
	 saved_err = error
      end,
      start_element = function(context, element)
	 error('snafu', 0)
      end,
   }
   local context = MarkupParseContext(parser, {})
   local ok, err = context:parse('<e/>')
   check(not ok)
   check(err == 'snafu')
   check(saved_err.message == err)

   saved_err = nil
   function parser.start_element(context, element)
      return false, 'snafu'
   end
   context = MarkupParseContext(parser, {})
   ok, err = context:parse('<e/>')
   check(not ok)
   check(err == 'snafu')
   check(saved_err.message == err)
end
