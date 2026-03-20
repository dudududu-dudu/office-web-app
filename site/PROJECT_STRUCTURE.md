# 華悦国際司法書士・行政書士事務所 - 网站项目文档

## 项目概述

**项目名称**: office-web-app
**项目类型**: 静态网站 (Nginx 双实例 + SSL)
**域名**: kaetsukokusai.com
**Elastic IP**: 52.198.225.111
**主题**: 司法书士事务所（日本法律服务机构）的官方网站
**语言**: 中文（简体）/ 日本語
**特点**: 响应式设计、PWA支持、多页面布局、双实例灾备

---

## 📁 文件结构

```
office-web-app/
├── 🔧 部署与编排
│   ├── docker-compose.yml                  # 服务编排 (nginx + site-1 + site-2 + certbot)
│   ├── init-ssl.sh                         # 首次获取 Let's Encrypt 证书
│   ├── renew-ssl.sh                        # 证书检测 + 自动续签
│   └── .dockerignore                       # Docker 忽略文件
│
├── 📁 nginx/                               # 入口 Nginx (SSL + LB)
│   ├── Dockerfile.nginx                    # 入口 Nginx 镜像
│   ├── nginx.conf                          # Nginx 主配置
│   ├── ssl-params.conf                     # TLS 参数 (TLS1.2/1.3, OCSP)
│   ├── docker-entrypoint-extra.sh          # 自动检测证书切换 HTTP/HTTPS
│   └── confi.d/
│       ├── site-http.conf                  # HTTP: upstream + 重定向 + ACME
│       ├── site-https.conf                 # HTTPS: upstream + 反向代理
│       └── site-http-only.conf.tpl         # 无证书时的 HTTP-only 模板
│
├── 📁 certbot/                             # Let's Encrypt 证书管理
│   ├── www/                                # ACME webroot 验证目录
│   └── renewal-hooks/deploy/
│       └── reload-nginx.sh                 # 续签后热重载 Nginx
│
├── 📁 site/                                # 静态网站内容
│   ├── Dockerfile.site                     # 后端 Nginx 静态实例镜像
│   ├── nginx-site.conf                     # 后端 Nginx 配置 (含 /healthz)
│   ├── run_server.py                       # Python HTTP 服务器 (本地开发)
│   ├── dockerfile                          # Python 服务器 Docker 镜像 (legacy)
│   ├── site.webmanifest                    # PWA 清单文件
│   │
│   ├── 📄 HTML 页面 (6 个)
│   │   ├── index.html                      # 主页 - 费用参考与委托说明
│   │   ├── services.html                   # 业务范围
│   │   ├── pricing.html                    # 费用说明
│   │   ├── office.html                     # 事务所介绍
│   │   ├── inheritance-international.html  # 国际继承服务
│   │   └── faq.html                        # 常见问题
│   │
│   ├── 📁 css/                             # 样式文件
│   │   ├── styles.css                      # 主样式表 (99KB)
│   │   └── vendor.css                      # 第三方样式 (20KB)
│   │
│   ├── 📁 js/                              # JavaScript 脚本
│   │   ├── main.js                         # 主脚本 (12KB)
│   │   ├── consult-dialog.js               # 咨询对话框组件 (1.4KB)
│   │   └── plugins.js                      # 插件库 (159KB)
│   │
│   └── 📁 assets/images/                   # 统一图片资源目录
│       ├── avatars/                         # 人物头像
│       ├── clients/                         # 客户 Logo (10 个 SVG)
│       ├── icons/                           # 图标集合 (3 个 SVG)
│       ├── qr/                              # 二维码
│       ├── thumbs/                          # 缩略图 (about/contact/location/single)
│       ├── logo.svg, kaetsu_panda_only.svg  # 品牌元素
│       ├── intro-bg.jpg, intro-bg@2x.jpg   # 背景图 (标准/Retina)
│       ├── sample-*.jpg, wheel-*.jpg        # 多分辨率图片
│       └── favicon.ico, favicon-*.png       # 网站图标
│
└── 📄 文档
    ├── DEPLOYMENT.md                        # 生产部署指南
    ├── site/README.md                       # 本地开发指南
    ├── site/PROJECT_STRUCTURE.md            # 本文档
    ├── site/ASSET_STRUCTURE.md              # 资源整理报告
    └── site/REORGANIZATION_SUMMARY.md       # 重组总结
```

---

## 🏗️ 架构

```
                         ┌──────────────┐
                         │  Nginx (LB)  │
Client ─► :80  (HTTP) ──►  SSL 终端     │
Client ─► :443 (HTTPS) ─►  随机分发     │
                         └──────┬───────┘
                                │ random
                     ┌──────────┴──────────┐
                     ▼                     ▼
              ┌─────────────┐       ┌─────────────┐
              │   site-1    │       │   site-2    │
              │  Nginx :80  │       │  Nginx :80  │
              │  纯静态文件  │       │  纯静态文件  │
              └─────────────┘       └─────────────┘
```

| Service | Container | Description |
|---------|-----------|-------------|
| `site-1` | `office-site-1` | 静态文件 Nginx 实例 1 |
| `site-2` | `office-site-2` | 静态文件 Nginx 实例 2 |
| `nginx` | `office-nginx` | SSL termination + load balancer |
| `certbot` | `office-certbot` | Let's Encrypt 证书管理 |

---

## 🌐 页面说明

| 页面文件 | 标题 | 功能说明 |
|---------|-----|--------|
| `index.html` | 費用参考与委托说明 | 主页，展示核心服务和费用 |
| `services.html` | 业务范围 | 详细的业务服务列表 |
| `pricing.html` | 费用说明 | 各项服务的详细价格 |
| `office.html` | 事务所介绍 | 公司背景、团队信息 |
| `inheritance-international.html` | 国际继承 | 国际继承服务的特殊页面 |
| `faq.html` | 常见问题 | FAQ知识库 |

---

## 🎨 样式系统

### CSS文件结构
- **vendor.css** (20KB): 第三方框架和重置样式
- **styles.css** (99KB): 自定义样式、布局、组件样式

### 主要特性
- 响应式设计（移动端优先）
- 预加载器动画（dots-fade）
- CSS变量支持
- 页面类 (`ss-home`) 便于页面特定样式

---

## 📜 JavaScript功能

### main.js (12KB)
- 页面交互逻辑
- DOM事件处理
- 动画和过渡效果

### consult-dialog.js (1.4KB)
- 咨询对话框组件
- 模态对话框处理
- 用户交互管理

### plugins.js (159KB)
- 第三方库和工具函数集合
- 依赖库（如jQuery、Swiper等）

---

## 🚀 部署与运行

### 生产部署
详见 [DEPLOYMENT.md](../DEPLOYMENT.md)

```bash
# 首次部署（获取证书 + 启动服务）
CERTBOT_EMAIL=toseiyu@gmail.com ./init-ssl.sh kaetsukokusai.com www.kaetsukokusai.com

# 日常启动
docker compose up -d --build
```

### 本地开发
详见 [site/README.md](README.md)

```bash
# Docker Compose（推荐）
docker compose up -d --build
# 访问 http://localhost

# Python 快速启动
cd site && python run_server.py -p 8080
# 访问 http://localhost:8080
```

---

## 🖼️ 媒体资源管理

### 图像分类
1. **背景图**: intro-bg.jpg, intro-bg@2x.jpg, intro.jpg
2. **响应式图**: sample-600.jpg, sample-1200.jpg, sample-2400.jpg
3. **轮廓/装饰**: wheel-500.jpg, wheel-1000.jpg, wheel-2000.jpg
4. **品牌元素**: logo.svg, kaetsu_panda_only.svg, geometric_shape.svg
5. **用户/头像**: 存储在 `assets/images/avatars/`
6. **客户图像**: 存储在 `assets/images/clients/`
7. **图标集**: 存储在 `assets/images/icons/`
8. **二维码**: 存储在 `assets/images/qr/`

### 响应式策略
- 多分辨率版本支持 (600px, 1000px, 1200px, 2000px, 2400px)
- @2x 变体用于Retina显示屏
- SVG格式用于Logo和矢量图形

---

## 🌍 多语言和国际化

- **主要语言**: 中文（简体）
- **语言支持**: 日本語（部分页面）
- **字符编码**: UTF-8
- **方向**: LTR（左到右）

---

## ✨ 网站特性

1. **PWA支持**
   - Web manifest 配置
   - 离线操作支持
   - App图标配置

2. **SEO优化**
   - 语义化HTML
   - Meta标签完整
   - Robots指令 (index, follow)

3. **性能优化**
   - 预加载器
   - 图像响应式处理
   - 资源懒加载

4. **高可用**
   - 双实例灾备
   - random 负载均衡
   - proxy_next_upstream 自动 failover

---

## 📊 项目统计

| 项目 | 数量 |
|-----|------|
| HTML页面 | 6 |
| CSS文件 | 2 |
| JavaScript文件 | 3 |
| 图像资源 | 40 |
| Docker 服务 | 4 (nginx, site-1, site-2, certbot) |
| Shell 脚本 | 3 (init-ssl, renew-ssl, reload-nginx) |
| Nginx 配置 | 6 |

---

## 🔄 技术栈

- **前端框架**: 原生HTML5 + CSS3 + JavaScript
- **响应式**: CSS Media Queries
- **Web 服务器**: Nginx 1.27 (Alpine)
- **SSL**: Let's Encrypt + Certbot (自动续签)
- **负载均衡**: Nginx upstream random
- **容器**: Docker Compose
- **本地开发**: Python SimpleHTTPServer (可选)
- **版本控制**: Git

---

## 📝 Git信息

- **当前分支**: prince
- **主分支**: main
- **域名**: kaetsukokusai.com
- **服务器**: AWS EC2 (Elastic IP: 52.198.225.111)

---

## 🎯 项目用途

这是一个专业的司法书士事务所官方网站，主要功能：
- 展示法律服务范围
- 提供费用透明度
- 客户咨询接触点
- 机构信息展示
- 多语言客户支持

---

## 📞 主要联系点

- **咨询对话框**: JavaScript交互组件
- **服务范围**: services.html 页面
- **常见问题**: faq.html 页面

---

**文档更新日期**: 2026-03-15
**项目分支**: prince
**维护者**: office-web-app team
