FROM python:3.12-slim

RUN useradd -m appuser

WORKDIR /app

COPY . /app

EXPOSE 8080

USER appuser

CMD ["python", "run_server.py", "-H", "0.0.0.0", "-p", "8080", "-d", "."]
