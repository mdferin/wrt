#!/bin/bash
set -e

script_path="$(realpath "$0")"

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'
BLUE='\033[34m'; MAGENTA='\033[35m'
BOLD_RED="${BOLD}${RED}"
BOLD_GREEN="${BOLD}${GREEN}"
BOLD_YELLOW="${BOLD}${YELLOW}"
BOLD_BLUE="${BOLD}${BLUE}"
BOLD_MAGENTA="${BOLD}${MAGENTA}"

main_menu() {
    clear
    echo -e "${BOLD_MAGENTA}##############################################${RESET}"
    echo -e "${BOLD_MAGENTA}                   AW1000                     ${RESET}"
    echo -e "${BOLD_MAGENTA}                                              ${RESET}"
    echo -e "${BOLD_MAGENTA}##############################################${RESET}"
    echo -e "${BOLD_BLUE}DISTRO: IMMORTALWRT${RESET}"
    echo -e "${BOLD_BLUE}BUILD MENU:${RESET}"

    distro="immortalwrt"
    repo="https://github.com/immortalwrt/immortalwrt.git"
    preset_repo="https://github.com/mdferin/wrt.git"
    preset_folder="wrt"

    if [ ! -d "$distro" ]; then
        echo -e "${BOLD_YELLOW}CLONING REPO: $repo INTO $distro${RESET}"
        git clone "$repo" "$distro" || {
            echo -e "${BOLD_RED}GIT CLONE FAILED. EXITING${RESET}"
            exit 1
        }
        echo -e "${BOLD_GREEN}REPO CLONED SUCCESSFULLY${RESET}"
        just_cloned=1
    else
        echo -e "${BOLD_GREEN}DIRECTORY '$distro' ALREADY EXISTS. SKIPPING CLONE${RESET}"
        just_cloned=0
    fi
}

update_feeds() {
    echo -e "${BOLD_YELLOW}UPDATING FEEDS${RESET}"
    ./scripts/feeds update -a && ./scripts/feeds install -a || {
        echo -e "${BOLD_RED}ERROR: FEEDS UPDATE FAILED${RESET}"
        return 1
    }

    read -rp "${BOLD_BLUE}EDIT FEEDS IF NEEDED, THEN PRESS ENTER TO CONTINUE: ${RESET}"
    ./scripts/feeds update -a && ./scripts/feeds install -a || {
        echo -e "${BOLD_RED}ERROR: FEEDS INSTALL FAILED AFTER EDIT${RESET}"
        return 1
    }

    echo -e "${BOLD_GREEN}FEEDS UPDATED SUCCESSFULLY${RESET}"
}

select_target() {
    echo -e "${BOLD_BLUE}AVAILABLE BRANCHES:${RESET}"
    git branch -a
    echo -e "${BOLD_BLUE}AVAILABLE TAGS:${RESET}"
    git tag | sort -V

    while true; do
        read -rp "${BOLD_BLUE}ENTER BRANCH OR TAG TO CHECKOUT: ${RESET}" target_tag
        if git checkout "$target_tag" &>/dev/null; then
            echo -e "${BOLD_GREEN}CHECKED OUT TO ${target_tag}${RESET}"
            break
        else
            echo -e "${BOLD_RED}INVALID BRANCH OR TAG: ${target_tag}${RESET}"
        fi
    done
}

apply_preset() {
    echo -e "${BOLD_YELLOW}CLEANING OLD PRESET AND CONFIG${RESET}"
    rm -rf ./files .config "$preset_folder"

    echo -e "${BOLD_YELLOW}CLONING PRESET FROM $preset_repo${RESET}"
    if git clone "$preset_repo" "$preset_folder"; then
        echo -e "${BOLD_GREEN}PRESET CLONED${RESET}"
        cp -r "$preset_folder/files" ./ 2>/dev/null && \
            echo -e "${BOLD_GREEN}FILES COPIED${RESET}" || \
            echo -e "${BOLD_RED}FILES NOT FOUND OR FAILED TO COPY${RESET}"
        cp "$preset_folder/preset" .config 2>/dev/null && \
            echo -e "${BOLD_GREEN}PRESET APPLIED${RESET}" || \
            echo -e "${BOLD_RED}WARNING: PRESET NOT FOUND${RESET}"
    else
        echo -e "${BOLD_RED}FAILED TO CLONE PRESET${RESET}"
        exit 1
    fi
}

run_menuconfig() {
    echo -e "${BOLD_YELLOW}RUNNING MENUCONFIG${RESET}"
    make menuconfig
    echo -e "${BOLD_GREEN}CONFIGURATION SAVED${RESET}"
}

get_version() {
    version_tag=$(git describe --tags --exact-match 2>/dev/null || echo "")
    version_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
}

start_build() {
    get_version
    while true; do
        echo -e "${BOLD_YELLOW}STARTING BUILD WITH $(nproc) CORES${RESET}"
        start=$(date +%s)

        if make -j"$(nproc)"; then
            dur=$(( $(date +%s) - start ))
            echo -e "${BOLD_YELLOW}BUILD VERSION: ${version_branch}${version_tag}${RESET}"
            echo -e "${BOLD_BLUE}OUTPUT DIRECTORY: $(pwd)/bin/targets/${RESET}"
            printf "${BOLD_GREEN}BUILD COMPLETED IN %02dh %02dm %02ds${RESET}\n" \
                $((dur / 3600)) $(((dur % 3600) / 60)) $((dur % 60))
            rm -rf "$preset_folder"; rm -f -- "$script_path"
            exit 0
        else
            echo -e "${BOLD_RED}BUILD FAILED. RETRYING WITH VERBOSE OUTPUT${RESET}"
            make -j1 V=s
            read -rp "${BOLD_RED}PLEASE FIX ERRORS AND PRESS ENTER TO RETRY: ${RESET}"
            make distclean
            update_feeds || return 1
            select_target
            apply_preset
            run_menuconfig
        fi
    done
}

build_menu() {
    cd "$distro" || exit 1
    update_feeds || exit 1
    select_target
    apply_preset
    make defconfig
    run_menuconfig
    start_build
}

rebuild_menu() {
    clear
    echo -e "${BOLD_MAGENTA}##############################################${RESET}"
    echo -e "${BOLD_MAGENTA}                    AW1000                    ${RESET}"
    echo -e "${BOLD_MAGENTA}                                              ${RESET}"
    echo -e "${BOLD_MAGENTA}##############################################${RESET}"
    echo -e "${BOLD_BLUE}REBUILD MENU:${RESET}"
    echo -e "1) FIRMWARE & PACKAGE UPDATE (FULL REBUILD)"
    echo -e "2) FIRMWARE UPDATE (FAST REBUILD)"
    echo -e "3) CONFIG UPDATE (FAST REBUILD)"
    echo -e "4) EXISTING UPDATE (NO CHANGES)"

    while true; do
        read -rp "${BOLD_BLUE}CHOOSE OPTION: ${RESET}" opt
        case "$opt" in
            1)
                echo -e "${BOLD_YELLOW}REMOVING EXISTING BUILD DIRECTORY: $distro${RESET}"
                rm -rf "$distro"
                git clone "$repo" "$distro" || {
                    echo -e "${BOLD_RED}ERROR: GIT CLONE FAILED${RESET}"
                    exit 1
                }
                cd "$distro" || exit 1
                update_feeds || exit 1
                select_target
                apply_preset
                make defconfig
                run_menuconfig
                start_build
                ;;
            2)
                cd "$distro" || exit 1
                make clean
                select_target
                apply_preset
                make defconfig
                start_build
                ;;
            3)
                cd "$distro" || exit 1
                rm -f .config
                apply_preset
                make defconfig
                run_menuconfig
                start_build
                ;;
            4)
                cd "$distro" || exit 1
                start_build
                ;;
            *)
                echo -e "${BOLD_RED}INVALID CHOICE${RESET}"
                ;;
        esac
    done
}

main_menu
if [ "$just_cloned" = "1" ]; then
    build_menu
else
    rebuild_menu
fi
