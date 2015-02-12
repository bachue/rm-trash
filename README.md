# rm-trash

## 简介

一个运行在Mac OS X上，实现了大部分`rm`的功能，能够将文件放进回收站而不是直接删除的工具。

## 适用范围

工作在Mac OS X上，喜爱命令行操作，有时比较粗心大意一个`rm`甚至`rm -rf`命令就删除了某些重要文件的用户

## 安装
将项目文件下载后存储在能够被用户访问到的任意目录，在`~/.zshrc`或是`~/.bashrc`或是任意初始化时会执行的shell脚本中编写一个alias`rm`，用来调用项目文件中的`rm.rb`文件，例如：

```
alias rm="$ZSH/bin/rm-trash/rm.rb"
```
***请注意务必授予 rm.rb 文件执行权限 !***

## 使用
与`rm`命令几乎一致，可以通过`rm --help`获得帮助

```
Usage: rm [options] file...
    -v                               Be verbose when deleting files, showing them as they are removed.
    -d                               Attempt to remove directories as well as other types of files.
    -R                               Attempt to remove the file hierarchy rooted in each file argument.  The -R option implies the -d option. If the -i option is specified, the user is prompted for confirmation before each directory's contents are processed (as well as before the attempt is made to remove the directory).  If the user does not respond affirmatively, the file hierarchy rooted in that directory is skipped.
    -r                               Equivalent to -R.
    -i                               Request confirmation before attempting to remove each file, regardless of the file's permissions, or whether or not the standard input device is a terminal.  The -i option overrides any previous -f options.
    -f                               Attempt to remove the files without prompting for confirmation, regardless of the file's permissions.  If the file does not exist, do not display a diagnostic message or modify the exit status to reflect an error.  The -f option overrides any previous -i options.
    -h, --help                       Display this help.
        --rm                         Attempt to remove the files by /bin/rm instead.
        --color, --colour            Colorful output.
        --no-color, --no-colour      Output only plain text.
```
被`rm`删除后的文件可以在回收站中找到并且恢复

## 与`rm`的不同
* 交互时默认会输出颜色，其中红色表示错误信息，黄色表示提问，白色表示普通的信息输出。这个功能可以通过`--color`或者`--colour`，`--no-color`或者`--no-colour`开启或关闭。
* 实现了`--rm`选项，从Shell中得到原来系统自带的`rm`命令并执行。（_所以不能将本项目文件直接放进`$PATH`中去用，否则就变成递归调用了对不对啊_）
* 在试图删除没有删除权限的文件时将跳出对话框要求输入密码，而不是直接显示`Permission Denied`。如果在一定时间内依然没有输入密码将显示`delete timeout`。
* 对于UNIX的Socket文件和Pipe文件，`rm-trash`无法将这样的文件直接放入回收站中，此时将提示是否不经过回收站而直接删除。
* 为了使得用户知道修复了更多Bug的新版本已经发布，每次使用该工具时，后台将自动检查新版本并提示用户升级。
* 未能实现`-P`选项，因为一旦对文件写入后再删除，该文件将无法回复
* 未能实现`-W`选项，因为被删除的文件就在回收站中，可以直接回复，无需命令行操作

## 依赖
* Ruby
    * 1.8.7
    * 1.9.3
    * 2.0.0 系统默认内置
    * 2.x.y

## 如何更新
在每次使用本工具时，后台会自动检查是否有新的版本发布。如果有的话，则提示用户前往更新。

更新方法如下：
1. 如果之前用户是直接下载源代码压缩包来安装本工具的话，则请重新下载一次源代码压缩包，解压缩并且覆盖之前安装的文件。
2. 如果之前用户使用Git下载源代码来安装本工具的话，则请执行`git pull origin master`命令即可自动更新源代码。

## Contributing
* Fork it from `git@gitcafe.com:bachue/rm-trash.git`
* Create your feature branch (`git checkout -b my-new-feature`)
* Commit your changes (`git commit -am 'Add some feature'`)
* Push to the branch (`git push origin my-new-feature`)
* Create new Pull Request
* Any Pull Request is Welcome

## License
Copyright (c) 2012-2014 Bachue

Released under the GPL v3 license:

http://www.gnu.org/licenses/gpl.txt
