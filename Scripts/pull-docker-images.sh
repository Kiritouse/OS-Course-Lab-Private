#!/usr/bin/env bash
# ============================================================
# Docker 镜像拉取辅助脚本 — 使用国内镜像源
# 适用于 OS-Course-Lab 项目
# ============================================================
set -e

# 颜色定义
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NONE='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NONE} $*"; }
warn()  { echo -e "${RED}[WARN]${NONE} $*"; }

# 国内 Docker Hub 镜像源列表（按优先级排列）
MIRRORS=(
    "docker.m.daocloud.io"
    "docker.1panel.dev"
    "dockerpull.org"
    "hub.rat.dev"
)

# 需要拉取的镜像（标准标签=镜像源标签）
IMAGES=(
    "ipads/oslab:25.03"
    "ipads/oslab:25.03-arm64"
)

pull_image() {
    local image="$1"    # e.g., ipads/oslab:25.03
    local pulled=false

    # 先检查本地是否已有该镜像
    if docker image inspect "$image" &>/dev/null; then
        info "镜像已存在: $image，跳过"
        return 0
    fi

    # 尝试从各个镜像源拉取
    for mirror in "${MIRRORS[@]}"; do
        local mirror_image="${mirror}/${image}"
        echo -n "尝试从 $mirror 拉取 $image ... "
        if docker pull "$mirror_image" 2>/dev/null; then
            # 重新打标签
            docker tag "$mirror_image" "$image"
            docker rmi "$mirror_image" 2>/dev/null || true
            info "成功: $image (via $mirror)"
            pulled=true
            break
        else
            echo "失败，尝试下一个..."
        fi
    done

    if [ "$pulled" = false ]; then
        # 最后尝试直接拉取（通过代理）
        echo -n "尝试从 Docker Hub 直接拉取 $image ... "
        if docker pull "$image" 2>/dev/null; then
            info "成功: $image (直连)"
            pulled=true
        else
            warn "所有镜像源均失败: $image"
            return 1
        fi
    fi
}

main() {
    echo -e "${BOLD}============================================${NONE}"
    echo -e "${BOLD}  OS-Course-Lab Docker 镜像拉取工具${NONE}"
    echo -e "${BOLD}============================================${NONE}"
    echo ""

    # 检查 docker 命令是否可用
    if ! command -v docker &>/dev/null; then
        warn "docker 命令不可用，请确认 Docker 已安装且你有权限访问"
        exit 1
    fi

    # 检查是否能连接 Docker daemon
    if ! docker info &>/dev/null; then
        warn "无法连接 Docker daemon！"
        echo ""
        echo "你可能没有 Docker 使用权限。请检查："
        echo "  1. 是否在 docker 组中: groups"
        echo "  2. 如果没有，请联系管理员运行: sudo usermod -aG docker wuchang"
        echo "  3. 重新登录后生效"
        exit 1
    fi

    local failed_count=0
    for img in "${IMAGES[@]}"; do
        if ! pull_image "$img"; then
            ((failed_count++))
        fi
        echo ""
    done

    echo -e "${BOLD}============================================${NONE}"
    if [ $failed_count -eq 0 ]; then
        info "所有镜像拉取完成！"
    else
        warn "$failed_count 个镜像拉取失败"
    fi

    # 显示已有镜像
    echo ""
    echo "本地 Docker 镜像:"
    docker images | grep -E 'ipados/oslab|ipads/oslab' || echo "  (未找到 ipads/oslab 镜像)"
}

main "$@"
