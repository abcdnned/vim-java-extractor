let g:constant_file_name = 'ElasticSearch'

command! EJAll :call s:ejall(g:constant_file_name)
command! EJ :call s:ej(g:constant_file_name)

let s:p_str = '\([a-zA-Z_]\{-\}\)'
let s:p_symbol = '"' . s:p_str . '"'
let s:define = 'static final String ' . s:p_str . ' = ' . s:p_symbol

function! s:changebuffer(file)
    let path = expand("%:p:h") . '/' . a:file . '.java'
    execute ':edit '.path
endfunction

function! s:extract(srcline, fn)
    let ml = matchlist(a:srcline, s:p_symbol)
    if len(ml) > 0
        let definename = s:generate_define(a:fn, ml[1])
        return substitute(a:srcline, s:p_symbol, g:constant_file_name . '.' . definename, 'g')
    endif
    return ''
endfunction

function! s:extract_all(fn)
    let lines = getline(1, line('$'))
    call s:changebuffer(a:fn)
    let lnum = 1
    let changes = []
    while lnum < len(lines)
        let newline = s:extract(lines[lnum], a:fn)
        if strlen(newline) > 0
            call add(changes, [lnum, newline])
        endif
        let lnum += 1
    endwhile
    execute "normal \<c-^>"
    for change in changes
        call setline(change[0] + 1, change[1])
    endfor
endfunction

function! s:generate_define(file, symbol)
    let eln = line('$')
    let s = -1
    let exists = 0
    let definename = ''
    while eln > 0
        let text = getline(eln)
        let ml = matchlist(text, s:define)
        if len(ml) > 0
            if ml[2] == a:symbol
                let exists = 1
                let definename = ml[1]
                break
            elseif s < 0
                let s = eln
            endif
        endif
        let eln -= 1
    endwhile
    if !exists
        let definename = s:format(a:symbol)
        if s < 0
            let s = line('$') - 2
        endif
        let i = indent(s)
        let pre = repeat(' ',i)
        let define = ['', pre.'static final String ' . definename . ' = ' . '"' . a:symbol . '"']
        call append(s, define)
    endif
    return definename
endfunction

function! s:appendclass()
    let define = ['','','public class '.g:constant_file_name.' {','','','}']
    call append(1, define)
endfunction

function! s:format(name)
    let lastu = -1
    let s = []
    for i in range(strlen(a:name))
        if a:name[i] < 'Z' && a:name[i] > 'A'
            if i - 1 != lastu && i != 0
                call add(s, i)
            endif
        endif
    endfor
    let items = []
    let un = toupper(a:name)
    for i in range(len(s))
        let start = i == 0 ? 0 : s[i - 1]
        call add(items, un[start:s[i] - 1])
    endfor
    if len(s) > 0
        call add(items, un[s[len(s) - 1]:strlen(un)])
    else
        return un
    endif
    let result = join(items, '_')
    return result
endfunction

function! s:ej(fn)
    let text = getline(line('.'))
    call s:changebuffer(a:fn)
    let newline = s:extract(text, a:fn)
    execute "normal \<c-^>"
    call setline(line('.'), newline)
endfunction

function! s:ejall(fn)
    call s:extract_all(a:fn)
endfunction
