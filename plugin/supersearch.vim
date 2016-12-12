" File: supersearch.vim
" Author: Tian (root AT codecn DOT org)
" Version: 1.8
" Last Modified: 2016.12.12
" Copyright: Copyright (C) 2015 ~ 2016 Tian,Teikay
"
" The "Super Search" plugin is a source code browser plugin for Vim and provides
" an overview of the structure of the programming language files and allows
" you to efficiently browse through source code files for different
" programming languages.  You can visit the supersearch plugin home page for more
" information:
"
"       https://github.com/hellotomcat/supersearch
"
" Installation
" ------------
" 1. Download the supersearch.zip file and unzip the files to the $HOME/.vim/plugin/
"    The directory structure should be preserved:
"    $HOME/.vim/plugin/supersearch.vim
"
" 2. Create a profile in the top-level directory of the project ("project.ini")
"
" 3. finished
"
"
" ------------
"
"这个项目是用来加速vim开发效率的
"1.由于历史原因我们的项目目录中有许多无关的目录包含着无关的代码，导致生成的tags文件往往没有实际用途
"2.当我们需要查看谁调用谁的问题时，要用:grep命令来搜索整个项目目录，相当不方便
"3.当想编译当前项目时，或者运行测试时，需要切换命令方式再手动打命令
"
"现在好了：
"有了supersearch插件，只要配置好与自己有关和目录，生成tags的事再也不用担心了（会自动生成tags文件），还能根据配置的目录进行全文搜索, 绑定快捷键后还能自己编译项目等等
"
"全文搜索目前定义为,s
"    在命令模式中,s直接搜索当前单词
"    在视图模式中先选择要搜索的文本，再按,s
"支持自定义编译(F9)，测试(F8), 格式化命令(,f)
"
"最后：
"        在插件文件的尾部定义了搜索快捷键，你可以自己修改为你喜欢的
"
"2016/12/12:
"   1.添加是否自动加载ctags功能
"   2.优化读取配置文件代码
"
"2016/12/10:
"   1. 修复在无配置文件情况下搜索时未指定目录问题（之前mac下会报错）
"   2. 修改搜索结果展示，只显示相对文件名（之前显示全路径）
"
"2016/09/07:
"   1.修复搜索问题
"
"2016/08/25:
"   1.修改检测tags方式.
"   2.默认在未配置格式化方式时，调用gg=G来格式化当前文件.
"
"2016/01/14:
"   1.修改关闭vim事件检测机制，感谢 zassen
"
"2015/12/24:
"   1.添加配置项目，支持编译，测试，文件过滤
"
"2015/06/18:
"   1.修复当前目录只有一个文件时搜索后无法跳转问题 by Teikay
"   2.修复生成tags文件错乱问题 by Tian
"   3.搜索时过滤掉.swp文件 by Tian
"


let g:conf_name = "project.ini"
let g:project_path = ""
let g:source_path = ["."]
let g:conf_dict = {}

func! FileSupportCheck()
    let ftype = expand("%:e")
    if ftype ==? "c" || ftype ==? "cpp" || ftype ==? "cc" || ftype ==? "java" || ftype ==? "py" ||  ftype ==? "h" || ftype ==? "go" || ftype ==? "php"
        return 1
    endif
    return 0
endfunc

func! ReadConfig(f)
    for line in readfile(a:f)
        "去掉无用的信息,只保留第一段配置内容
        let field = substitute(line, "#.*", "", "")
        let field = substitute(field, "//.*", "", "")
        let field = substitute(field, "\\s$", "", "")
        let kv = split(field, "=")
        if len(kv) == 2
            let g:conf_dict[kv[0]] = kv[1]
        endif
    endfor
endfunc

func! GetFileName(path)
    let pList = split(a:path, "/")
    return pList[len(pList) - 1]
endfunc


func! IsExcludePath(file)
    if has_key(g:conf_dict, "ExcludePath")
        for k in split(g:conf_dict["ExcludePath"], ",")
            if k ==? a:file
                return 1
            endif
        endfor
    endif
    return 0
endfunc


"查找目录中的project.ini,并解析其中配置信息
func! LoadConfig()
    let path_array = split(expand("%:p"), "/")
    let path_index = len(path_array)

    while path_index > 1
        let config_path = "/".join(path_array[0:path_index - 1], "/")
        let config_file = findfile(g:conf_name, config_path)
        if config_file != ""
            call ReadConfig(config_file)
            let g:source_path = []
            for path in split(globpath(config_path, '*'), "\n")
                if isdirectory(path)
                    let fileName = GetFileName(path)
                    if IsExcludePath(fileName)
                        "echo 'jump '.fileName
                        continue
                    endif
                    let g:source_path = add(g:source_path, path)
                endif
            endfor
            let g:project_path = config_path
            return 1
        endif
        let path_index -= 1
    endwhile
    return 0
endfunc

func! GetCtagsExcludeCmd()
    let cmd = ""
    if has_key(g:conf_dict, "CtagsExcludeFile")
        for key in split(g:conf_dict["CtagsExcludeFile"], ",")
            let cmd = cmd . " --exclude=" . key
        endfor
    endif
    return cmd
endfunc

func! UpdateTagsFile(path)
    let tags_file = a:path."/tags"
    let tags_exist = filereadable(tags_file)
    let cmd_find =  "find ".a:path." -maxdepth 1 -type f -newer ".tags_file

    if !tags_exist || system(cmd_find) != ""
        let exclude = GetCtagsExcludeCmd()
        let cmd_create_tags = "cd ".a:path.";ctags -R --c-kinds=+p --c++-kinds=+px --fields=+iaS --extra=+q ".exclude.";cd -"
        "echo cmd_create_tags
        let xxx = system(cmd_create_tags)
        "echo "create_ok".xxx
    endif
endfunc

func! UpdateTags()
    if has_key(g:conf_dict, "CtagsExtendFile")
        for tagsPath in split(g:conf_dict["CtagsExtendFile"], ",")
            let set_tags_cmd = "set tags+=".tagsPath."/tags"
            exe set_tags_cmd
        endfor
    endif

    for path in g:source_path
        call UpdateTagsFile(path)
        let set_tags_cmd = "set tags+=".path."/tags"
        exe set_tags_cmd
        "echo set_tags_cmd
    endfor
endfunc


func! CtagsEnable()
    if has_key(g:conf_dict, "CtagsEnable") && g:conf_dict["CtagsEnable"] == "true"
        return 1
    endif
    return 0
endfunc

func! SuperSearchStart()
    "是否支持
    if !FileSupportCheck()
        return
    endif

    "是否有配置文件并加载成功
    if !LoadConfig()
        return
    endif

    if CtagsEnable()
        call UpdateTags()
    endif

endfunc




func! OpenSearchResultFile()
    let info = split(getline("."), ":")
    if len(info) < 1
        return
    endif
    let filename = info[0]
    let linenumber = info[1]
    let fullpath = g:project_path.filename
    "关闭搜索窗口
    call CloseSearchWindow()
    execute "tabnew +".linenumber." ".fullpath
endfunc

func! GetSearchExcludeCmd()
    let cmd = "! -name 'tags' ! -name '*.swp' ! -path '*/.*/*' "
    if has_key(g:conf_dict, "FindExcludeFile")
        for key in split(g:conf_dict["FindExcludeFile"], ",")
            let cmd = cmd . " ! -name '" . key . "'"
        endfor
    endif
    return cmd
endfunc


func! OpenSearchWindow(k)
    let key = shellescape(a:k)
    copen
    let path = join(g:source_path, " ")
    let exclude = GetSearchExcludeCmd()
    "echo path
    let grep_cmd = "find ".path." ". exclude ." -type f  -exec grep -HFRn ".key." {} \\; "
    "echo grep_cmd
    let bytecode = system(grep_cmd)
    set modifiable
    for line in split(bytecode,'\v\n')
        call append(0, substitute(line, g:project_path, "", ""))
    endfor
    nnoremap <buffer> <silent> <CR> : call OpenSearchResultFile()<CR>
    nnoremap <buffer> <silent> <ESC> : call CloseSearchWindow()<CR>
    "set nomodifiable
    call search(a:k)
    call matchadd('Search', a:k)
endfunc


func! KeySearch()
    let key = expand("<cword>")
    call OpenSearchWindow(key)
endfunc

func! TestProject()
    w
    if len(g:project_path) > 0
        if has_key(g:conf_dict, "Test")
            let cmd = "cd ".g:project_path." ;". g:conf_dict["Test"]." ; cd -"
            "echo cmd
            let bytecode = system(cmd)
            echo bytecode
        endif
    endif
endfunc

func! MakeProject()
    w
    if len(g:project_path) > 0
        if has_key(g:conf_dict, "Make")
            let cmd = "cd ".g:project_path." ;". g:conf_dict["Make"]." ; cd -"
            "echo cmd
            let bytecode = system(cmd)
            echo bytecode
        endif
    endif
endfunc


func! SelectSearch()
    let t = visualmode()
    if t ==# 'v'
        normal! `<v`>y
    elseif t ==# 'char'
        normal! `[v`]y
    else
        return
    endif
    call OpenSearchWindow(@@)
endfunc

func! CloseSearchWindow()
    cclose
endfunc

func! FormatFile()
    if has_key(g:conf_dict, "Format")
        w!
        let fileName = expand("%:p")
        let cmd = g:conf_dict["Format"]." ".fileName
        "echo cmd
        let res = system(cmd)
        if len(res) && stridx(res, ":") != -1
            echo res
            return
        endif
        e!
    else
        :normal gg=G``
    endif
endfunc


call SuperSearchStart()

nnoremap ,s :call KeySearch()<cr>
vnoremap ,s :call SelectSearch()<cr>
nnoremap ,f :call FormatFile()<cr>
map <F8> :call TestProject()<CR>
map <F9> :call MakeProject()<CR>

"有的vim不支持QuitPre，先检测下
if exists('##QuitPre')
    au QuitPre * call CloseSearchWindow()
else
    if exists('##VimLeavePre')
        au VimLeavePre * call CloseSearchWindow()
    endif
endif


