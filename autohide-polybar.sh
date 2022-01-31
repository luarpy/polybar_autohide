#! /usr/bin/env bash

### VARIABLES ###
PID=
MARGIN_TOP=5
MARGIN_HIDE_TOP=50
DEBUG=1
INTERVAL=1
x=0
y=0
height=50
width=1366
margin=5

VERSION='0.1'

usage(){
cat << EOF
Usage: autohide-polybar [action] [-p <PID>]

Options:
  -h, --help show this message
  -p, --pid=  bars PID. Used to identify which bar must be used
  -a, --paddings= screen margins. <x>x<y>+<height>+<width>. Defaults are $x x $y + $height + $width
EOF
}

version(){
  printf %s\\n "Version: $VERSION"
}

getPointerY(){
  local pointer="$(xdotool getmouselocation --shell | grep 'Y=' | tr -d 'Y=')"
  printf "$pointer"
}

getPointerX(){
  local pointer="$(xdotool getmouselocation --shell | grep 'X=' | tr -d 'X=')"
  printf "$pointer"
}

hide(){
  polybar-msg cmd hide "$([ -n $PID ] && printf -- "-p $PID")"  > /dev/null
  polybarshown=1
}

show(){
  polybar-msg cmd show "$([ -n $PID ] && printf -- "-p $PID")" > /dev/null
  polybarshown=0
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


  if [[ $width -lt $(($screenwidth - 10)) && $height -lt $(($screenheight - 5)) ]]; then
    printf 1
  elif [[ $width -lt $screenwidth && $height -lt $screenheight ]]; then
    printf 0
  else
    printf 2
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
  local pointerY pointerX windownumber polybarshown
  while true; do
    # Get initial values
    pointerY="$(getPointerY)" 
    pointerX="$(getPointerX)"
    windowpresence="$(windowPresence)"

    if [ $DEBUG -eq 0 ]; then
      printf %s\\n "(x,y) pointer position: ($pointerX,$pointerY)" \
        "windowPresent: $windowpresence" \
        "polybarShown: $polybarshown" \
        "PID: $PID"
    fi
    case "$windowpresence" in
      # Window presence true
      0)
        # The pointer must be between the four points of the bar
        if [[ $pointerX -ge $x  && \
          $pointerY -ge $y  && \
          $pointerX -lt $(($x + $width)) && \
          $pointerY -lt $(($y + $height)) ]]; then
          show 
          echo here
        else
          hide
        fi
        ;;
      # Window presence false
      1)
        show
        ;;
      # Fullscreen
      2)
        hide
        ;;
    esac
    sleep $INTERVAL
  done
  
}

#params="$@"

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
    -a|--paddings=)
      shift 
      x="$(printf "$1" | cut -d 'x' -f1)"
      y="$(printf "$1" | cut -d 'x' -f2 | cut -d '+' -f1)"
      height="$(printf "$1" | cut -d '+' -f2)"
      width="$(printf "$1" | cut -d '+' -f3)"
      printf %s\\n "$x $y $height $width"
      ;;
  esac
done

main "$params"
