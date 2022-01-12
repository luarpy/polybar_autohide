# Autohide script for Polybar

Idea from [akean's](https://github.com/arkeane/polybar_autohide) initial script

It is based on the ```polybar-msg``` usage

This script toggles polybars hide/show state by checking the presence of active X11 window. When theres is an active window, it hides from screen.

I am planing to add a PID variable so the script only applies to a specific polybar proccess.

## Installation

Clone this repository
```bash
git clone https://github.com/luarpy/polybar_autohide.git
```

Them, copy ```autohide-polybar.sh``` to your personal polybar scripts directory and execute it in beginning of your window manager

Example for Openbox:
```bash
cp ~/polybar_autohide/autohide-polybar.sh ~/.config/polybar/scripts

# Inside ~/.config/openbox/autostart write after polybar's launch
bash ~/.config/polybar/scripts/autohide-polybar.sh &
```

## Dependencies

- xdotool
- xprop

## License

[GNU General Public License V3](https://www.gnu.org/licenses/gpl-3.0.txt)
