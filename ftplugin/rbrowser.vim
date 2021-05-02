" Vim filetype plugin file
" Language: R Browser (generated by the Nvim-R)
" Maintainer: Jakson Alves de Aquino <jalvesaq@gmail.com>


" Only do this when not yet done for this buffer
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

let s:upobcnt = 0

let s:cpo_save = &cpo
set cpo&vim

" Source scripts common to R, Rnoweb, Rhelp and rdoc files:
exe "source " . substitute(expand("<sfile>:h:h"), ' ', '\ ', 'g') . "/R/common_global.vim"

" Some buffer variables common to R, Rnoweb, Rhelp and rdoc file need be
" defined after the global ones:
exe "source " . substitute(expand("<sfile>:h:h"), ' ', '\ ', 'g') . "/R/common_buffer.vim"

setlocal noswapfile
setlocal buftype=nofile
setlocal nowrap
setlocal iskeyword=@,48-57,_,.
setlocal nolist
setlocal nonumber
setlocal norelativenumber
setlocal nocursorline
setlocal nocursorcolumn
setlocal nospell

if !has_key(g:rplugin, "hasmenu")
    let g:rplugin.hasmenu = 0
endif

" Popup menu
if !exists("s:hasbrowsermenu")
    let s:hasbrowsermenu = 0
endif

function! UpdateOB(what)
    if a:what == "both"
        let wht = g:rplugin.curview
    else
        let wht = a:what
    endif
    if g:rplugin.curview != wht
        return "curview != what"
    endif
    if s:upobcnt
        echoerr "OB called twice"
        return "OB called twice"
    endif
    let s:upobcnt = 1

    let rplugin_switchedbuf = 0
    let s:bufl = execute("buffers")
    if s:bufl !~ "Object_Browser"
        let s:upobcnt = 0
        return "Object_Browser not listed"
    endif

    if wht == "GlobalEnv"
        let fcntt = readfile(g:rplugin.tmpdir . "/globenv_" . $NVIMR_ID)
    else
        let fcntt = readfile(g:rplugin.tmpdir . "/liblist_" . $NVIMR_ID)
    endif
    if has("nvim")
        let obcur = nvim_win_get_cursor(g:rplugin.ob_winnr)
        call nvim_buf_set_option(g:rplugin.ob_buf, "modifiable", v:true)
        call nvim_buf_set_lines(g:rplugin.ob_buf, 0, nvim_buf_line_count(g:rplugin.ob_buf), 0, fcntt)
        if obcur[0] <= len(fcntt)
            call nvim_win_set_cursor(g:rplugin.ob_winnr, obcur)
        endif
        call nvim_buf_set_option(g:rplugin.ob_buf, "modifiable", v:false)
    else
        if has_key(g:rplugin, "curbuf") && g:rplugin.curbuf != "Object_Browser"
            let savesb = &switchbuf
            set switchbuf=useopen,usetab
            sil noautocmd sb Object_Browser
            let rplugin_switchedbuf = 1
        endif

        setlocal modifiable
        let curline = line(".")
        let curcol = col(".")
        if !exists("curline")
            let curline = 3
        endif
        if !exists("curcol")
            let curcol = 1
        endif
        let save_unnamed_reg = @@
        sil normal! ggdG
        let @@ = save_unnamed_reg
        call setline(1, fcntt)
        call cursor(curline, curcol)
        if bufname("%") =~ "Object_Browser"
            setlocal nomodifiable
        endif
        if rplugin_switchedbuf
            exe "sil noautocmd sb " . g:rplugin.curbuf
            exe "set switchbuf=" . savesb
        endif
    endif
    let s:upobcnt = 0
    return "End of UpdateOB()"
endfunction

function! RBrowserDoubleClick()
    if line(".") == 2
        return
    endif

    " Toggle view: Objects in the workspace X List of libraries
    if line(".") == 1
        if g:rplugin.curview == "libraries"
            let g:rplugin.curview = "GlobalEnv"
            call JobStdin(g:rplugin.jobs["ClientServer"], "31\n")
        else
            let g:rplugin.curview = "libraries"
            call JobStdin(g:rplugin.jobs["ClientServer"], "321\n")
        endif
        return
    endif

    " Toggle state of list or data.frame: open X closed
    let key = RBrowserGetName(1, 1)
    let curline = getline(".")
    if g:rplugin.curview == "GlobalEnv"
        if curline =~ "&#.*\t"
            call SendToNvimcom("L", key)
        elseif curline =~ "\[#.*\t" || curline =~ "\$#.*\t" || curline =~ "<#.*\t" || curline =~ ":#.*\t"
            call JobStdin(g:rplugin.jobs["ClientServer"], "33G" . key . "\n")
        else
            let key = RBrowserGetName(0, 0)
            call g:SendCmdToR("str(" . key . ")")
        endif
    else
        if curline =~ "(#.*\t"
            call AskRDoc(key, RBGetPkgName(), 0)
        else
            if key =~ ":$" || curline =~ "\[#.*\t" || curline =~ "\$#.*\t" || curline =~ "<#.*\t" || curline =~ ":#.*\t"
                call JobStdin(g:rplugin.jobs["ClientServer"], "33L" . key . "\n")
            else
                let key = RBrowserGetName(0, 0)
                call g:SendCmdToR("str(" . key . ")")
            endif
        endif
    endif
endfunction

function! RBrowserRightClick()
    if line(".") == 1
        return
    endif

    let key = RBrowserGetName(1, 0)
    if key == ""
        return
    endif

    let line = getline(".")
    if line =~ "^   ##"
        return
    endif
    let isfunction = 0
    if line =~ "(#.*\t"
        let isfunction = 1
    endif

    if s:hasbrowsermenu == 1
        aunmenu ]RBrowser
    endif
    let key = substitute(key, '\.', '\\.', "g")
    let key = substitute(key, ' ', '\\ ', "g")

    exe 'amenu ]RBrowser.summary('. key . ') :call RAction("summary")<CR>'
    exe 'amenu ]RBrowser.str('. key . ') :call RAction("str")<CR>'
    exe 'amenu ]RBrowser.names('. key . ') :call RAction("names")<CR>'
    exe 'amenu ]RBrowser.plot('. key . ') :call RAction("plot")<CR>'
    exe 'amenu ]RBrowser.print(' . key . ') :call RAction("print")<CR>'
    amenu ]RBrowser.-sep01- <nul>
    exe 'amenu ]RBrowser.example('. key . ') :call RAction("example")<CR>'
    exe 'amenu ]RBrowser.help('. key . ') :call RAction("help")<CR>'
    if isfunction
        exe 'amenu ]RBrowser.args('. key . ') :call RAction("args")<CR>'
    endif
    popup ]RBrowser
    let s:hasbrowsermenu = 1
endfunction

function! RBGetPkgName()
    let lnum = line(".")
    while lnum > 0
        let line = getline(lnum)
        if line =~ '.*##[0-9a-zA-Z\.]*\t'
            let line = substitute(line, '.*##\(.\{-}\)\t.*', '\1', "")
            return line
        endif
        let lnum -= 1
    endwhile
    return ""
endfunction

function! RBrowserFindParent(word, curline, curpos)
    let curline = a:curline
    let curpos = a:curpos
    while curline > 1 && curpos >= a:curpos
        let curline -= 1
        let line = substitute(getline(curline), "\x09.*", "", "")
        let curpos = stridx(line, '[#')
        if curpos == -1
            let curpos = stridx(line, '$#')
            if curpos == -1
                let curpos = stridx(line, '<#')
                if curpos == -1
                    let curpos = a:curpos
                endif
            endif
        endif
    endwhile

    if g:rplugin.curview == "GlobalEnv"
        let spacelimit = 3
    else
        if s:isutf8
            let spacelimit = 10
        else
            let spacelimit = 6
        endif
    endif
    if curline > 1
        let line = substitute(line, '^.\{-}\(.\)#', '\1#', "")
        let line = substitute(line, '^ *', '', "")
        if line =~ " " || line =~ '^.#[0-9]' || line =~ '-' || line =~ '^.#' . s:reserved
            let line = substitute(line, '\(.\)#\(.*\)$', '\1#`\2`', "")
        endif
        if line =~ '<#'
            let word = substitute(line, '.*<#', "", "") . '@' . a:word
        elseif line =~ '\[#'
            let word = substitute(line, '.*\[#', "", "") . '$' . a:word
        else
            let word = substitute(line, '.*\$#', "", "") . '$' . a:word
        endif
        if curpos != spacelimit
            let word = RBrowserFindParent(word, line("."), curpos)
        endif
        return word
    else
        " Didn't find the parent: should never happen.
        let msg = "R-plugin Error: " . a:word . ":" . curline
        echoerr msg
    endif
    return ""
endfunction

function! RBrowserCleanTailTick(word, cleantail, cleantick)
    let nword = a:word
    if a:cleantick
        let nword = substitute(nword, "`", "", "g")
    endif
    if a:cleantail
        let nword = substitute(nword, '[\$@]$', '', '')
        let nword = substitute(nword, '[\$@]`$', '`', '')
    endif
    return nword
endfunction

function! RBrowserGetName(cleantail, cleantick)
    let line = getline(".")
    if line =~ "^$" || line(".") < 3
        return ""
    endif

    let curpos = stridx(line, "#")
    let word = substitute(line, '.\{-}\(.#\)\(.\{-}\)\t.*', '\2\1', '')
    let word = substitute(word, '\[#$', '$', '')
    let word = substitute(word, '\$#$', '$', '')
    let word = substitute(word, '<#$', '@', '')
    let word = substitute(word, '.#$', '', '')

    if word =~ ' ' || word =~ '^[0-9]' || word =~ '-' || word =~ '^' . s:reserved . '$'
        let word = '`' . word . '`'
    endif

    if curpos == 4
        " top level object
        let word = substitute(word, '\$\[\[', '[[', "g")
        let word = RBrowserCleanTailTick(word, a:cleantail, a:cleantick)
        if g:rplugin.curview == "libraries"
            return word . ':'
        else
            return word
        endif
    else
        if g:rplugin.curview == "libraries"
            if s:isutf8
                if curpos == 11
                    let word = RBrowserCleanTailTick(word, a:cleantail, a:cleantick)
                    let word = substitute(word, '\$\[\[', '[[', "g")
                    return word
                endif
            elseif curpos == 7
                let word = RBrowserCleanTailTick(word, a:cleantail, a:cleantick)
                let word = substitute(word, '\$\[\[', '[[', "g")
                return word
            endif
        endif
        if curpos > 4
            " Find the parent data.frame or list
            let word = RBrowserFindParent(word, line("."), curpos - 1)
            let word = RBrowserCleanTailTick(word, a:cleantail, a:cleantick)
            let word = substitute(word, '\$\[\[', '[[', "g")
            return word
        else
            " Wrong object name delimiter: should never happen.
            let msg = "R-plugin Error: (curpos = " . curpos . ") " . word
            echoerr msg
            return ""
        endif
    endif
endfunction

function! OnOBBufUnload()
    if g:R_hi_fun_globenv < 2
        call SendToNvimcom("N", "OnOBBufUnload")
    endif
endfunction

function! PrintListTree()
    call JobStdin(g:rplugin.jobs["ClientServer"], "37\n")
endfunction

nnoremap <buffer><silent> <CR> :call RBrowserDoubleClick()<CR>
nnoremap <buffer><silent> <2-LeftMouse> :call RBrowserDoubleClick()<CR>
nnoremap <buffer><silent> <RightMouse> :call RBrowserRightClick()<CR>

call RControlMaps()

setlocal winfixwidth
setlocal bufhidden=wipe

if has("gui_running")
exe "source " . substitute(expand("<sfile>:h:h"), ' ', '\ ', 'g') .     "/R/gui_running.vim"
    call RControlMenu()
    call RBrowserMenu()
endif

au BufEnter <buffer> stopinsert
au BufUnload <buffer> call OnOBBufUnload()

let s:reserved = '\(if\|else\|repeat\|while\|function\|for\|in\|next\|break\|TRUE\|FALSE\|NULL\|Inf\|NaN\|NA\|NA_integer_\|NA_real_\|NA_complex_\|NA_character_\)'

let s:envstring = tolower($LC_MESSAGES . $LC_ALL . $LANG)
if s:envstring =~ "utf-8" || s:envstring =~ "utf8"
    let s:isutf8 = 1
else
    let s:isutf8 = 0
endif
unlet s:envstring

call setline(1, ".GlobalEnv | Libraries")

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=4
