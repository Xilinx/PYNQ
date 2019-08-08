# WiFi Connect package

This package connects to a wifi network at boot, using `wpa_supplicant`.

## How to use

The wifi connection will be made automatically at boot, but there are a few
configuration options picked up from files in the boot partition. Change these
files to describe your own set of wifi networks and your wifi adapter.

  * `wpa_supplicant.conf`: is a standard `wpa_supplicant` configuration file,
    listing all of the networks that the board should connect to.
    See below for an example config file.

  * `wifi.ko`: is an optional driver file. This lets you easily inject wifi
    drivers that are not in the mainline kernel.

## Example `wpa_supplicant.conf` file

Here is an example config file that describes two different networks:

```
network={
    # Network name
    ssid="MyHomeNetwork"

    # Password in plain text using quotes
    psk="AndItsPlaintextPassword"

    # A unique ID for this entry
    id_str="home"
}

network={
    # Second network name
    ssid="ConferenceWiFi"
    
    # Password obfuscated with wpa_passphrase command
    psk=d1d140ae3d73f946bfb117479b8967a5a5b541f712c0f40ba8049f34ce43e89c
    
    # A unique ID
    id_str="demonight"
}
```
