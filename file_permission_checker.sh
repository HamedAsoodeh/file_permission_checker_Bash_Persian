#!/bin/bash

# ==================== CONFIGURATION ====================
SEARCH_DIR="."
OUTPUT_FILE="permission_report_$(date '+%Y%m%d_%H%M%S').txt"
# ======================================================

# Colors for better display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
WHITE='\033[0m'

# Function to show help
show_help() {
    echo -e "${GREEN}📋 راهنما: $0 [مسیر دایرکتوری]${WHITE}"
    echo -e "${BLUE}نمونه استفاده:${WHITE}"
    echo -e "  $0           # دایرکتوری جاری"
    echo -e "  $0 /home     # دایرکتوری مشخص"
    echo -e "  $0 ~/documents"
    echo -e ""
    echo -e "${YELLOW}📊 گزارش در فایل ذخیره می‌شود: $OUTPUT_FILE${WHITE}"
}

# Function to display main menu
show_menu() {
    clear
    echo -e "${PURPLE}=============================================="
    echo -e "🛠️  منوی مدیریت مجوزهای فایل‌ها"
    echo -e "==============================================${WHITE}"
    echo -e "${GREEN}1. 📂 لیست تمام فایل‌ها با مجوزها"
    echo -e "2. 🚀 لیست فایل‌های قابل اجرا"
    echo -e "3. ✍️  لیست فایل‌های قابل نوشتن"  
    echo -e "4. 👀 لیست فایل‌های فقط خواندنی"
    echo -e "5. 🔍 جستجوی فایل‌های با مجوز خاص"
    echo -e "6. 📊 نمایش آمار کلی"
    echo -e "7. ⚙️  تغییر دایرکتوری جستجو"
    echo -e "8. 📖 نمایش راهنما"
    echo -e "9. 🚪 خروج${WHITE}"
    echo -e "${PURPLE}==============================================${WHITE}"
}

# Function to get user input
get_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Function to check directory existence
check_directory() {
    if [ ! -d "$SEARCH_DIR" ]; then
        echo -e "${RED}❌ خطا: دایرکتوری '$SEARCH_DIR' وجود ندارد${WHITE}" >&2
        return 1
    fi
    return 0
}

# Function to convert permissions to Persian text
convert_permission_to_persian() {
    local perm="$1"
    local text=""
    
    if [[ $perm == *"r"* ]]; then
        text+="${GREEN}خواندن${WHITE}"
    else
        text+="${RED}بدون خواندن${WHITE}"
    fi
    
    if [[ $perm == *"w"* ]]; then
        text+="${YELLOW}نوشتن${WHITE}"
    else
        text+="${RED}بدون نوشتن${WHITE}"
    fi
    
    if [[ $perm == *"x"* ]]; then
        text+="${BLUE}اجرا${WHITE}"
    else
        text+="${RED}بدون اجرا${WHITE}"
    fi
    
    echo "$text"
}

# Function to list files based on type
list_files() {
    local type="$1"
    local command="$2"
    
    echo -e "\n${YELLOW}🔍 در حال جستجوی $type در: $SEARCH_DIR${WHITE}"
    echo -e "${BLUE}⏰ زمان شروع: $(date)${WHITE}"
    echo "========================================"
    
    local count=0
    while IFS= read -r -d '' file; do
        [ -e "$file" ] || continue
        
        local perm=$(stat -c "%A" "$file")
        local owner=$(stat -c "%U" "$file")
        local size=$(stat -c "%s" "$file")
        local human_size=$(numfmt --to=iec $size 2>/dev/null || echo $size)
        
        echo -e "📄 فایل: ${BLUE}$(basename "$file")${WHITE}"
        echo -e "📁 مسیر: $file"
        echo -e "👤 مالک: $owner"
        echo -e "📏 اندازه: $human_size"
        echo -e "🔐 مجوز: $perm"
        echo -e "🎯 دسترسی: $(convert_permission_to_persian "$perm")"
        echo "----------------------------------------"
        
        ((count++))
    done < <(eval "$command" 2>/dev/null)
    
    echo -e "${GREEN}✅ تعداد $type: $count ${WHITE}"
}

# Different listing functions
list_all_files() {
    list_files "تمام فایل‌ها" "find \"$SEARCH_DIR\" -type f -not -path '*/\.*' -print0"
}

list_executable_files() {
    list_files "فایل‌های قابل اجرا" "find \"$SEARCH_DIR\" -type f -executable -not -path '*/\.*' -print0"
}

list_writable_files() {
    list_files "فایل‌های قابل نوشتن" "find \"$SEARCH_DIR\" -type f -writable -not -path '*/\.*' -print0"
}

list_readonly_files() {
    list_files "فایل‌های فقط خواندنی" "find \"$SEARCH_DIR\" -type f -readable ! -writable -not -path '*/\.*' -print0"
}

# Function for advanced search
search_specific_permission() {
    echo -e "${YELLOW}🔍 جستجوی بر اساس مجوز خاص${WHITE}"
    echo -e "${BLUE}نمونه‌ها: ${WHITE}"
    echo -e "  - rwx : خواندن، نوشتن، اجرا"
    echo -e "  - rw- : خواندن و نوشتن"
    echo -e "  - r-- : فقط خواندن"
    echo -e "  - --x : فقط اجرا"
    
    local pattern=$(get_input "الگوی مجوز را وارد کنید" "rwx")
    
    list_files "فایل‌های با الگوی $pattern" "find \"$SEARCH_DIR\" -type f -perm -u=${pattern} -not -path '*/\.*' -print0"
}

# Function to show statistics
show_statistics() {
    echo -e "${PURPLE}📊 آمار کلی دایرکتوری: $SEARCH_DIR${WHITE}"
    echo "========================================"
    
    local total_files=$(find "$SEARCH_DIR" -type f -not -path '*/\.*' | wc -l)
    local executable_files=$(find "$SEARCH_DIR" -type f -executable -not -path '*/\.*' | wc -l)
    local writable_files=$(find "$SEARCH_DIR" -type f -writable -not -path '*/\.*' | wc -l)
    local readonly_files=$(find "$SEARCH_DIR" -type f -readable ! -writable -not -path '*/\.*' | wc -l)
    
    echo -e "📂 کل فایل‌ها: $total_files"
    echo -e "🚀 قابل اجرا: $executable_files"
    echo -e "✍️ قابل نوشتن: $writable_files"
    echo -e "👀 فقط خواندنی: $readonly_files"
    echo -e "📅 آخرین بروزرسانی: $(date)"
}

# Function to change directory
change_directory() {
    local new_path=$(get_input "مسیر دایرکتوری جدید را وارد کنید" "$SEARCH_DIR")
    
    if [ -d "$new_path" ]; then
        SEARCH_DIR="$new_path"
        echo -e "${GREEN}✅ دایرکتوری تغییر کرد به: $SEARCH_DIR${WHITE}"
    else
        echo -e "${RED}❌ دایرکتوری وجود ندارد: $new_path${WHITE}"
    fi
}

# Main function
main() {
    # Check command line arguments
    if [ $# -gt 0 ]; then
        if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
            show_help
            exit 0
        elif [ -d "$1" ]; then
            SEARCH_DIR="$1"
        else
            echo -e "${RED}❌ خطا: '$1' یک دایرکتوری معتبر نیست${WHITE}"
            show_help
            exit 1
        fi
    fi
    
    # Check directory
    if ! check_directory; then
        exit 1
    fi
    
    # Main menu loop
    while true; do
        show_menu
        local choice=$(get_input "لطفاً عدد مورد نظر را انتخاب کنید" "1")
        
        case $choice in
            1)
                list_all_files | tee -a "$OUTPUT_FILE"
                ;;
            2)
                list_executable_files | tee -a "$OUTPUT_FILE"
                ;;
            3)
                list_writable_files | tee -a "$OUTPUT_FILE"
                ;;
            4)
                list_readonly_files | tee -a "$OUTPUT_FILE"
                ;;
            5)
                search_specific_permission | tee -a "$OUTPUT_FILE"
                ;;
            6)
                show_statistics | tee -a "$OUTPUT_FILE"
                ;;
            7)
                change_directory
                ;;
            8)
                show_help
                ;;
            9)
                echo -e "${GREEN}👋 با تشکر از استفاده شما!${WHITE}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ انتخاب نامعتبر! لطفاً عدد بین 1-9 وارد کنید.${WHITE}"
                ;;
        esac
        
        read -p "⏎ برای ادامه Enter بزنید..."
    done
}

# Error handling
trap 'echo -e "${RED}❌ اسکریپت متوقف شد${WHITE}"; exit 1' SIGINT

# Main execution
main "$@"
