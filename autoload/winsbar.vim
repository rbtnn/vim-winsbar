
let s:prev_args = get(s:, 'prev_args', [])
let s:prev_winids = get(s:, 'prev_winids', [])
let s:prev_timer = get(s:, 'prev_timer', -1)
let s:prev_localtime = get(s:, 'prev_localtime', 0)

function! winsbar#enabled() abort
    if has('popupwin')
        if -1 != s:prev_timer
            call timer_stop(s:prev_timer)
        endif
        let s:prev_timer = timer_start(100, function('s:timer_handler'), #{ repeat: -1 })
    endif
endfunction

function! s:popup_create(w_height, w_winrow, size, col, line, highlight) abort
    let diff = (a:size + a:line) - a:w_height
    if 0 > diff
        let diff = 0
    endif
    return popup_create(repeat([' '], a:size - diff), #{
        \ minheight: a:size - diff,
        \ maxheight: a:size - diff,
        \ col: a:col,
        \ line: a:line + a:w_winrow,
        \ highlight: a:highlight,
        \ pos: 'topleft',
        \ border: [0, 0, 0, 0],
        \ })
endfunction

function! s:tabsidebar_size() abort
    if has('tabsidebar')
        if (&showtabsidebar == 2) || (&showtabsidebar == 1 && 1 < tabpagenr('$'))
            return &tabsidebarcolumns
        endif
    endif
    return 0
endfunction

function! s:set_scrollbar_in_window(w_topline, w_winrow, w_wincol, w_width, w_height, b_linecount) abort
    let winids = []
    let winsbar_highlights = get(g:, 'winsbar_highlights', ['PmenuSbar', 'PmenuThumb'])
    let col = a:w_wincol + a:w_width + s:tabsidebar_size()
    let n = 1.0 * a:b_linecount / a:w_height
    let pos = float2nr(a:w_topline / n)
    let size = float2nr(a:w_height / n) + 1
    if a:w_topline == 1 && a:w_height >= a:b_linecount
        let pos = 0
        let size = a:w_height
    endif
    if size > a:w_height
        let size = a:w_height
    endif
    let x = a:w_height - pos - size
    if pos > 0
        let winids += [s:popup_create(a:w_height, a:w_winrow, pos, col, 0, winsbar_highlights[0])]
    endif
    if size > 0
        let winids += [s:popup_create(a:w_height, a:w_winrow, size, col, pos, winsbar_highlights[1])]
    endif
    if x > 0
        let winids += [s:popup_create(a:w_height, a:w_winrow, x, col, pos + size, winsbar_highlights[0])]
    endif
    return winids
endfunction

function! s:timer_handler(timer) abort
    let m = mode()
    if ('n' == m) || ('i' == m)
        let args = []
        for w in getwininfo()
            if tabpagenr() == w['tabnr']
                let args += [[
                    \ w['topline'], w['winrow'], w['wincol'], w['width'], w['height'],
                    \ getbufinfo(w['bufnr'])[0]['linecount']
                    \ ]]
            endif
        endfor
        let no_scrolling = (s:prev_args == args && empty(s:prev_winids))
        if (s:prev_args != args) || no_scrolling
            for winid in s:prev_winids
                call popup_close(winid)
            endfor
            let s:prev_winids = []
            if (1 < localtime() - s:prev_localtime) || no_scrolling
                for xs in args
                    let s:prev_winids += call(function('s:set_scrollbar_in_window'), xs)
                endfor
                let s:prev_localtime = localtime()
            endif
            let s:prev_args = args
        endif
    endif
endfunction

