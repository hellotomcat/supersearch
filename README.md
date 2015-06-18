The "Super Search" plugin is a source code browser plugin for Vim and provides
an overview of the structure of the programming language files and allows
you to efficiently browse through source code files for different
programming languages.  You can visit the supersearch plugin home page for more
information:

      https://github.com/hellotomcat/supersearch

这个项目是用来加速vim开发效率的
1.由于历史原因我们的项目目录中有许多无关的目录包含着无关的代码，导致生成的tags文件往往没有实际用途
2.当我们需要查看谁调用谁的问题时，要用:grep命令来搜索整个项目目录，相当不方便

现在好了：
有了supersearch插件，只要配置好与自己有关和目录，生成tags的事再也不用担心了（会自动生成tags文件），还能根据配置的目录进行全文搜索

跳转继续使用传统的ctrl+]
全文搜索目前定义为,s
    在命令模式中,s直接搜索当前单词
    在视图模式中先选择要搜索的文本，再按,s


Installation
------------
1. Download the supersearch.zip file and unzip the files to the $HOME/.vim/plugin/
   The directory structure should be preserved:
   $HOME/.vim/plugin/supersearch.vim

2. Create a profile in the top-level directory of the project ("project.conf")

3. finished

直接把这个supersearch.vim放到.vim/plugin/目录中就可以了


Example
------------
Project directory structure:
src<br />
    --http<br />
    --core<br />
    --event<br />
    --mail<br />
    --misc<br />
    --os<br />
The configuration file (project.conf):
/http
/core
/event
/mail
/misc
/os


最后：
在插件文件的尾部定义了搜索快捷键，你可以自己修改为你喜欢的

