" -*- vim -*-
" vim:sts=2:sw=2:ff=unix:
" FILE: "D:\vim\foo.vim"
" LAST MODIFICATION: "Tue, 06 Aug 2002 09:30:33 Eastern Daylight Time ()"
" (C) 2000, 2001, 2002 by Benji Fisher, <benji@member.ams.org>

" This file contains relatively short functions and a few commands and
" mappings for vim.  Many of these were written in response to questions
" posted on the vim mailing list.  As a result (if I do say so myself)
" there are a lot of clever ideas in this file.
"
" The examples are organized chronologically, which means that the ones near
" the beginning are not necessarily the best ones to start with.  I hope the
" following table of contents will help.  If you see something that looks
" interesting, position the cursor on the function name and use the * command.
" (Most of my examples involve functions; some also involve maps, commands,
" autocommands, etc.)

" Most of this file was written for vim 5.x, so several things could be
" simplified with new features of vim 6.0, such as :map <local> and
" :map <silent>.

" *** Table of Contents ***

" fun! DoSp(str)
"   Purpose:  interpret special characters, such as <C-U>, in a string.
"   Techniques:  argument syntax, substitute() function
" fun! EvalInput(string)
"   Purpose:  Same as DoSp()
"   Techniques:  scratch buffer, :normal with control characters, @"
" fun! HTMLmatch()
"   Purpose:  Find matching HTML tags (baby version of matchit.vim)
"   Techniques:  :if ... :endif, character under the cursor
" fun! ClassHeader(leader)
"   Purpose:  Insert a fancy comment line whenever a C++ class is started.
"   Techniques:  :autocmd, :imap, :normal with control characters
" command! -nargs=* Line
" command! -nargs=* Range
"   Purpose:  Use one or two variables to give a line or range to a command.
"   Techniques:  :command, <q-args>, substitute(), :execute
" fun! Mark(...)
" fun! Line(mark)
" fun! Virtcol(mark)
"   Purpose:  Use (local) variables to store marks, restore cursor and screen.
"   Techniques:  variable number of arguments, parsing with =~, substitute()
" fun! Pippo(...) range
"   Purpose:  Append words matching a given pattern to a file.
"   Techniques:  :function with a range, variable number of arguments, :copy
" fun! LastNonBlank()
"   Purpose:  Move the cursor to the last non-blank on the line; ^ in reverse.
"   Techniques:  matchend(), positioning the cursor with :normal
" fun! StripTag(pattern)
"   Purpose:  Tag search on "foo" if the current word is "xxxfoo".
"   Techniques:  expand(), <cword>, =~, :normal with control characters
" fun! JS_template()
"   Purpose:  Insert a JavaScript template at the magic string "<scr"
"   Techniques:  :autocmd, mode switching, :append
" fun! LineUpLT()
"   Purpose:  Automatically align C++ << operators.
"   Techniques:  :autocmd, mode switching, manually adjusting indent
" fun! Count(pat)
"   Purpose:  Count the number of lines matching the input pattern.
"   Techniques:  :g, returning a value, :execute
" fun! ShowHi()
"   Purpose:  Show the colors of all highlight groups.
"	Oops, we reinvented the wheel!  See $VIMRUNTIME/hitest.vim .
"   Techniques:  saving and restoring an option, scratch buffer, :redir, etc.
" fun! EditFun(name)
"   Purpose:  Edit a vim function in a scratch buffer.
"   Techniques:  pretty much the same as ShowHi()
" fun! GetModelines(pat, ...)
"   Purpose:  Get information stored in comments (modelines) in the buffer.
"   Techniques:  variable number of arguments, :silent (vim 6.0), complex :g
" fun! VarTab(c, ...)
"   Purpose:  Define tab stops at arbitrarily spaced columns.
"   Techniques:  getting the value of a function without leaving Insert mode,
"     looping over variable number of arguments
" fun! SmartBS(pat)
"   Purpose:  Delete HTML constructs like "&foo;" as a single character.
"   Techniques:  Insert-mode mapping that works at start, middle, end of line
" fun! Transform(old, new, ...)
"   Purpose:  Perform multiple simple substitutions.
"   Transform:  :while loop, getline() and setline()
" fun! Search(pat)
"   Purpose:  Search for a pattern and slect it in Select mode.
"   Techniques:  :command, :execute, mode switching
" fun! Capitalize()
"   Purpose:  Make "_" act like a Caps Lock key in Insert mode.
"   Techniques:  store a flag as a buffer variable, mode switching
" inoremap <LeftMouse>
"   Purpose:  Keep mode (Insert or Normal) attached to a window.
"   Techniques:  window variables, Command mode inside a mapping
" command! Echo
"   Purpose:  Echo a command, then execute it.  Useful for making a log of
"   your Command-mode session.
" command! Iabbr
"   Purpose:  Define an Insert-mode abbreviation that "eats" the space that
"   triggers it.
" fun! Getchar()
"   Purpose:  like getchar() but always return a String.  Used by
"   Eatchar() and GetMotion().
"   Techniques:  getchar(), nr2char()
" fun! Eatchar(pat)
"   Purpose:  This is a helper function for :Iabbr .
" fun! Yank()
"   Purpose:  Example for using GetMotion() to remap an operator.
" fun! GetMotion(char)
"   Purpose:  Capture a sequence of characters that define a motion.  This is
"   useful when redefining operators, such as y (yank).
"   Techniques:  getchar(), while
" fun! Common(str1, str2)
"   Purpose:  Return the common initial part of two strings.
"   Techniques:  matchend(), strpart(), while
" fun! TWIN()
"   Purpose:  Prompt for input, and insert something in the file.
"   Techniques:  input(), append(), :normal, switching modes.

" Since I experiment a lot with this file, I want to avoid having
" duplicate autocommands.
augroup Foo
  autocmd!
augroup END

" This is the beginning of a function for taking an input string and
" returning the value after "special characters" have been evaluated:
" <C-U> erases all previous input.  One might also want to implement
" <C-W> and others.
fun! DoSp(str)
  let s = substitute(a:str, '.*\<C-U>', "", "")
  return s
endfun

" This function evaluates the input string in Input mode.  Special
" characters, such as <C-U> and <C-N> will be executed in Input mode.
" Raw <Esc> characters will produce unpredictable results.
fun! EvalInput(string)
  new
  execute "normal a" . a:string . "\<Esc>ggyG"
  q!
  return @"
endfun

" Use with  :nmap % :call HTMLmatch()
" If the cursor is on a non-alphabetic character then invoke the normal
" behavior of %.  If the cursor is on an alphabetic character, attempt to
" jump from <tag> to </tag> and back.  This is just a quick demo; it does
" not deal with nesting.  For a more complete version, see matchit.vim .
fun! HTMLmatch()
  if getline(".")[col(".")-1] !~ "\\a"
    normal! %
    return
  endif
  execute "normal ?\\A\<CR>"
  normal lye
  if getline(".")[col(".")-2] == '/'
    execute 'normal ?<\s*' . @" . "\<CR>l"
  else
    execute 'normal /<\s*\/' . @" . "\<CR>ll"
  endif
endfun

" Insert a header every time you begin a new class in C++ .
augroup Foo
  autocmd BufEnter *.cpp,*.h inoremap { {<Esc>:call ClassHeader("-")<CR>a
  autocmd BufLeave *.cpp,*.h iunmap {
  " Keep your braces balanced!}}}
augroup END
fun! ClassHeader(leader)
  if getline(".") !~ "^\\s*class"
    return
  endif
  normal yyP$x
  let width = 80
  if exists("&tw")
    let width = &tw
  endif
  execute "normal " . (width-virtcol(".")-3) . "I" . a:leader . "\<Esc>"
  execute "normal a \<Esc>"
  execute "normal I//\<Esc>"
  " Keep your braces balanced!{
  execute "normal! jo};\<Esc>"
  normal k$
endfun

" This is my first user-defined command.  Unlike a user-defined function,
" a command can be called from the function Foo() and have access to the
" local variables of Foo().
" Usage:  :let foo = 1 | Line foo s/foo/bar
" Usage:  :let foo = 1 | let bar = 3 | Line foo,bar s/foo/bar
" You can also do ":Line foo+1 s/foo/bar" or "Line foo-1,bar+1 ..."
" There must be no spaces in "foo,bar".
command! -nargs=* Line
	\ | let Line_range = matchstr(<q-args>, '\S\+')
	\ | let Line_range = "(" . substitute(Line_range, ",", ").','.(", "") . ")"
	\ | execute "let Line_range = " . Line_range
	\ | execute Line_range . substitute(<q-args>, '\S\+', "", "")
	\ | unlet Line_range
" Example:  If foo=2 and bar=3 and you do ":Line foo-1,bar+1 s/foo/bar" then
" 1. Line_range = "foo-1,bar+1"
" 2. Line_range = "(foo-1).','.(bar+1)"
" If there is no comma then this step has no effect.
" 3. Line_range = "1,4"
" 4. 1,4 s/foo/bar

" Usage:  :let foo = 1 | let bar = 3 | Range foo bar s/foo/bar
command! -nargs=* Range
	\ | execute substitute(<q-args>, '\(\S\+\)\s\+\(\S\+\)\(.*\)',
		\ 'let Range_range=\1.",".\2', "")
	\ | execute Range_range . substitute(<q-args>, '\S\+\s\+\S\+', "", "")
	\ | unlet Range_range

" Usage:  :let ma = Mark() ... execute ma
" has the same effect as  :normal ma ... :normal 'a
" without affecting global marks.
" You can also use Mark(17) to refer to the start of line 17 and Mark(17,34)
" to refer to the 34'th (screen) column of the line 17.  The functions
" Line() and Virtcol() extract the line or (screen) column from a "mark"
" constructed from Mark() and default to line() and virtcol() if they do not
" recognize the pattern.
" Update:  :execute Mark() now restores screen position as well as the cursor.
fun! Mark(...)
  if a:0 == 0
    let mark = line(".") . "G" . virtcol(".") . "|"
    normal! H
    let mark = "normal!" . line(".") . "Gzt" . mark
    execute mark
    return mark
  elseif a:0 == 1
    return "normal!" . a:1 . "G1|"
  else
    return "normal!" . a:1 . "G" . a:2 . "|"
  endif
endfun

" See comments above Mark()
fun! Line(mark)
  if a:mark =~ '\dG\d\+|$'
    return substitute(a:mark, '.\{-}\(\d\+\)G\d\+|$', '\1', "")
  else
    return line(a:mark)
  endif
endfun

" See comments above Mark()
fun! Virtcol(mark)
  if a:mark =~ '\d\+G\d\+|$'
    return substitute(a:mark, '.*G\(\d\+\)|$', '\1', "")
  else
    return col(a:mark)
  endif
endfun

" Usage:  If the file contains lines like
" let pippo1 = pippo12
" I like pippo2
" then :%call Pippo()<CR> will append lines
" pippo1
" pippo12
" pippo2
" to the end of the file.
" I do not know what the original requester had in mind, but this could be
" useful for generating dictionaries.  For example, for LaTeX, try
" :%call Pippo('\\\a\+') and then sort the resulting lines.
fun! Pippo(...) range
  if a:0
    let pat = a:1
  else
    let pat = '\<pippo\d\+\>'
  endif
  let bot = line("$")
  execute a:firstline . "," . a:lastline . 'g/' . pat . '/copy $'
  if bot == line("$")
    return
  endif
  execute (bot+1) . ',$s/' . pat . '/&\r/ge'
  execute (bot+1) . ',$v/' . pat . '/d'
  execute (bot+1) . ',$s/.\{-}\(' . pat . '\)$/\1/e'
endfun

" <S-4> or $ takes you to the last character of the line; this takes you
" to the last non-blank character of the line.
map <M-4> 0:let@9=@/<Bar>set nohls<CR>/.*\S/e<CR>:let @/=@9<Bar>set hls<CR>
" Here is another way to do it.  I use a function for legibility and for the
" sake of a local variable.
map <M-4> :call LastNonBlank()<CR>
fun! LastNonBlank()
  let i = matchend(getline("."), '.*\S')-1
  if i > 0
    execute "normal!0" . i . "l"
  elseif i == 0
    execute normal! 0
  endif
endfun

" Strip off a pattern from a keyword and jump to the tag.
nmap <C-]> :call StripTag("xxx")<CR>
fun! StripTag(pattern)
  let keyword = expand("<cword>")
  if keyword =~ '^' . a:pattern
    execute "tag!" . substitute(keyword, a:pattern, "", "")
  else
    execute "normal! \<C-]>"
  endif
endfun

" These autocommands and function insert a template every time you
" type "<scr" at the end of a line in a *.jsp file.
augroup Foo
  autocmd BufEnter *.jsp imap r r<Esc>:call JS_template()<CR>a
  autocmd BufLeave *.jsp iunmap r
augroup END
fun! JS_template()
  if getline(".") !~ '<scr$'
    return
  endif
  s/scr$/script language="JavaScript">/
  append
  function foo() {
      alert("Hello, world.");
    }
  </script>

.
endfun

"The following autocommand and function align C++ style << characters.
augroup Foo
  autocmd BufEnter *.cpp imap < <<C-O>:call LineUpLT()<CR>
  autocmd BufLeave *.cpp iunmap <
augroup END
fun! LineUpLT()
  if line(".") == 1 || getline(".") !~ '^\s*<<$'
    return
  endif
  let newline = getline(line(".")-1)
  let col = match(newline, "<<")
  if col != -1
    let newline = strpart(newline, 0, col)
    let newline = substitute(newline, '\S', " ", "g") . "<<"
    call setline(line("."), newline)
    normal!$
  endif
endfun

fun! Count(pat)
  let num = 0
  execute 'g/' . a:pat . '/let num = num + 1'
  return num
endfun

" A joint effort with Douglas Potts.
" Show the colors of all highlight groups.
" Oops, we reinvented the wheel!  See $VIMRUNTIME/hitest.vim .
fun! ShowHi()
  " Save the value of 'more'
  let save_more = &more
  " Spare me the "more" prompts!
  set nomore
  " Redirect output of :hi to register a
  redir @a
  hi
  redir END
  let &more = save_more
  new
  " Put it in a temp buffer
  put a
  " Remove any line that does not match '\h' (head-of-word character)
  v/\h/d
  " Do some processing to add 'syn keyword' syntax
  %s/.\{-}\(\h\w*\).*/syn keyword \1 \1/
  " Yank the buffer into register a and execute it.
  %y a
  @a
endfun

command! -nargs=1 -complete=var EditFun call EditFun(<q-args>)
fun! EditFun(name)
  " Save the value of 'more'
  let save_more = &more
  " Spare me the "more" prompts!
  set nomore
  " Redirect output of :function to register a
  redir @a
  execute "function " . a:name
  redir END
  let &more = save_more
  " Put it in a temp buffer
  execute "sp " . tempname()
  put a
  set ft=vim
endfun

" Get information from user-defined modelines.  If the file contains
" /* foo:  bar */
" on line 17 then GetModelines('/\* foo:') returns the String "17:".
" If the pattern contains a \(group\) then the matching text is
" returned:  GetModelines('/\* foo:  \(.*\) \*/') returns "17:bar".
" A more robust input pattern would be '/\*\s*foo:\s*\(.\{-}\)\s*\*/'.
" If no match is found, the function returns "0:".  Vim will also
" report that no match was found; this may trigger a hit-return prompt.
" At least, it does not count as an error.
"
" By default, the whole file is searched, and the LAST match counts.
" You can restrict the range as follows:
"   GetModelines(pat, 100)	searches the first 100 lines;
"   GetModelines(pat, -100)	searches the last 100 lines;
"   GetModelines(pat, 10,100)	searches lines 10 to 100.
" In all cases, the script checks for a valid range, so that you do
" not have to.
fun! GetModelines(pat, ...)
  " Long but simple:  set start line and finish line.
  let EOF = line("$")
  if a:0 >1
    let start = a:1
    let finish = a:2
  elseif a:0 == 1
    if a:1 > 0
      let start = 1
      let finish = a:1
    else
      let start = EOF + a:1 + 1
      let finish = EOF
    endif
  endif
  if !exists("start") || start < 1
    let start = 1
  endif
  if !exists("finish") || finish > EOF
    let finish = EOF
  endif
  " Now for the fun part!  Remember that any command can be used after
  " :g/pat/ although :s is the most common.  Since I am using "/" to
  " delimit the :g command, I have to escape them in a:pat.
  let n = 0
  " The :silent command requires vim 6.0.
  silent execute start .",". finish
	\ 'g/' . escape(a:pat, "/") . "/let n=line('.')"
  " Now, some substitute() magic:  I enclose the pattern in a \(group\),
  " in case it contains branches, and add .\{-} and .* at the beginning
  " and end, so it matches the whole line.  Since \(pat\) is the first
  " group, \2 refers to the user's first group, if any.
  if n
    execute "normal!\<C-O>"
    return substitute(getline(n), '.\{-}\(' . a:pat . '\).*', n.':\2', '')
  else
    echo
    return "0:"
  endif
endfun

" Make tab stops at columns 8, 17, 26, and 35.
" In real life, you would want to map <Tab> instead of <F7>.
imap <F7> <C-R>=VarTab(virtcol("."),8,17,26,35)<CR>
fun! VarTab(c, ...)
  " Find the first tab stop after the current column.
  let i = 1
  while i <= a:0
    execute "let num_sp = -a:c + a:" . i
    if num_sp > 0
      break
    endif
    let i = i+1
  endwhile
  if i > a:0  " We are already past the last tab stop.
    return ""
  endif
  " This may be overkill, but I want an efficient way to generate a string
  " with the right number of spaces.
  let spaces = " "
  let len = 1
  while len < num_sp
    let spaces = spaces . spaces
    let len = len + len
  endwhile
  return strpart(spaces, 0, num_sp)
endfun

" For HTML files, map <BS> to delete "&foo;" as one character.
" To avoid complications (start of line, end of line, etc.) the
" mapping inserts a character, the function deletes all but two
" characters, and the mapping deletes the last two.
augroup Foo
  autocmd BufEnter *.html,*.htm
   \ inoremap <BS> x<Esc>:call SmartBS('&[^ \t;]*;')<CR>a<BS><BS>
  autocmd BufLeave *.html,*.htm iunmap <BS>
augroup END
fun! SmartBS(pat)
  let init = strpart(getline("."), 0, col(".")-1)
  let len = strlen(matchstr(init, a:pat . "$")) - 1
  if len > 0
    execute "normal!" . len . "X"
  endif
endfun

" If you have the line
"	foobar
" and call :Transform abc xyz
" then the "a" and "b" in "foobar" are translated into "x" and "y", to give
"	fooyxr
" If the Transform() function is given the optional third argument, a string,
" then it returns the transformed string instead of operating on the current
" line.  Both can be given a range of lines, following the usual rules.
command! -nargs=* -range Transform <line1>,<line2> call Transform(<f-args>)
fun! Transform(old, new, ...)
  if a:0
    let string = a:1
  else
    let string = getline(".")
  endif
  let i = 0
  while i < strlen(a:old) && i < strlen(a:new)
    execute "let string=substitute(string,'".a:old[i]."','".a:new[i]."','g')"
    let i = i+1
  endwhile
  if a:0
    return string
  else
    call setline(".", string)
  endif
endfun

" :Search foo
" will find the next occurrence of "foo" and select it in Select mode.
" It does not work well if the match is a single character.
command! -nargs=1 Search call Search(<f-args>)
fun! Search(pat)
  execute "normal! /" . a:pat . "\<CR>"
  execute "normal! v//e+1\<CR>\<C-G>"
endfun

" Change _foo_ into FOO on the fly, in Insert mode.
" This version only works within one line.
" It will not get confused if you switch bufffers before the second "_".
:imap _ _<Esc>:call Capitalize()<CR>s
fun! Capitalize()
  if exists("b:Capitalize_flag")
    unlet b:Capitalize_flag
    normal! vF_Ux,
  else
    let b:Capitalize_flag = 1
    execute "normal! a_\<Esc>"
  endif
endfun

" If you switch between windows with the mouse, and want each window to
" remember whether it was in Insert or Normal mode, try this:
inoremap <LeftMouse> <Esc>:let w:lastmode="Insert"<CR><LeftMouse>
        \ :if exists("w:lastmode")&&w:lastmode=="Insert"<Bar>
        \ startinsert<Bar>endif<CR>
nnoremap <LeftMouse> :let w:lastmode="Normal"<CR><LeftMouse>
        \ :if exists("w:lastmode")&&w:lastmode=="Insert"<Bar>
        \ startinsert<Bar>endif<CR>

" Echo a command and then execute it.  This is useful for making a record
" of your vim session (the Command-line portion) with
" :redir > vimlog.txt .
command! -nargs=* Echo echo ":".<q-args> <bar> <args>

" Use getchar() to eat up the space that triggers an abbreviation.  (This
" requires vim 6.x .)  If you want to type "foo " and get "foo()" with the
" cursor between the parentheses, use the following command and enter
" :Iab <silent> foo foo()<Left>

command! -nargs=+ Iabbr execute "iabbr" <q-args> . "<C-R>=Eatchar('\\s')<CR>"

" The built-in getchar() function returns a Number for an 8-bit character, and
" a String for any other character.  This version always returns a String.
fun! Getchar()
  let c = getchar()
  if c != 0
    let c = nr2char(c)
  endif
  return c
endfun

fun! Eatchar(pat)
   let c = Getchar()
   return (c =~ a:pat) ? '' : c
endfun

" If you want to remap an operator, use GetMotion() to supply the motion that
" follows the operator.  For example,
"
" nmap <silent> y :call Yank()<CR>
"
" will redefine y (yank) in Normal mode, so that the cursor does not move.
" (By default, the cursor moves to the start of the selection.)
" This version of GetMotion() is usable, but not complete.
" One disadvantage is that the command is not shown as you type, even if you
" have the 'showcmd' option set.
" TODO:  How can we capture an optional register?

fun! Yank()
  let startpos = Mark()
  execute "norm! y" . GetMotion("y")
  execute startpos
endfun

" Get a sequence of characters that describe a motion.
fun! GetMotion(char)
  let motion = ""
  let c = Getchar()
  " In some contexts, such as "yy", a particular character counts as a motion.
  if c == a:char
    return c
  endif
  " Capture any sequence of digits (a count) and mode modifiers.
  " :help o_v
  while c =~ "[vV[:digit:]\<C-V>]"
    let motion = motion . c
    let c = Getchar()
  endwhile
  " Most motions are a single character, but some two-character motions start
  " with 'g'.  For example,
  " :help gj
  if c == "g"
    let motion = motion . c
    let c = Getchar()
  endif
  " Text objects start with 'a' or 'i'.  :help text-objects
  " Jump to a mark with "'" or "`".  :help 'a
  if c =~ "[ai'`]"
    let motion = motion . c
    let c = Getchar()
  endif
  return motion . c
endfun

" Return the common initial part of two strings.
fun! Common(str1, str2)
  " Thanks to Peppe Guldberg, who noticed that we get an infinite loop if we
  " omit this test.  If  n  is too big then a:str1[n] is the empty string...
  if a:str1 == a:str2
    return a:str1
  endif
  let n = 0
  while a:str1[n] == a:str2[n]
    let n = n+1
  endwhile
  return strpart(a:str1, 0, n)
endfun

:inoremap <F4> <C-O>:call TWIN()<CR>
fun! TWIN()
  let str = "I hear that the weather is nice in "
  let str = str . input("Where do you want to go today?  ")
  let str = str . " this time of year."
  call append(".", str)
  +normal! gqq$
endfun
