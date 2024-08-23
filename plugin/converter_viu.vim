
if !executable('viu')
    finish
endif

function! ZF_AsciiPlayer_viu_converterInit(params)
    " detect whether use -w or -h
    if exists('g:ZFAsciiPlayerLog')
        let _start_time = reltime()
    endif
    let wData = system(printf('viu -w %s -b -s "%s"'
                \ , a:params['maxWidth']
                \ , a:params['file']
                \ ))
    let hData = system(printf('viu -h %s -b -s "%s"'
                \ , a:params['maxHeight']
                \ , a:params['file']
                \ ))
    if exists('g:ZFAsciiPlayerLog')
        call add(g:ZFAsciiPlayerLog,
                    \   'viu detect w/h used time: '
                    \   . float2nr(reltimefloat(reltime(_start_time, reltime())) * 1000)
                    \ )
    endif

    if len(wData) <= len(hData)
        let convertCmd = printf('viu -w %s -b -1 "%s"'
                    \ , a:params['maxWidth']
                    \ , a:params['file']
                    \ )
    else
        let convertCmd = printf('viu -h %s -b -1 "%s"'
                    \ , a:params['maxHeight']
                    \ , a:params['file']
                    \ )
    endif
    if exists('g:ZFAsciiPlayerLog')
        let _start_time = reltime()
        let convertResult = system(convertCmd)
        call add(g:ZFAsciiPlayerLog,
                    \   'viu cmd: '
                    \   . convertCmd
                    \ )
        call add(g:ZFAsciiPlayerLog,
                    \   'viu used time: '
                    \   . float2nr(reltimefloat(reltime(_start_time, reltime())) * 1000)
                    \ )
    else
        let convertResult = system(convertCmd)
    endif
    if v:shell_error != 0
        call ZF_AsciiPlayer_log('[ZFAsciiPlayer] unable to convert: ' . convertResult)
        return {}
    endif

    if exists('g:ZFAsciiPlayerLog')
        let _start_time = reltime()
        let asciiFrames = ZF_AsciiPlayer_terminalHLParsePages(convertResult)
        call add(g:ZFAsciiPlayerLog,
                    \   'terminalHLParsePages used time: '
                    \   . float2nr(reltimefloat(reltime(_start_time, reltime())) * 1000)
                    \ )
    else
        let asciiFrames = ZF_AsciiPlayer_terminalHLParsePages(convertResult)
    endif
    if empty(asciiFrames)
        call ZF_AsciiPlayer_log('[ZFAsciiPlayer] no frame')
        return {}
    endif
    let frameDatas = []

    if exists('g:ZFAsciiPlayerLog')
        let _start_time = reltime()
        for asciiFrame in asciiFrames
            call add(frameDatas, ZF_AsciiPlayer_terminalHLToHLCmd(asciiFrame))
        endfor
        call add(g:ZFAsciiPlayerLog,
                    \   'viu terminalHL used time: '
                    \   . float2nr(reltimefloat(reltime(_start_time, reltime())) * 1000)
                    \ )
    else
        for asciiFrame in asciiFrames
            call add(frameDatas, ZF_AsciiPlayer_terminalHLToHLCmd(asciiFrame))
        endfor
    endif

    return {
                \   'fps' : -1,
                \   'totalFrame' : len(frameDatas),
                \   'frameDatas' : frameDatas,
                \ }
endfunction

function! ZF_AsciiPlayer_viu_converterFrame(state, frame)
    return a:state['frameDatas'][a:frame]
endfunction


if !exists('g:ZFAsciiPlayer_converters')
    let g:ZFAsciiPlayer_converters = {}
endif
let impl = {
            \   'init' : function('ZF_AsciiPlayer_viu_converterInit'),
            \   'frame' : function('ZF_AsciiPlayer_viu_converterFrame'),
            \ }
for ext in [
            \   'bmp',
            \   'gif',
            \   'jpeg',
            \   'jpg',
            \   'png',
            \   'webp',
            \ ]
    let g:ZFAsciiPlayer_converters[ext] = impl
endfor

