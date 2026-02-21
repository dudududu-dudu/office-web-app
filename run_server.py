import argparse
import os
import webbrowser
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler


def parse_args():
    p = argparse.ArgumentParser(description="Serve a directory over HTTP for local preview")
    p.add_argument("-d", "--dir", default=".", help="要提供的目录（默认: 当前目录）")
    p.add_argument("-p", "--port", type=int, default=8080, help="监听端口（默认: 8000）")
    p.add_argument("-H", "--host", default="0.0.0.0", help="绑定地址（默认: 0.0.0.0，表示所有接口）")
    p.add_argument("-o", "--open", action="store_true", help="启动后在默认浏览器打开 URL")
    return p.parse_args()


def main():
    args = parse_args()
    serve_dir = os.path.abspath(args.dir)
    os.chdir(serve_dir)

    handler = SimpleHTTPRequestHandler
    server_address = (args.host, args.port)

    # 在 0.0.0.0 时，用 localhost 显示可在本机打开的 URL
    host_for_url = "localhost" if args.host == "0.0.0.0" else args.host
    url = f"http://{host_for_url}:{args.port}/"

    try:
        with ThreadingHTTPServer(server_address, handler) as httpd:
            print(f"Serving {serve_dir} at {url}")
            if args.open:
                try:
                    webbrowser.open(url)
                except Exception:
                    print("无法自动打开浏览器，请手动访问:", url)
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n已停止服务器")
    except Exception as e:
        print("服务器启动失败:", e)


if __name__ == "__main__":
    main()
