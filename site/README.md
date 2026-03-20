# Office Web App — Local Development

## Prerequisites

- Docker & Docker Compose
- Python 3.x (optional, for non Docker 方式)

## 方式一：Docker Compose (推荐)

启动完整架构：Nginx LB + 2 个静态实例

```bash
docker compose up -d --build
```

访问 http://localhost

Nginx entrypoint 会自动检测：
- 无 SSL 证书 → HTTP-only 模式（本地开发默认）
- 有 SSL 证书 → 自动启用 HTTPS + HTTP→HTTPS 重定向

### 常用命令

```bash
# 查看容器状态
docker compose ps

# 查看 Nginx 日志
docker logs office-nginx

# 查看后端实例日志
docker logs office-site-1
docker logs office-site-2

# 健康检查
docker exec office-site-1 sh -c "curl -s http://localhost/healthz"
docker exec office-site-2 sh -c "curl -s http://localhost/healthz"

# 重新构建并启动
docker compose up -d --build

# 停止所有服务
docker compose down

# 停止并清除 volumes
docker compose down -v
```

### 测试 Failover

```bash
# 停掉 site-1，验证请求自动切到 site-2
docker stop office-site-1
curl http://localhost   # 仍然 200 OK

# 恢复
docker start office-site-1
```

## 方式二：Python HTTP Server

无需 Docker，直接用 Python 启动单实例开发服务器：

```bash
cd site
python run_server.py -p 8080
```

访问 http://localhost:8080

### 参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `-d, --dir` | `.` | 要提供的目录 |
| `-p, --port` | `8080` | 监听端口 |
| `-H, --host` | `0.0.0.0` | 绑定地址 |
| `-o, --open` | off | 启动后自动打开浏览器 |

## 方式三：单容器 Site 镜像

只启动一个静态 Nginx 实例（不经过 LB）：

```bash
docker build -f site/Dockerfile.site -t office-site .
docker run --rm -p 8080:80 office-site
```

访问 http://localhost:8080
