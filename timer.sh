#!/bin/bash

TIMER_FILE="$HOME/.config/waybar/timer"
MAX_MINUTES=60

# Function to format time
format_time() {
    local total_seconds=$1
    printf "%02d:%02d" $((total_seconds / 60)) $((total_seconds % 60))
}

# Initialize timer if file doesn't exist
if [ ! -f "$TIMER_FILE" ]; then
    echo "600,0,600,0,0,timer" > "$TIMER_FILE"  # Default: 10 minutes
fi

# Read current state
IFS=',' read -r duration running reset_value stopwatch stopwatch_running mode < "$TIMER_FILE"

case $1 in
    click)
        if [ "$mode" = "timer" ]; then
            running=$((1 - running))
            [ "$running" -eq 1 ] && reset_value=$duration
        else
            stopwatch_running=$((1 - stopwatch_running))
        fi
        ;;
    rightclick)
        if [ "$mode" = "timer" ]; then
            duration=$reset_value
            running=0
        else
            stopwatch=0
            stopwatch_running=0
        fi
        ;;
    middleclick)
        if [ "$mode" = "timer" ]; then
            mode="stopwatch"
            running=0
        else
            mode="timer"
            stopwatch_running=0
        fi
        ;;
    up)
        if [ "$mode" = "timer" ]; then
            duration=$(( (duration / 60 + 1) * 60 ))
            [ $duration -gt $((MAX_MINUTES * 60)) ] && duration=$((MAX_MINUTES * 60))
        fi
        ;;
    down)
        if [ "$mode" = "timer" ]; then
            duration=$(( (duration / 60 - 1) * 60 ))
            [ $duration -lt 60 ] && duration=60
        fi
        ;;
    *)
        if [ "$mode" = "timer" ] && [ "$running" -eq 1 ]; then
            duration=$((duration - 1))
            if [ $duration -le 0 ]; then
                running=0
                duration=0
                notify-send "Timer Finished" "Your timer has reached zero!"
            fi
        elif [ "$mode" = "stopwatch" ] && [ "$stopwatch_running" -eq 1 ]; then
            stopwatch=$((stopwatch + 1))
        fi
        ;;
esac

# Save new state
echo "$duration,$running,$reset_value,$stopwatch,$stopwatch_running,$mode" > "$TIMER_FILE"

# Format output for waybar
if [ "$mode" = "timer" ]; then
    formatted_time=$(format_time "$duration")
    [ "$running" -eq 1 ] && class="timer-running" || class="timer-stopped"
    icon="🕒"
else
    formatted_time=$(format_time "$stopwatch")
    [ "$stopwatch_running" -eq 1 ] && class="stopwatch-running" || class="stopwatch-stopped"
    icon="⏱️"  # Stopwatch icon
fi

# Output JSON for waybar
echo "{\"text\":\"$icon $formatted_time\", \"class\":\"$class\"}"
