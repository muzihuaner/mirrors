#!/bin/bash

#===========================================
# tunasync 服务管理菜单
# 支持: 启动、停止、重启、查看状态
#===========================================

# 配置项（根据你的实际路径修改）
MANAGER_CONFIG="/etc/tunasync/manager.toml"
WORKER_CONFIG="/etc/tunasync/worker.toml"
MANAGER_PORT=12345
LOG_DIR="/var/log/tunasync"

# 初始化脚本路径
INIT_MANAGER="/etc/init.d/tunasync-manager"
INIT_WORKER="/etc/init.d/tunasync-worker"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

#-------------------------------------------
# 颜色定义
#-------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

#-------------------------------------------
# 函数：显示横幅
#-------------------------------------------
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════╗"
    echo "║        Tunasync 服务管理工具          ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

#-------------------------------------------
# 函数：显示主菜单
#-------------------------------------------
show_menu() {
    echo -e "${YELLOW}请选择操作：${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}) 启动服务 (Start)"
    echo -e "  ${GREEN}2${NC}) 停止服务 (Stop)"
    echo -e "  ${GREEN}3${NC}) 重启服务 (Restart)"
    echo -e "  ${GREEN}4${NC}) 查看服务状态 (Status)"
    echo -e "  ${GREEN}5${NC}) 查看同步任务列表"
    echo -e "  ${GREEN}6${NC}) 查看 Manager 日志"
    echo -e "  ${GREEN}7${NC}) 查看 Worker 日志"
    echo -e "  ${RED}0${NC}) 退出"
    echo ""
    echo -n "请输入选项 [0-7]: "
}

#-------------------------------------------
# 函数：启动服务
#-------------------------------------------
start_services() {
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  正在启动 tunasync 服务...${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo ""

    # 启动 manager
    if [ -f "$INIT_MANAGER" ]; then
        echo -e "${CYAN}[1/2] 使用 init 脚本启动 Manager...${NC}"
        $INIT_MANAGER start
    else
        echo -e "${CYAN}[1/2] 直接启动 Manager...${NC}"
        nohup tunasync manager --config "$MANAGER_CONFIG" > "$LOG_DIR/manager.log" 2>&1 &
        echo "Manager PID: $!"
    fi

    sleep 1

    # 启动 worker
    if [ -f "$INIT_WORKER" ]; then
        echo -e "${CYAN}[2/2] 使用 init 脚本启动 Worker...${NC}"
        $INIT_WORKER start
    else
        echo -e "${CYAN}[2/2] 直接启动 Worker...${NC}"
        nohup tunasync worker --config "$WORKER_CONFIG" > "$LOG_DIR/worker.log" 2>&1 &
        echo "Worker PID: $!"
    fi

    echo ""
    echo -e "${GREEN}✓ 启动完成${NC}"
    sleep 1
    press_any_key
}

#-------------------------------------------
# 函数：停止服务
#-------------------------------------------
stop_services() {
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  正在停止 tunasync 服务...${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo ""

    # 停止 worker
    echo -e "${CYAN}[1/2] 停止 Worker...${NC}"
    if [ -f "$INIT_WORKER" ]; then
        $INIT_WORKER stop
    else
        pkill -f "tunasync worker" && echo "Worker 已停止" || echo "Worker 未在运行"
    fi

    sleep 1

    # 停止 manager
    echo -e "${CYAN}[2/2] 停止 Manager...${NC}"
    if [ -f "$INIT_MANAGER" ]; then
        $INIT_MANAGER stop
    else
        pkill -f "tunasync manager" && echo "Manager 已停止" || echo "Manager 未在运行"
    fi

    echo ""
    echo -e "${GREEN}✓ 服务已停止${NC}"
    press_any_key
}

#-------------------------------------------
# 函数：重启服务
#-------------------------------------------
restart_services() {
    stop_services
    sleep 2
    start_services
}

#-------------------------------------------
# 函数：查看服务状态
#-------------------------------------------
check_status() {
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  tunasync 服务进程状态${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo ""

    # 检查 Manager 进程
    if pgrep -f "tunasync manager" > /dev/null; then
        MANAGER_PID=$(pgrep -f "tunasync manager" | head -1)
        echo -e "  Manager:  ${GREEN}● 运行中${NC}  (PID: $MANAGER_PID)"
    else
        echo -e "  Manager:  ${RED}● 未运行${NC}"
    fi

    # 检查 Worker 进程
    if pgrep -f "tunasync worker" > /dev/null; then
        WORKER_PID=$(pgrep -f "tunasync worker" | head -1)
        echo -e "  Worker:   ${GREEN}● 运行中${NC}  (PID: $WORKER_PID)"
    else
        echo -e "  Worker:   ${RED}● 未运行${NC}"
    fi

    echo ""
    press_any_key
}

#-------------------------------------------
# 函数：查看同步任务列表
#-------------------------------------------
list_tasks() {
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  镜像同步任务列表${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo ""

    if command -v tunasynctl &> /dev/null; then
        tunasynctl list -p "$MANAGER_PORT" --all
    else
        echo -e "${RED}错误: tunasynctl 命令未找到${NC}"
        echo "请确认 tunasync 已正确安装"
    fi

    echo ""
    press_any_key
}

#-------------------------------------------
# 函数：查看 Manager 日志
#-------------------------------------------
view_manager_log() {
    if [ -f "$LOG_DIR/manager.log" ]; then
        echo -e "${YELLOW}════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  Manager 日志 (最后50行)${NC}"
        echo -e "${YELLOW}════════════════════════════════════════${NC}"
        echo ""
        tail -n 50 "$LOG_DIR/manager.log"
    else
        echo -e "${RED}日志文件不存在: $LOG_DIR/manager.log${NC}"
    fi
    echo ""
    press_any_key
}

#-------------------------------------------
# 函数：查看 Worker 日志
#-------------------------------------------
view_worker_log() {
    if [ -f "$LOG_DIR/worker.log" ]; then
        echo -e "${YELLOW}════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  Worker 日志 (最后50行)${NC}"
        echo -e "${YELLOW}════════════════════════════════════════${NC}"
        echo ""
        tail -n 50 "$LOG_DIR/worker.log"
    else
        echo -e "${RED}日志文件不存在: $LOG_DIR/worker.log${NC}"
    fi
    echo ""
    press_any_key
}

#-------------------------------------------
# 辅助函数：按任意键继续
#-------------------------------------------
press_any_key() {
    echo -e "${BLUE}按 Enter 键返回菜单...${NC}"
    read -r
}

#-------------------------------------------
# 主循环
#-------------------------------------------
while true; do
    show_banner
    show_menu
    read -r choice

    case $choice in
        1)
            start_services
            ;;
        2)
            stop_services
            ;;
        3)
            restart_services
            ;;
        4)
            check_status
            ;;
        5)
            list_tasks
            ;;
        6)
            view_manager_log
            ;;
        7)
            view_worker_log
            ;;
        0)
            echo ""
            echo -e "${GREEN}感谢使用，再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新选择${NC}"
            sleep 1
            ;;
    esac
done
