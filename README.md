# rm-trash

## 简介

一个运行在Mac OS X上，实现了大部分`rm`的功能，能够将文件放进回收站而不是直接删除的工具。

## 适用范围

工作在Mac OS X上，喜爱命令行操作，有时比较粗心大意一个`rm`甚至`rm -rf`命令就删除了某些重要文件的用户

## 安装
将项目文件下载后存储在能够被用户访问到的任意目录，在`~/.zshrc`或是`~/.bashrc`或是任意初始化时会执行的shell脚本中编写一个alias`rm`，用来调用项目文件中的`rm.rb`文件，并将所有参数一并传入，例如：

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
    -h, --help                       Display this help
        --rm                         Find rm from $PATH and execute it. All parameters after --rm will belong to it
        --color, --colour            Colorful output
        --no-color, --no-colour      White output
```
被`rm`删除后的文件可以在回收站中找到并且恢复

## 与`rm`的不同
* 交互时默认会输出颜色，其中红色表示错误信息，黄色表示提问，白色表示普通的信息输出。这个功能可以通过`--color`或者`--colour`，`--no-color`或者`--no-colour`开启或关闭。
* 实现了`--rm`选项，从Shell中得到原来系统自带的`rm`命令并执行。（_所以不能将本项目文件直接放进`$PATH`中去用，否则就变成递归调用了对不对啊_）
* 在试图删除没有删除权限的文件时将跳出对话框要求输入密码，而不是直接显示`Permission Denied`
* 未能实现`-P`选项，因为一旦对文件写入后再删除，该文件将无法回复
* 未能实现`-W`选项，因为被删除的文件就在回收站中，可以直接回复，无需命令行操作

## 依赖
* Ruby
	* 1.8.7 系统默认内置
	* 1.9.3
	* 2.0.0

## 已知 Bug
* 交互式递归删除文件时(即`rm -ir`)递归顺序略有差异

本程序：

```
examine files in directory dir? y
examine files in directory dir/1? y
examine files in directory dir/2? y
remove dir/1/1? y
remove dir/1/2? y
remove dir/1? y
remove dir/2/1? y
remove dir/2/2? y
remove dir/2? y
remove dir? y
```

内置：

```
examine files in directory dir? y
examine files in directory dir/1? y
remove dir/1/1? y
remove dir/1/2? y
remove dir/1? y
examine files in directory dir/2? y
remove dir/2/1? y
remove dir/2/2? y
remove dir/2? y
remove dir? y
```

* 在交互式时删除空文件夹时(即`rm -id`)，对于非空文件夹的表现略有差异
	* 本程序在这种情况下将直接显示`Directory not empty`错误
	* 系统内置的`rm`在这种情况下依然会询问用户是否删除，在用户确认删除后再显示出`Directory not empty`错误

## Bug 报告
* 登陆 `GitCafe`
* 访问 <https://gitcafe.com/bachue/rm-trash/tickets>
* 点击 `New Ticket` 按钮
* 将执行的命令，输出的错误信息写入，建议使用Markdown格式并注意排版
* 点击 `Create` 按钮即可创建
* 或是直接发送邮件到 <bachue.shu@gmail.com>

## Contributing
* Fork it from `git@gitcafe.com:bachue/rm-trash.git`
* Create your feature branch (`git checkout -b my-new-feature`)
* Commit your changes (`git commit -am 'Add some feature'`)
* Push to the branch (`git push origin my-new-feature`)
* Create new Pull Request
* Any Pull Request is Welcome

## License
Copyright (c) 2012-2013 Bachue

Released under the GPL v3 license:

http://www.gnu.org/licenses/gpl.txt
