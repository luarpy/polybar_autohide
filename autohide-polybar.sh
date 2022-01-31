#! /usr/bin/env bash

### VARIABLES ###
PID=
MARGIN_TOP=5
MARGIN_HIDE_TOP=50
DEBUG=1
INTERVAL=1
top=0
bottom=5
left=5
right=5

VERSION='0.1'

usage(){
cat << EOF
Usage: autohide-polybar [action] [-p <PID>]

Options:
  -h, --help show this message
  -p, --pid=  bars PID. Used to identify which bar must be used
  -a, --paddings= screen margins. <top>,<right>,<bottom>,<left>. Defaults are $top, $right, $bottom, $left
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

getScreenSize(){
  xrandr -q | grep 'current' | cut -d ',' -f2 | tr -d 'current\| ' 2>&2
}

getWindow(){
  local window="$(xdotool getactivewindow)" # window ID
  window="$(xdotool getwindowgeometry --shell "$window")"
  local x y screenwidth screenheight screensize
  screensize="$(getScreenSize)"
  screenwidth="$(printf "$screensize" | cut -d 'x' -f1)"
  screenheight="$(printf "$screensize" | cut -d 'x' -f2)"
  width="$(printf "$window" | grep 'WIDTH=' | tr -d 'WIDTH=')"
  height="$(printf "$window" | grep 'HEIGHT=' | tr -d 'HEIGHT=')"
  
  if [ "$DEBUG" -eq 0 ]; then
    printf %s\\n "Screen Size: $screenwidth x $screenheight" \
      "Window Geometry: $width x $height" >&2
  fi

  if [ "$width" -ge "$screenwidth" ] && [ "$height" -ge "$screenheight" ]; then
    printf 2
  else
    printf 0
  fi
}

windowPresence(){
  # FIXME: encontrar una manera mejor de devolver la presencia de ventanas o no. De manera ideal debería devolver la presencia de ventanas (0) para los casos en los que hay una ventana en Maximize mode o Full Screen Mode. 
  local windownumber="$(getWindow)"
  if [ $DEBUG -eq 0 ]; then
    printf %s\\n "window state: $windownumber" >&2
  fi
  [ -z "$windownumber" ] && printf 1 || printf "$windownumber"
}

main(){
  local pointer windownumber polybarshown
  polybarshown=0
  show
  while :; do
    # Get initial values
    pointer="$(getPointer)" 
    windowpresence="$(windowPresence)"

    if [ $DEBUG -eq 0 ]; then
      printf %s\\n "pointer Y position: $pointer" \
        ", windowPresent: $windowpresence" \
        ", polybarShown: $polybarshown" \
        ", PID: $PID"
    fi
    
    # If no windows, then show polybar
    if [ $windowpresence -eq 1 ]; then
        polybarshown=0
        show
    elif [ $windowpresence -eq 0 ]; then
        pointer="$(getPointer)"
        if [ $pointer -gt $MARGIN_HIDE_TOP ]; then # if mouse is under bar's area
          # Check if window size is lower than widnowsize+margin
          # FIXME: make this more efficient. Must not need theses amount of variables
          local window="$(xdotool getactivewindow)" # window ID
          window="$(xdotool getwindowgeometry --shell "$window")"
          local x y screenwidth screenheight screensize
          screensize="$(getScreenSize)"
          screenwidth="$(printf "$screensize" | cut -d 'x' -f1)"
          screenheight="$(printf "$screensize" | cut -d 'x' -f2)"
          width="$(printf "$window" | grep 'WIDTH=' | tr -d 'WIDTH=')"
          height="$(printf "$window" | grep 'HEIGHT=' | tr -d 'HEIGHT=')"
          if [ $height -lt $(($screenheight - $bottom - $top)) ] && [ $width -lt $(($screenwidth - $left - $right)) ] ; then
            poybarshow=0
            show
          else
            polybarshown=1
            hide
          fi
        elif [ $pointer -lt $MARGIN_TOP ]; then # if mouse is over bar's area
          polybarshown=0
          show
        fi
    elif [ $windowpresence -eq 2 ]; then
      polybarshown=1
      hide
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
    --margin-top=)
      shift
      MARGIN_TOP="$1"
      ;;
    --margin-top-hide)
      shift
      MARGIN_HIDE_TOP="$1"
      ;;
    -a|--paddings=)
      shift 
      top="$(printf "$1" | cut -d ',' -f1)"
      right="$(printf "$1" | cut -d ',' -f2)"
      bottom="$(printf "$1" | cut -d ',' -f3)"
      left="$(printf "$1" | cut -d ',' -f4)"
      ;;
  esac
done

main "$params"
