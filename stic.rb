#! /usr/bin/env ruby
# stic.rb -- Sanity-To-Insanity Converter
# Copyright (C) 2017 Wolfgang Jaehrling
#
# ISC License
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# read config that maps classes to tags
$tags = {}
src = File.new('html-tags')
while line = src.gets
  the_class, tag = line.split
  $tags[the_class] = tag
end
def tag4class(the_class)
  $tags[the_class] || :div
end

# this helper class makes the parser quite simple
class StrScan
  def initialize(str)
    @str = str
    @pos = 0
  end

  def end?
    @pos == @str.size
  end

  def skip
    @pos += 1 unless end?
  end

  def rest
    @str[@pos..-1]
  end

  def head
    @str[@pos]
  end

  def while(regex)
    result = ''
    while !end?
      if !(head =~ regex)
        return result
      end
      result += head
      @pos += 1
    end
    result
  end
end

# we want properly indented HTML
$indent = 0
def emit(str)
  puts ('  ' * $indent) + str
end

# little bit of dynamic scoping for convenience
$src, $open_nodes = nil, nil
$param_stack = []
def with_src(new_src, new_params = {})
  old_src, old_open_nodes = $src, $open_nodes
  $src, $open_nodes = new_src, []
  $param_stack.push(new_params)
  yield
  $src, $open_nodes = old_src, old_open_nodes
  $param_stack.pop
end

def lookup_variable(var)
  $param_stack.reverse_each do |locals|
    if locals[var]
      return locals[var]
    end
  end
  ''
end

def substitute_vars(str)
  str.gsub(/\$[-_a-zA-Z0-9.]+/) { |match| lookup_variable(match[1..-1]) }
end

def scan_value(scan)
  case scan.head
  when "'"
    scan.skip
    result = scan.while(/[^']/)
    scan.skip
    substitute_vars(result)
  when '"'
    scan.skip
    result = scan.while(/[^"]/)
    scan.skip
    substitute_vars(result)
  when '$'
    scan.skip
    var = scan.while(/[-_a-zA-Z0-9.]/)
    lookup_variable(var)
  else
    scan.while(/[^ )]/)
  end
end

def scan_attrs(scan)
  scan.while(/ /)
  attrs = {}
  if scan.head == '('
    scan.skip # drop paren
    loop do
      scan.while(/[ ,]/)
      if scan.head == ')'
        scan.skip # drop paren
        break
      end
      name = scan.while(/[^:=]/) # using `=` by mistake is common, so handle gracefully
      scan.skip # drop colon or equal sign
      scan.while(/ /)
      value = scan_value(scan)
      attrs[name] = value
    end
  end
  attrs
end

def attrs2html(attrs)
  result = ''
  attrs.each do |key, val|
    result += " #{key}=\"#{val}\""
  end
  result
end

def rep_nodes
  while line = $src.gets
    line.strip!
    line.sub!(/;;.*$/, '')
    case line[0]
    when '.', '%'
      scan = StrScan.new(line)
      if scan.head == '%'
        scan.skip
        tag = scan.while(/[-_a-zA-Z0-9$]/)
      end
      if scan.head == '.'
        scan.skip # drop first dot
        classes = scan.while(/[-_a-zA-Z0-9.$]/).split('.').map { |c| substitute_vars(c) }
        tag ||= tag4class(classes.first)
      else
        classes = []
      end
      attrs = scan_attrs(scan)
      if classes.any?
        tag_start = "#{tag} class=\"#{classes.join(' ')}\"#{attrs2html(attrs)}"
      else
        tag_start = "#{tag}#{attrs2html(attrs)}"
      end
      scan.while(/ /)
      case scan.head
      when '{'
        emit "<#{tag_start}>"
        $indent += 1
        $open_nodes.push(tag)
        rep_nodes
        raise 'internal mismatch' unless tag == $open_nodes.pop
        $indent -= 1
        emit "</#{tag}>"
      when nil
        emit "<#{tag_start} />"
      else
        emit "<#{tag_start}>#{substitute_vars(scan.rest)}</#{tag}>"        
      end
    when '@'
      scan = StrScan.new(line)
      scan.skip # drop at-sign
      identifier = scan.while(/[-_a-zA-Z0-9.$]/)
      attrs = scan_attrs(scan)
      if identifier == 'CONTENT'
        lookup_variable(' BLOCK ').call
      else
        filename = substitute_vars(identifier) + '.stic'
        scan.while(/ /)
        if scan.head == '{'
          src4block, locals4block = $src, $param_stack.last
          attrs[' BLOCK '] = lambda do
            with_src(src4block, locals4block) do
              $open_nodes.push(:BLOCK)
              rep_nodes
            end
          end
        elsif scan.head != nil
          raise 'trailing garbage after module inclusion'
        end
        with_src(File.new(filename), attrs) do
          rep_nodes
        end
      end
    when '}'
      raise 'unmatched }' unless $open_nodes.size > 0
      return
    when nil
      nil # empty line, do nothing
    else
      emit substitute_vars(line)
    end
  end
end

raise 'no file name given (or too many)' unless ARGV.size == 1
with_src(File.new(ARGV.first)) do
  emit '<!DOCTYPE html>'
  rep_nodes
end
