" File: supersearch.vim
" Author: Tian (root AT codecn DOT org)
" Version: 1.0
" Last Modified: 2015.06.17
" Copyright: Copyright (C) 2015 Tian
"
" The "Super Search" plugin is a source code browser plugin for Vim and provides
" an overview of the structure of the programming language files and allows
" you to efficiently browse through source code files for different
" programming languages.  You can visit the supersearch plugin home page for more
" information:
"
"       https://github.com/c-wind/supersearch
"
" Installation
" ------------
" 1. Download the supersearch.zip file and unzip the files to the $HOME/.vim/plugin/
"    The directory structure should be preserved:
"    $HOME/.vim/plugin/supersearch.vim
"
" 2. Create a profile in the top-level directory of the project ("project.conf")
"
" 3. finished
"
"
" Example
" ------------
" Project directory structure:
" └── src
"      ├── core
"      ├── event
"      ├── http
"      ├── mail
"      ├── misc
"      └── os
" The configuration file (project.conf):
" /http
" /core
" /event
" /mail
" /misc
" /os
"
"这个项目是用来加速vim开发效率的
"1.由于历史原因我们的项目目录中有许多无关的目录包含着无关的代码，导致生成的tags文件往往没有实际用途
"2.当我们需要查看谁调用谁的问题时，要用:grep命令来搜索整个项目目录，相当不方便
"
"现在好了：
"有了supersearch插件，只要配置好与自己有关和目录，生成tags的事再也不用担心了（会自动生成tags文件），还能根据配置的目录进行全文搜索
"
"跳转继续使用传统的ctrl+]
"全文搜索目前定义为,s
"    在命令模式中,s直接搜索当前单词
"    在视图模式中先选择要搜索的文本，再按,s
"
"最后：
"        在插件文件的尾部定义了搜索快捷键，你可以自己修改为你喜欢的
"
"
"


set tags=/usr/include/tags
let g:conf_name = "project.conf"
let g:source_path = []

func! FileSupportCheck()
        let ftype = expand("%:e")
        if ftype ==? "c" || ftype ==? "cpp" || ftype ==? "cc" || ftype ==? "java" || ftype ==? "py" ||  ftype ==? "h"
                return 1
        endif
        return 0
endfunc

"获取配置文件中的源码目录，如果没有配置文件，返回当前目录
func! GetSourcePath()
        let path_array = split(expand("%:p"), "/")
        let path_index = len(path_array)

        while path_index > 1
                let config_path = "/".join(path_array[0:path_index - 1], "/")
                let config_file = findfile(g:conf_name, config_path)
                if config_file != ""
                        let conf = readfile(config_file)
                        let i = 0
                        "去掉无用的信息,只保留第一段配置内容
                        while i < len(conf)
                                let conf[i] = config_path.split(conf[i])[0]
                                let g:source_path = add(g:source_path, conf[i])
                                let i+=1
                        endwhile
                        return conf
                endif
                let path_index -= 1
        endwhile
        return ["."]
endfunc


func! CreateTags(path)
        let ls_cmd =  "ls -t1 ".a:path." |head -n 1"
        let res = system(ls_cmd)
        if split(res)[0] != "tags"
                "echo "create tags:".a:path."/tags"
                let mk_tags_cmd = "cd ".a:path.";ctags -R --c-kinds=+lp --c++-kinds=+px --fields=+iaS --extra=+q;cd -"
                let xxx = system(mk_tags_cmd)
        endif
endfunc

func! GetTagsPath()
        let path_array = GetSourcePath()
        let idx = len(path_array)

        while idx > 0
                call CreateTags(path_array[idx - 1])
                let path_array[idx - 1] = path_array[idx - 1]."/tags"
                let idx -= 1
        endwhile
        return path_array
endfunc

function! SuperSearchStart()
        if !FileSupportCheck()
                return
        endif
        let tags_path = GetTagsPath()
        let idx = len(tags_path)

        while idx > 0
                let set_tags_cmd = "set tags+=".tags_path[idx - 1]
                exe set_tags_cmd
                let idx -= 1
        endwhile

endfunction




func! OpenFile()
        let info = split(getline("."), ":")
        if len(info) < 1
                return
        endif
        let filename = info[0]
        let linenumber = info[1]
        "关闭搜索窗口
        call CloseSearchWindow()
        execute "edit +".linenumber." ".filename
endfunc



func! OpenSearchWindow(k)
        let key = shellescape(a:k)
        copen
        let path = join(g:source_path, " ")
        let grep_cmd = "find ".path." ! -name 'tags' -type f|xargs grep --exclude-dir='.svn' -Rn ".key
       " echo grep_cmd
        let bytecode = system(grep_cmd)
        set modifiable
        call append(0, split(bytecode, '\v\n'))
        nnoremap <buffer> <silent> <CR> : call OpenFile()<CR>
        nnoremap <buffer> <silent> <ESC> : call CloseSearchWindow()<CR>
        set nomodifiable
        call search(a:k)
        call matchadd('Search', a:k)
endfunc

func! KeySearch()
        let key = expand("<cword>")
        call OpenSearchWindow(key)
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


call SuperSearchStart()

nnoremap ,s :call KeySearch()<cr>
vnoremap ,s :call SelectSearch()<cr>


