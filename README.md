# Device Battery Levels

A theme-aware Omarchy bar widget that shows battery levels and charging status for compatible wireless mice, keyboards, headphones, and laptop batteries.

Click the horizontal battery icon to open a popup with **Left**, **Center**, and **Right** buttons for moving the widget between bar sections, plus sections for detected **Mouse**, **Keyboard**, **Headphones**, and **Laptop** batteries. Each detected device shows its model, charge percentage, and status. Device sections are hidden when no battery of that type is available. The widget refreshes every two seconds and uses the active Omarchy theme colors.

<img width="612" height="436" alt="screenshot-2026-10-19_04-29-04" src="https://github.com/user-attachments/assets/0537db72-0e1e-4a2a-9105-6b86e5fb8e56" />


## Compatibility

The widget reads battery information exposed by Linux in `/sys/class/power_supply`. It looks for supplies with `POWER_SUPPLY_TYPE=Battery`, then uses `udevadm` input-device properties to classify them as a mouse, keyboard, or headphones. Headphone detection uses a matching Linux sound device or a recognizable headphone or headset product name. System-scoped supplies and common laptop battery device names are classified as the laptop battery.

A device is supported when its Linux driver exposes battery capacity and status through the power-supply interface and its input device is identifiable through udev. Support depends on the device, connection type, and Linux driver; not every wireless device or brand exposes battery information this way. Sections for devices without an exposed battery reading are hidden.

## Install

Install it in Omarchy with:

```sh
omarchy plugin add https://github.com/Z1Z0R/Device-Battery-Levels.git --enable
```

The plugin is enabled as a bar widget and default location is on the right (when installing there will be a prompt to choose plugin location).

To enable it later:

```sh
omarchy plugin enable device-battery-levels
```

Uninstall it in Omarchy with:

```sh
omarchy plugin remove device-battery-levels
```

## Requirements

- Omarchy with shell plugin support
- Linux `power_supply` battery entries for the device
- `udevadm` and standard shell utilities (`grep`, `sed`, `head`, `tr`)

No brand-specific utility or battery daemon is required.

## Development / validation

Validate the plugin manifest and layout with:

```sh
omarchy plugin validate .
```

The plugin entry point is `Battery.qml`; `battery-status.sh` reads and classifies available battery devices.

## License

This project is licensed under the [GNU General Public License v3.0 only](https://www.gnu.org/licenses/gpl-3.0.html); see [`LICENSE`](LICENSE) for the full terms. GPLv3 permits commercial and noncommercial use, copying, modification, and redistribution under its terms. Distributed modified versions must comply with GPLv3, including its source-code and license-notice requirements.
