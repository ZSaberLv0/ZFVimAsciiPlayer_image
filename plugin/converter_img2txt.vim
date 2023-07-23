
let s:frameSeparator = 'ZF_img2txt_ZF'
let s:scriptPath = expand('<sfile>:p:h:h') . '/misc'
function! ZF_AsciiPlayer_pillow_converterInit(params)
    if executable('python3')
        let py = 'python3'
    elseif executable('python')
        let py = 'python'
    else
        call ZF_AsciiPlayer_log('[ZFAsciiPlayer] no python available')
        return {}
    endif

    let tmpFile = CygpathFix_absPath(tempname())
    let convertCmd = py . ' "' . s:scriptPath . '/img2txt.py"'
                \ . ' "' . a:params['file'] . '"'
                \ . ' ' . a:params['maxWidth']
                \ . ' ' . a:params['maxHeight']
                \ . ' ' . string(a:params['heightScale'])
                \ . ' > "' . tmpFile . '"'
    if exists('g:ZFAsciiPlayerLog')
        let _start_time = reltime()
        let convertResult = system(convertCmd)
        call add(g:ZFAsciiPlayerLog,
                    \   'img2txt.py cmd: '
                    \   . convertCmd
                    \ )
        call add(g:ZFAsciiPlayerLog,
                    \   'img2txt.py used time: '
                    \   . float2nr(reltimefloat(reltime(_start_time, reltime())) * 1000)
                    \ )
    else
        let convertResult = system(convertCmd)
    endif
    if v:shell_error != 0
        try
            call delete(tmpFile)
        catch
        endtry
        call ZF_AsciiPlayer_log('[ZFAsciiPlayer] unable to convert: ' . convertResult)
        return {}
    endif
    let convertResult = join(readfile(tmpFile, 'b'), "\n")
    try
        call delete(tmpFile)
    catch
    endtry

    let convertResult = substitute(convertResult, '\r\n', '\n', 'g')
    let convertResult = substitute(convertResult, '^\n\+', '', '')
    let convertResult = substitute(convertResult, '\n\+$', '', '')
    let asciiFrames = split(convertResult, s:frameSeparator)
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
                    \   'img2txt.py terminalHL used time: '
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

function! ZF_AsciiPlayer_pillow_converterFrame(state, frame)
    return a:state['frameDatas'][a:frame]
endfunction


if !exists('g:ZFAsciiPlayer_converters')
    let g:ZFAsciiPlayer_converters = {}
endif
let impl = {
            \   'init' : function('ZF_AsciiPlayer_pillow_converterInit'),
            \   'frame' : function('ZF_AsciiPlayer_pillow_converterFrame'),
            \ }
for ext in [
            \   'bmp',
            \   'gif',
            \   'jpeg',
            \   'jpg',
            \   'png',
            \   'webp',
            \ ]
    if !exists('g:ZFAsciiPlayer_converters[ext]')
        let g:ZFAsciiPlayer_converters[ext] = impl
    endif
endfor

