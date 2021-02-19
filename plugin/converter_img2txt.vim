
let s:frameSeparator = 'ZF_img2txt_ZF'
let s:scriptPath = expand('<sfile>:p:h:h') . '/misc'
function! ZF_AsciiPlayer_pillow_converterInit(params)
    if executable('python3')
        let py = 'python3'
    elseif executable('python')
        let py = 'python'
    else
        echomsg '[ZFAsciiPlayer] no python available'
        return {}
    endif
    if !executable('img2txt.py')
        echomsg '[ZFAsciiPlayer] img2txt.py not installed'
        return {}
    endif

    let tmpFile = CygpathFix_absPath(tempname())
    let convertCmd = py . ' "' . s:scriptPath . '/img2txt.py"'
                \ . ' "' . a:params['file'] . '"'
                \ . ' ' . a:params['maxWidth']
                \ . ' ' . a:params['maxHeight']
                \ . ' ' . string(a:params['heightScale'])
                \ . ' > "' . tmpFile . '"'
    let convertResult = system(convertCmd)
    if v:shell_error != 0
        try
            call delete(tmpFile)
        catch
        endtry
        echomsg '[ZFAsciiPlayer] unable to convert: ' . convertResult
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
        echomsg '[ZFAsciiPlayer] no frame'
        return {}
    endif
    let frameDatas = []
    for asciiFrame in asciiFrames
        call add(frameDatas, ZF_AsciiPlayer_terminalHLToHLCmd(asciiFrame))
    endfor

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

