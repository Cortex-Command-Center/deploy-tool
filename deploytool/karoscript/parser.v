// Copyright (C) 2022 Wazubaba
// 
// Karoscript is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// Karoscript is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with gmb2. If not, see <http://www.gnu.org/licenses/>.

module karoscript
import os
import strings

/// Callback type for non-userdata parse.
pub type LineCB = fn (string, string) ?

/// Callback type for userdata parse.
pub type LineCB_UD =  fn (mut voidptr, string, string) ?

/// Parser state
pub struct Parser
{
	// Callback per line
	linecb LineCB

	// Ditto, but with userdata
	linecbud LineCB_UD
mut:
	line int
	char int
	userdata voidptr
}

[params]
pub struct ParseFileParams
{
	path string
	last string
	seen []string
	threadsafe bool
}

fn (this Parser) er(m string) IError
{
	{ return error('$m ($this.line, $this.char)') }
}

/// Instance a new parser with the given non-userdata callback.
pub fn new_parser(cb LineCB) Parser
{
	return Parser{linecb: cb}
}

/// Instance a new parser with the given userdata-supported callback.
pub fn new_parser_with_userdata(userdata voidptr, cb LineCB_UD) Parser
{
	return Parser{userdata: userdata, linecbud: cb}
}

/// Parse the file, invoking your callback for each line of key = value.
pub fn (mut this Parser) parse_file(path string)?
{
	this.parse_impl(ParseFileParams{path: path}) ?
}

/// Thread-safe parse of a file. Be warned you must still ensure safety
/// with your callback for R/W of your userdata, if used.
pub fn (mut this Parser) thread_safe_parse_file(path string) ?
{
	this.parse_impl(ParseFileParams{path: path, threadsafe: true}) ?
}


fn (mut this Parser) parse_impl(c ParseFileParams) ?
{
	if !c.threadsafe
	{
		// Safety to avoid recursive include (not perfect)
		if c.last == c.path || c.path in c.seen
			{ return this.er('Recursive include detected [$c.last->$c.path]') }
	}
	mut buffer := strings.new_builder(0)
	mut flag := false
	mut key := ''
	mut val := ''

	mut data := []string{}

	if !c.threadsafe
	{
		data = os.read_lines(c.path) or
		{
			msg := 'No readable file $c.path' + if c.last != '' { '[$c.last]' } else { '' }
			return this.er(msg)
		}
	} else {
		data = os.read_lines(c.path) ?
	}


	outer: for line in data
	{
		if !c.threadsafe
		{
			this.line ++
			this.char = 0
		}

		if line.len == 0
			{ continue }

		if line.trim_space().len == 0 
			{ continue }

		if line[0] == `\$`
		{
			// Handle directives
			dir := line[1..line.len].to_lower()
			params := dir.split(' ')
			mut seen := []string{}
			if params[0] == 'include'
			{
				if params.len < 2
					{ return if !c.threadsafe { this.er('Missing include path for directive') } else { error('Missing include path for directive') } }
				
				if !c.threadsafe
				{
					seen = c.seen.clone()
					seen << c.path
				}
				// Concat the params since paths can have spaces
				newpath := params[1..params.len].join(' ').split('#')[0].trim_space()
				this.parse_impl(ParseFileParams{newpath, c.path, seen, c.threadsafe})?
			}
		} else {
			for ch in line
			{
				if !c.threadsafe
					{ this.char ++ }
				match ch
				{
					`#`
					{
						if buffer.len == 0
							{ continue outer }
						else
							{ break }
						
					}
					`=`
					{
						key = buffer.str().trim_space()
						flag = true
						buffer.clear()
					}
					else
					{
						buffer.write_rune(ch)
					}
				}
			}

			if !flag
				{ return if !c.threadsafe { this.er('Missing value') } else { error('Missing value') } }
			
			val = buffer.str().trim_space()

			if this.userdata != 0
			{
				this.linecbud(mut this.userdata, key, val) or
					{ if !c.threadsafe { return this.er('Parse aborted: $err @$c.path') } else { return error('Parse aborted: $err @$c.path') } }
			}
			else
			{
				this.linecb(key, val) or
					{ if !c.threadsafe { return this.er('Parse aborted: $err @$c.path') } else { return error('Parse aborted: $err @$c.path')}}
			}

			flag = false
			key = ''
			val = ''
			buffer.clear()
			if !c.threadsafe
				{ this.char = 0 }
		}
	}
}