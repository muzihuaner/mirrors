# Quick Mirror
快点开源软件镜像站，致力于为国内用户提供高质量的开源软件镜像、Linux 镜像源服务，帮助用户更方便地获取开源软件。本镜像站由HuanGeTech负责运行维护。  
https://imirrors.quickso.cn/

### 技术栈:
操作系统：Centos8/Debian12  
镜像同步：[tunasync](https://github.com/tuna/tunasync)  
Web服务：[Caddy](https://caddyserver.com/)

### 项目结构
```
mirrors/ #项目目录
├── Caddy #Caddy配置文件及docker-compose启动文件
│   ├── Caddyfile
│   └── docker-compose.yml
├── mirrors #网页目录
│   ├── index.html 
│   ├── isoinfo.json #常用发行版 ISO 和应用软件安装包信息文件
│   ├── jobs.json #同步状态文件
│   ├── scripts #同步脚本
│   │   ├── github-release.json
│   │   ├── github-release.py
│   │   └── sync_wepe.sh
│   ├── static #网页静态资源
│   │   ├── jquery-1.11.3.min.js
│   │   ├── main.js
│   │   ├── mirror.css
│   │   └── mirror.js
│   └── status #服务器状态网页及资源
│       ├── cpu.png
│       ├── cpu.rrd
│       ├── index.html
│       ├── memory.png
│       ├── memory.rrd
│       ├── network.png
│       ├── network.rrd
│       ├── README.md
│       └── update_rrd.sh
├── README.md #项目概述
└── tunasync #tunasync配置文件夹
    ├── manager.conf
    ├── manager.db
    └── worker.conf
```
### 如何搭建？
https://blog.quickso.cn/2025/01/03/%E4%BD%BF%E7%94%A8tunasync%E6%90%AD%E5%BB%BA%E8%87%AA%E5%B7%B1%E7%9A%84%E5%BC%80%E6%BA%90%E8%BD%AF%E4%BB%B6%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/



### 定时任务 crontab -e

```
*/1 * * * * wget -q http://127.0.0.1:12345/jobs -O /home/www/mirrors/jobs.json -o /home/www/mirrors/logs/wget.log
* * * * * /home/www/mirrors/status/update_rrd.sh
*/5 * * * * wget -O /home/www/mirrors/isoinfo.json https://mirrors.tuna.tsinghua.edu.cn/static/status/isoinfo.json
```
