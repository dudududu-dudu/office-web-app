# 華悦国際司法書士事務所 - 网站项目文档

## 项目概述

**项目名称**: office-web-app
**项目类型**: 静态网站 + Python服务器
**主题**: 司法书士事务所（日本法律服务机构）的官方网站
**语言**: 中文（简体）/ 日本語
**特点**: 响应式设计、PWA支持、多页面布局

---

## 📁 文件结构

```
office-web-app/
├── 📄 HTML页面（7个）
│   ├── index.html                    # 主页 - 费用参考与委托说明
│   ├── services.html                 # 业务范围
│   ├── pricing.html                  # 费用说明
│   ├── office.html                   # 事务所介绍
│   ├── inheritance-international.html # 国际继承服务
│   ├── faq.html                      # 常见问题
│   └
│
├── 📁 css/                           # 样式文件
│   ├── styles.css                    # 主样式表 (99KB)
│   └── vendor.css                    # 第三方样式 (20KB)
│
├── 📁 js/                            # JavaScript脚本
│   ├── main.js                       # 主脚本 (12KB)
│   ├── consult-dialog.js             # 咨询对话框组件 (1.4KB)
│   └── plugins.js                    # 插件库 (159KB)
│
├── 📁 images/                        # 媒体资源
│   ├── avatars/                      # 人物头像
│   ├── clients/                      # 客户相关图像
│   ├── icons/                        # 图标集合
│   ├── qr/                           # 二维码
│   ├── thumbs/                       # 缩略图
│   ├── logo.svg                      # 公司Logo
│   ├── geometric_shape.svg           # 几何形状装饰
│   ├── kaetsu_panda_only.svg        # 品牌吉祥物图
│   ├── intro-bg.jpg                  # 背景图（低分辨率）
│   ├── intro-bg@2x.jpg               # 背景图（高分辨率）
│   ├── intro.jpg                     # 介绍图（高分辨率 3.7MB）
│   ├── sample-*.jpg                  # 样本图（多分辨率版本）
│   ├── user.jpg                      # 用户头像
│   └── wheel-*.jpg                   # 轮廓图（多分辨率版本）
│
├── 🔧 配置和部署文件
│   ├── run_server.py                 # Python HTTP服务器脚本
│   ├── dockerfile                    # Docker镜像配置
│   ├── .dockerignore                 # Docker忽略文件
│   ├── site.webmanifest              # PWA清单文件
│   └── README.md                     # 简单说明
│
├── 🖼️ 图标文件
│   ├── favicon.ico                   # 网站图标
│   ├── favicon-16x16.png             # 16x16图标
│   ├── favicon-32x32.png             # 32x32图标
│   ├── apple-touch-icon.png          # iOS图标 (180x180)
│   ├── android-chrome-192x192.png    # Android图标
│   └── android-chrome-512x512.png    # Android启动图标
│
└── .git/                             # Git版本控制


📊 文件统计:
- 总文件数: ~200+
- 图像资源: 38个
- HTML页面: 7个
- CSS文件: 2个
- JS文件: 3个
```

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

### 本地开发
```bash
# 启动Python内置HTTP服务器
python run_server.py

# 可用选项：
python run_server.py -d . -p 8080 -H 0.0.0.0 -o
# -d: 服务目录（默认: 当前目录）
# -p: 端口（默认: 8080）
# -H: 绑定地址（默认: 0.0.0.0）
# -o: 启动后自动打开浏览器
```

### Docker部署
```bash
# 构建镜像
docker build -t office-web-app .

# 运行容器
docker run -p 8080:8080 office-web-app
```

**Dockerfile配置**:
- 基础镜像: `python:3.12-slim`
- 工作用户: `appuser`（非root）
- 暴露端口: 8080
- 启动命令: Python HTTP服务器

---

## 🔧 配置文件

### site.webmanifest (PWA)
```json
{
  "name": "",
  "short_name": "",
  "icons": [
    {"src": "/android-chrome-192x192.png", "sizes": "192x192"},
    {"src": "/android-chrome-512x512.png", "sizes": "512x512"}
  ],
  "theme_color": "#ffffff",
  "background_color": "#ffffff",
  "display": "standalone"
}
```

### .dockerignore
排除Docker构建不需要的文件

---

## 🖼️ 媒体资源管理

### 图像分类
1. **背景图**: intro-bg.jpg, intro-bg@2x.jpg, intro.jpg
2. **响应式图**: sample-600.jpg, sample-1200.jpg, sample-2400.jpg
3. **轮廓/装饰**: wheel-500.jpg, wheel-1000.jpg, wheel-2000.jpg
4. **品牌元素**: logo.svg, kaetsu_panda_only.svg, geometric_shape.svg
5. **用户/头像**: 存储在 `images/avatars/`
6. **客户图像**: 存储在 `images/clients/`
7. **图标集**: 存储在 `images/icons/`
8. **二维码**: 存储在 `images/qr/`

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

4. **无障碍设计**
   - 类名检测JS支持 (no-js / js)
   - 语义化标记

---

## 📊 项目统计

| 项目 | 数量 |
|-----|------|
| HTML页面 | 7 |
| CSS文件 | 2 |
| JavaScript文件 | 3 |
| 图像资源 | 38+ |
| 配置文件 | 6 |
| 总文件数 | 200+ |
| **项目总大小** | **~4.5MB** |

---

## 🔄 技术栈

- **前端框架**: 原生HTML5 + CSS3 + JavaScript
- **响应式**: CSS Media Queries
- **服务器**: Python SimpleHTTPServer (开发) / Docker (生产)
- **容器**: Docker + Python 3.12
- **版本控制**: Git

---

## 📝 Git信息

- **当前分支**: prince
- **主分支**: main
- **最近提交**: 82d9dc2 (first commit)
- **状态**: 干净（无未提交更改）

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

**文档生成日期**: 2026-03-15
**项目分支**: prince
**维护者**: office-web-app team
