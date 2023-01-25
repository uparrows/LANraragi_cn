## LANraragi_CN

This repo is a fork of [Difegue / LANraragi](https://github.com/Difegue/LANraragi) , those things i've done was to translate this repo into chinese。

这个仓库是[Difegue / LANraragi](https://github.com/Difegue/LANraragi)的一个分支,我所作的是将这个软件上的文字翻译为中文。

## 简介


Lanraragi是一个开源的压缩包漫画阅读器，运行在Mojolicious和Redis基础上。

[<img src="https://img.shields.io/docker/pulls/dezhao/lanraragi_cn.svg">](https://hub.docker.com/r/dezhao/lanraragi_cn/)
[![IC](https://github.com/uparrows/LANraragi_cn/actions/workflows/docker-image.yml/badge.svg?branch=main)](https://github.com/uparrows/LANraragi_cn/actions/workflows/docker-image.yml)

[⏬ 下载源码](https://github.com/uparrows/LANraragi_cn/releases/latest) |[📄 教程](http://yuanfangblog.xyz/technology/251.html) |

安卓客户端（已提交中文支持）：https://f-droid.org/packages/com.utazukin.ichaival/

IOS客户端(用AltStore安装)： https://github.com/Doraemoe/DuReader/releases
AltStore:https://altstore.io/

Windows客户端（已提交中文支持）： https://www.microsoft.com/zh-cn/p/lrreader/9mz6bwwvswjh

tachiyomi客户端：https://github.com/tachiyomiorg/tachiyomi-extensions/

alfareader(Windows)：https://www.alfareader.org/

<img src="public/favicon.ico" width="128">  

LANraragi
===========

用于漫画浏览查看的开源服务器软件, 基于 Mojolicious + Redis 提供服务.

#### 💬 与其他LANraragi用户交流 [Discord](https://discord.gg/aRQxtbg) or [GitHub Discussions](https://github.com/Difegue/LANraragi/discussions)  

####  [📄 文档](https://sugoi.gitbook.io/lanraragi/v/dev) | [⏬ 下载](https://github.com/Difegue/LANraragi/releases/latest) | [🎞 演示](https://lrr.tvc-16.science) | [🪟🌃 Windows版构建包下载](https://nightly.link/Difegue/LANraragi/workflows/push-continous-delivery/dev) | [💵 赞助](https://ko-fi.com/T6T2UP5N)  



## 截图  
 
|主页, 预览图 | 主页, 列表模式 |
|---|---|
| [![archive_thumb](./tools/_screenshots/archive_thumb.png)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/archive_thumb.png) | [![archive_list](./tools/_screenshots/archive_list.png)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/archive_list.png) |

|阅读器 | 预览 |
|---|---|
| [![reader](./tools/_screenshots/reader.jpg)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/reader.jpg) | [![reader_overlay](./tools/_screenshots/reader_overlay.jpg)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/reader_overlay.jpg) |


|配置 | 插件配置 |
|---|---|
| [![cfg](./tools/_screenshots/cfg.png)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/cfg.png) | [![cfg_plugin](./tools/_screenshots/cfg_plugin.png)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/cfg_plugin.png) |


## 功能

* 以存档格式存储您的漫画。 （支持zip / rar / targz / lzma / 7z / xz / cbz / cbr / pdf，epub准支持）

* 直接从Web浏览器读取档案：服务器使用临时文件夹从压缩文件中读取。

* 使用内置的OPDS目录（现在支持 PSE！）在专用的阅读器软件中阅读档案

* 使用客户端API与其他程序中的LANraragi进行交互(适用于[很多平台!](https://sugoi.gitbook.io/lanraragi/v/dev/advanced-usage/external-readers))

* 多种不同的用户界面：紧凑的存档列表，带有悬停缩略图或缩略图视图。

* 自带5中格式风格的主题，或使用CSS添加属于自己的主题。

* 完整的Tag支持：添加属于你的Tag或使用插件从其他来源导入它们。

* 设置收藏夹标签，以便能够快速在您的收藏夹中找到包含它们的档案

* 自动标记：将存档添加到LANraragi后，将使用插件自动导入或获取元数据。

* 将数据库备份为JSON，以将您的设置和元数据、Tag迁移至另一个LANraragi实例。

## 代码分享或捐赠

提交合并到仓库或者(赞助5美元)可以获得一份LRR贴纸包 [填写送货地址](https://forms.office.com/Pages/ResponsePage.aspx?id=DQSIkWdsW0yxEjajBLZtrQAAAAAAAAAAAAN__osxt25URTdTUTVBVFRCTjlYWFJLMlEzRTJPUEhEVy4u) 