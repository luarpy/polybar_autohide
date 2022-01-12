#! /usr/bin/env bash

### VARIABLES ###
PID=
MARGIN_TOP=5
MARGIN_HIDE_TOP=50
DEBUG=1
CURSOR_WINDOW_DELAY=1
INTERVAL=1

VERSION='0.1'

usage(){
cat << EOF
Usage: autohide-polybar [action] [-p <PID>]

Options:
  -h, --help show this message
  -p, --pid  bars PID. Used to identify which bar must be used
EOF
}

version(){
printf %s\\n "Version: $VERSION"
}

getPointer(){
  local pointer="$(xdotool getmouselocation --shell | grep 'Y=' | tr -d 'Y=')"
  printf "$pointer"
}

hide(){
  polybar-msg cmd hide "$([ -n $PID ] && printf -- "-p $PID")"
}

show(){
  polybar-msg cmd show "$([ -n $PID ] && printf -- "-p $PID")"
}

toggle(){
  polybar-msg cmd toggle "$([ -n $PID ] && printf -- "-p $PID")"
}

windowPresence(){
  local windownumber="$(xdotool getactivewindow)"
  if [ $DEBUG -eq 0 ]; then
    printf %s\\n "$? window number: $windownumber" >&2
  fi
  # FIXME: arreglar esto. No devuelve bien cuantas ventanas hay. Si no hubiese ventanas sería vacía la respuesta 
  [ -z "$windownumber" ] && printf 1 || printf 0
}

main(){
  local pointer windownumber polybarshown
  polybarshown=0
  show
  while :; do
    pointer="$(getPointer)" 
    windowpresence="$(windowPresence)"

    if [ $DEBUG -eq 0 ]; then
      printf %s\\n "pointer Y position: $pointer" \
        ", windowPresent: $windowpresence" \
        ", polybarShown: $polybarshown" \
        ", PID: $PID"
    fi

    # If no windows, then show polybar
    if [ "$windowpresence" -eq 1 ]; then
      if [ "$polybarshown" -eq 1 ]; then
        windowpresence="$(windowPresence)"
        
        if [ "$windowpresence" -eq 1 ]; then
          polybarshown=0
          show
        fi
      fi
    elif [ $polybarshown -eq 1 ]; then
      # If there is a window and polybar is hidden we want to unhide it if mouse is at the top
      if [ $pointer -lt $MARGIN_TOP ]; then
#        sleep $CURSOR_WINDOW_DELAY
        pointer="$(getPointer)"
        if [ $pointer -lt $MARGIN_TOP ]; then
          polybarshown=0
          show
        fi
      fi
    else
      # else there is a window an polybar is shown, we want to hide it if mouse moves away
      if [ $pointer -gt $MARGIN_HIDE_TOP ]; then
        echo hola
        polybarshown=1
        hide
      fi

    fi

    sleep $INTERVAL
  done
  
}

params="$@"

while [ "$#" -gt 0 ]; do
  param="$1"
  shift
  case "$param" in
    -h|--help)
      usage
      exit 0
      ;;
    -v|--version)
      version
      exit 0
      ;;
    -d|--debug)
      DEBUG=0
      ;;
    -p|--pid)
      shift
      param="$1"
      PID="$param"
      ;;
  esac
done

main "$params"
