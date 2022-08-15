## LANraragi_cn

This repo is a fork of [Difegue / LANraragi](https://github.com/Difegue/LANraragi) , those things i've done was to translate this repo into chinese ,and fix chrome browser js problem .also use user root instead of user koyomi to fix the access permissions of the content folder on synology nas.

also i've build a docker image , if you are a user of docker ,you need to mount your comic folder to "/root/lanraragi/content" directory, and the database folder to "/root/lanraragi/database" directory.

Thanks to Difegue for developing this software ！

这是LANraragi的汉化版本，相较与原版汉化了界面，修复了chrome的js报错，并且使用root账户代替koyomi解决群晖nas上面的无法访问挂载文件夹/home/koyomi/lanraragi/content目录的问题,我构建了一个docker镜像，如果你是docker用户，你需要将漫画文件夹挂载到/root/lanraragi/content，数据库挂载到/root/lanraragi/database。

## 简介


Lanraragi是一个开源的压缩包漫画阅读器，运行在Mojolicious和Redis基础上。

[<img src="https://img.shields.io/docker/pulls/dezhao/lanraragi_cn.svg">](https://hub.docker.com/r/dezhao/lanraragi_cn/)
[![IC](https://github.com/uparrows/LANraragi_cn/actions/workflows/docker-image.yml/badge.svg?branch=main)](https://github.com/uparrows/LANraragi_cn/actions/workflows/docker-image.yml)

[⏬ 下载源码](https://github.com/uparrows/LANraragi_cn/releases/latest) |[📄 教程](http://yuanfangblog.xyz/technology/251.html) |

安卓客户端：https://f-droid.org/packages/com.utazukin.ichaival/

IOS客户端(用AltStore安装)： https://github.com/Doraemoe/DuReader/releases
AltStore:https://altstore.io/

Windows客户端： https://www.microsoft.com/zh-cn/p/lrreader/9mz6bwwvswjh

## 扫码直接查看教程

[<img src="https://user-images.githubusercontent.com/38988286/111801925-65776800-8908-11eb-8b13-283a4d21e41c.jpg">](http://yuanfangblog.xyz/technology/251.html)



## 截图  
 
|主页, 预览图 | 主页, 列表模式 |
|---|---|
| [![archive_thumb](https://user-images.githubusercontent.com/38988286/111873262-6f619f80-89ca-11eb-8891-7437f1d08cb4.png)](https://user-images.githubusercontent.com/38988286/111873262-6f619f80-89ca-11eb-8891-7437f1d08cb4.png) | [![archive_list](https://user-images.githubusercontent.com/38988286/111873240-5822b200-89ca-11eb-8c0c-17b3bd374a9b.png)](https://user-images.githubusercontent.com/38988286/111873240-5822b200-89ca-11eb-8c0c-17b3bd374a9b.png) |

|阅读器 | 预览 |
|---|---|
| [![reader](https://user-images.githubusercontent.com/38988286/111873285-899b7d80-89ca-11eb-8868-5431e7a117f9.jpg)](https://user-images.githubusercontent.com/38988286/111873285-899b7d80-89ca-11eb-8868-5431e7a117f9.jpg) | [![reader_overlay](https://user-images.githubusercontent.com/38988286/111873298-915b2200-89ca-11eb-8d61-cc67dca038f0.jpg)](https://user-images.githubusercontent.com/38988286/111873298-915b2200-89ca-11eb-8d61-cc67dca038f0.jpg) |


|配置 | 插件配置 |
|---|---|
| [![cfg](https://user-images.githubusercontent.com/38988286/111873270-78527100-89ca-11eb-9526-35f1f78b578f.png)](https://user-images.githubusercontent.com/38988286/111873270-78527100-89ca-11eb-9526-35f1f78b578f.png) | [![cfg_plugin](https://user-images.githubusercontent.com/38988286/111873273-7f797f00-89ca-11eb-89b4-b3c21228c949.png)](https://user-images.githubusercontent.com/38988286/111873273-7f797f00-89ca-11eb-89b4-b3c21228c949.png) |


## 功能

*以存档格式存储您的漫画。 （支持zip / rar / targz / lzma / 7z / xz / cbz / cbr / pdf，epub准支持）

*直接从Web浏览器读取档案：服务器使用临时文件夹从压缩文件中读取。

*使用内置的OPDS目录在专用的阅读器软件中阅读档案

*使用客户端API与其他程序中的LANraragi进行交互

*两种不同的用户界面：紧凑的存档列表，带有悬停缩略图或缩略图视图。

*从5种预装的响应库样式中进行选择，或使用CSS添加您自己的样式。

*命名空间的完整标签支持：添加您自己的名称或使用插件从其他来源导入它们。

*设置收藏夹标签，以便能够快速在您的收藏夹中找到包含它们的档案

*自动标记：将存档添加到LANraragi后，将使用插件自动导入元数据。

*将数据库备份为JSON，以将标签传递到另一个LANraragi实例。
