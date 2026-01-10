FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装工具链
# 更新点：在列表中加入了 python3-pip 和 python3-pexpect
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    gdb-multiarch \
    qemu-system-aarch64 \
    cmake \
    git \
    python3 \
    python3-pip \
    python3-pexpect \
    sudo \
    vim \
    curl \
    unzip \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

ARG USERNAME=stu
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# 2. 创建用户组和用户
# 保持了之前修复的 /bin/bash 设置
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 3. 预先创建工作目录并赋权
RUN mkdir -p /workspace/OS-Course-Lab \
    && chown -R $USERNAME:$USER_GID /workspace/OS-Course-Lab

# 4. 强制开启彩色提示符 (修改 .bashrc)
RUN echo "force_color_prompt=yes" >> /home/$USERNAME/.bashrc \
    && echo "if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi" >> /home/$USERNAME/.bashrc \
    && echo "export TERM=xterm-256color" >> /home/$USERNAME/.bashrc

# 5. 切换用户
USER $USERNAME

# 6. 设置工作目录
WORKDIR /workspace/OS-Course-Lab

CMD ["/bin/bash"]