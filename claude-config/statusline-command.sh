#!/usr/bin/env bash
# Claude Code status line — visual redesign

input=$(cat)

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
DIM=$'\033[2m'
RESET=$'\033[0m'

SEP="${DIM} │ ${RESET}"

# ── Parse data ────────────────────────────────────────────────────────────────
user=$(whoami)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
cwd="${cwd/#$HOME/\~}"

model_id=$(echo "$input" | jq -r '.model.id // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
model="${model#Claude }"  # "Claude Opus 4" → "Opus 4"

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
cache_write=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── Truncate deep paths: …/parent/dir ─────────────────────────────────────────
depth=$(echo "$cwd" | awk -F'/' '{print NF}')
if [ "$depth" -gt 4 ]; then
    last_two=$(echo "$cwd" | rev | cut -d'/' -f1-2 | rev)
    cwd="…/${last_two}"
fi

# ── Session elapsed time ──────────────────────────────────────────────────────
session_file="/tmp/.claude_session_${PPID}"
if [ ! -f "$session_file" ]; then
    date +%s > "$session_file"
fi
start_time=$(cat "$session_file")
now=$(date +%s)
elapsed=$(( now - start_time ))

if [ "$elapsed" -ge 86400 ]; then
    time_str="$(( elapsed / 86400 ))d $(( (elapsed % 86400) / 3600 ))h"
elif [ "$elapsed" -ge 3600 ]; then
    time_str="$(( elapsed / 3600 ))h $(( (elapsed % 3600) / 60 ))m"
elif [ "$elapsed" -ge 60 ]; then
    time_str="$(( elapsed / 60 ))m"
else
    time_str="<1m"
fi

# ── Cost estimation ───────────────────────────────────────────────────────────
case "$model_id" in
  *opus-4*|*opus-4-5*|*opus-4-6*)
    price_in="15.00"; price_out="75.00"; price_cw="18.75"; price_cr="1.50" ;;
  *sonnet-4*|*sonnet-4-5*|*sonnet-4-6*)
    price_in="3.00";  price_out="15.00"; price_cw="3.75";  price_cr="0.30" ;;
  *sonnet-3-7*|*3-7*)
    price_in="3.00";  price_out="15.00"; price_cw="3.75";  price_cr="0.30" ;;
  *sonnet-3-5*|*3-5-sonnet*)
    price_in="3.00";  price_out="15.00"; price_cw="3.75";  price_cr="0.30" ;;
  *haiku-4-5*|*haiku-3-5*|*3-5-haiku*)
    price_in="0.80";  price_out="4.00";  price_cw="1.00";  price_cr="0.08" ;;
  *haiku*)
    price_in="0.25";  price_out="1.25";  price_cw="0.30";  price_cr="0.03" ;;
  *)
    price_in="3.00";  price_out="15.00"; price_cw="3.75";  price_cr="0.30" ;;
esac

cost=$(awk -v ti="$total_input" -v to="$total_output" \
           -v cw="$cache_write" -v cr="$cache_read" \
           -v pi="$price_in" -v po="$price_out" \
           -v pcw="$price_cw" -v pcr="$price_cr" \
    'BEGIN {
        cost = (ti * pi + to * po + cw * pcw + cr * pcr) / 1000000
        printf "%.4f", cost
    }')

# ── Assemble parts ────────────────────────────────────────────────────────────
parts=()

# 1. Location: dimmed user + path
parts+=("${DIM}${user}${RESET} ${cwd}")

# 2. Model name
parts+=("${model}")

# 3. Context bar (color-coded)
if [ -n "$used" ]; then
    used_int=$(printf '%.0f' "$used")
    if [ "$used_int" -ge 80 ]; then
        ctx_color="$RED"
    elif [ "$used_int" -ge 50 ]; then
        ctx_color="$YELLOW"
    else
        ctx_color="$GREEN"
    fi
    bar_width=15
    filled=$(( used_int * bar_width / 100 ))
    empty=$(( bar_width - filled ))
    bar_filled=""
    bar_empty=""
    for ((i=0; i<filled; i++)); do bar_filled+="█"; done
    for ((i=0; i<empty; i++)); do bar_empty+="░"; done
    parts+=("${ctx_color}${bar_filled}${RESET}${DIM}${bar_empty}${RESET} ${ctx_color}${used_int}%${RESET}")
fi

# 4. Cost (smart units + color)
if [ "$(awk -v c="$cost" 'BEGIN { print (c > 0.0001) ? "1" : "0" }')" = "1" ]; then
    cost_color="$GREEN"
    if [ "$(awk -v c="$cost" 'BEGIN { print (c >= 50) ? "1" : "0" }')" = "1" ]; then
        cost_color="$RED"
    elif [ "$(awk -v c="$cost" 'BEGIN { print (c >= 10) ? "1" : "0" }')" = "1" ]; then
        cost_color="$YELLOW"
    fi
    if [ "$(awk -v c="$cost" 'BEGIN { print (c < 1) ? "1" : "0" }')" = "1" ]; then
        cost_fmt=$(awk -v c="$cost" 'BEGIN { printf "%.1f", c * 100 }')
        parts+=("${cost_color}${cost_fmt}¢${RESET}")
    else
        cost_fmt=$(awk -v c="$cost" 'BEGIN { printf "%.2f", c }')
        parts+=("${cost_color}\$${cost_fmt}${RESET}")
    fi
fi

# 5. Session time (dimmed — ambient info)
parts+=("${DIM}${time_str}${RESET}")

# 6. Rate limits (if available)
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
    rate_items=""
    if [ -n "$five_pct" ]; then
        five_int=$(printf '%.0f' "$five_pct")
        rate_items="${DIM}5h${RESET}:${five_int}%"
    fi
    if [ -n "$week_pct" ]; then
        week_int=$(printf '%.0f' "$week_pct")
        [ -n "$rate_items" ] && rate_items="${rate_items} "
        rate_items="${rate_items}${DIM}7d${RESET}:${week_int}%"
    fi
    parts+=("${rate_items}")
fi

# ── Join parts with separator ─────────────────────────────────────────────────
result=""
for i in "${!parts[@]}"; do
    [ "$i" -gt 0 ] && result+="${SEP}"
    result+="${parts[$i]}"
done
printf "%s" "$result"
