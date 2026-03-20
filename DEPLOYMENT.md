# Deployment Guide

## Local Development

```bash
# 进入 site 目录，启动 Python 开发服务器
cd site
python run_server.py -d . -p 8080 -o
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-d, --dir` | 要提供的目录 | `.` |
| `-p, --port` | 监听端口 | `8080` |
| `-H, --host` | 绑定地址 | `0.0.0.0` |
| `-o, --open` | 启动后自动打开浏览器 | off |

启动后访问 http://localhost:8080/

```bash
# 停止服务器
# 在运行服务器的终端中按 Ctrl+C
```

---

## Production — Nginx + HTTPS + Certbot

## Architecture

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

- 入口 Nginx: SSL termination + `random` 负载均衡
- 两个后端实例: 纯 Nginx 静态文件服务, 互为灾备
- 任一实例宕机, `proxy_next_upstream` 自动 failover 到另一个

## Services (docker-compose.yml)

| Service | Container | Description |
|---------|-----------|-------------|
| `site-1` | `office-site-1` | 静态文件 Nginx 实例 1 |
| `site-2` | `office-site-2` | 静态文件 Nginx 实例 2 |
| `nginx` | `office-nginx` | SSL termination + load balancer |
| `certbot` | `office-certbot` | Let's Encrypt 证书管理 |

## File Structure

```
├── docker-compose.yml                         # 服务编排 (4 services)
├── init-ssl.sh                                # 首次获取证书脚本
├── renew-ssl.sh                               # 证书检测 + 自动续签脚本
├── nginx/
│   ├── Dockerfile.nginx                       # 入口 Nginx (仅配置, 不含静态文件)
│   ├── nginx.conf                             # Nginx 主配置
│   ├── ssl-params.conf                        # TLS 参数 (TLS1.2/1.3, OCSP)
│   └── confi.d/
│       ├── site-http.conf                     # HTTP: upstream + 重定向 + ACME
│       ├── site-https.conf                    # HTTPS: upstream + 反向代理
│       └── site-http-only.conf.tpl            # 初始化阶段用的纯 HTTP 模板
├── site/
│   ├── Dockerfile.site                        # 后端静态 Nginx 实例镜像
│   ├── nginx-site.conf                        # 后端 Nginx 配置 (含 /healthz)
│   └── *.html, css/, js/, assets/             # 静态资源
├── certbot/
│   ├── www/                                   # ACME webroot 验证目录
│   └── renewal-hooks/deploy/reload-nginx.sh   # 续签后热重载 Nginx
```

## Load Balancing & Failover

```nginx
upstream site_backend {
    random;                                     # 随机分发
    server site-1:80 max_fails=3 fail_timeout=10s;
    server site-2:80 max_fails=3 fail_timeout=10s;
}
```

| 机制 | 说明 |
|------|------|
| `random` | 每次请求随机选择一个实例 |
| `max_fails=3` | 连续失败 3 次后标记为不可用 |
| `fail_timeout=10s` | 标记不可用持续 10 秒后重试 |
| `proxy_next_upstream` | 请求失败时自动切换到另一个实例 |

## Deployment Steps

### 1. Prerequisites

- DNS A records point to Elastic IP `52.198.225.111`
  - `kaetsukokusai.com` → `52.198.225.111`
  - `www.kaetsukokusai.com` → `52.198.225.111`
- Docker & Docker Compose installed

### 2. First-time Setup (Obtain Certificate)

```bash
chmod +x init-ssl.sh renew-ssl.sh
CERTBOT_EMAIL=toseiyu@gmail.com ./init-ssl.sh kaetsukokusai.com www.kaetsukokusai.com
```

The script will automatically:

1. Switch Nginx to HTTP-only mode (no certs yet, 443 would fail)
2. Start site-1, site-2, and Nginx
3. Request certificate via Certbot webroot validation
4. Enable HTTPS config and rebuild all services

### 3. Auto-Renewal (Cron Job)

`renew-ssl.sh` provides certificate detection + renewal + verification:

```
┌─ Step 1: 检测证书剩余天数
│   ├─ 方式 1: openssl HTTPS 探测 (最准确)
│   └─ 方式 2: 从 Docker volume 读取证书文件 (fallback)
│
├─ Step 2: 剩余天数 > 阈值 (默认 30d) → 跳过
│
├─ Step 3: Certbot 续签 (最多重试 3 次)
│
├─ Step 4: HUP 信号热重载 Nginx
│
└─ Step 5: 续签后验证新证书
    └─ 失败 → 触发告警 webhook
```

```bash
crontab -e
```

```
0 3 * * * /home/ec2-user/office-web-app/renew-ssl.sh >> /var/log/certbot-renew.log 2>&1
```

| Variable | Default | Description |
|----------|---------|-------------|
| `DOMAIN` | auto-detect | 要检测的域名 |
| `RENEW_THRESHOLD` | `30` | 剩余天数 <= 此值时触发续签 |
| `ALERT_WEBHOOK` | (empty) | 失败时 POST 告警 (Slack/DingTalk/飞书) |

### 4. Manual Operations

```bash
# Start all services
docker compose up -d

# Rebuild and restart
docker compose up -d --build

# View logs
docker logs office-nginx
docker logs office-site-1
docker logs office-site-2

# Health check backend instances
docker compose exec site-1 curl -s http://localhost/healthz
docker compose exec site-2 curl -s http://localhost/healthz

# Manually trigger certificate renewal
docker compose run --rm certbot renew

# Reload Nginx without downtime
docker kill -s HUP office-nginx

# Test Nginx config
docker compose exec nginx nginx -t
```

## Notes

- Domain: `kaetsukokusai.com` / Elastic IP: `52.198.225.111`
- Nginx reloads via `HUP` signal — zero downtime on certificate renewal
- SSL config enforces TLS 1.2/1.3, OCSP stapling, and HSTS
- Both site instances serve identical static content; if one crashes, the other continues serving
