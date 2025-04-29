# --------------------- 第一阶段：构建阶段（使用完整镜像） ---------------------
FROM python:3.11 AS builder
ENV PYTHONUNBUFFERED 1
WORKDIR /app
# 安装构建依赖（完整镜像可能已包含部分工具，但显式声明更安全）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    default-libmysqlclient-dev \
    gettext && \
    rm -rf /var/lib/apt/lists/*
# 复制依赖文件并安装（使用 --user 将包安装到用户目录）
COPY requirements.txt .
# 使用中科大pip源提高拉取速度。
RUN pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple && \
    pip install --user --no-cache-dir -r requirements.txt gunicorn[gevent]

# --------------------- 第二阶段：运行时阶段（使用精简镜像） ---------------------
FROM python:3.11-slim
WORKDIR /code/djangoblog/
# 安装运行时系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # 用default-mysql-client替换default-libmysqlclient-dev。
    default-mysql-client \
    gettext && \
    rm -rf /var/lib/apt/lists/*
# 从构建阶段复制已安装的 Python 包。
COPY --from=builder /root/.local /usr/local
# 复制项目代码
COPY . .
# 设置启动脚本权限
RUN chmod +x /code/djangoblog/deploy/entrypoint.sh && \
    rm -f .dockerignore Dockerfile requirements.txt
ENTRYPOINT ["/code/djangoblog/deploy/entrypoint.sh"]
