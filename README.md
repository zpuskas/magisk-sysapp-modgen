**NOTICE: This project has been migrated to [Codeberg](https://codeberg.org/zpuskas/magisk-sysapp-modgen)! This repository has been archived, will receive no further updates, and will be deleted on 2026-09-01!**

# Magisk sysapp module generator

## What is this?

Build files to generate system application modules to be used with Magisk under
Android 15.

Currently it only supports a handful GApps derived from NikGapps.

## What for?

Certain applications need elevated system privileges in order to function
properly. Modern Android ROM partitioning however leaves no space for manual
installation of additional applications into the system partition.

Using these build files one can generate modules which when added to Magisk will
make contained applications to be installed and running as system applications.

This is mainly useful for people running de-Googled Android ROMS with Magisk
installed, who want to keep their system minimal but at the same time also have
select functionality installed based on closed source binaries.

## How to use?

Build the relevant app module by running:

`make -f Makefile.{chosen_app}`

Once build finishes, there will be a `{chosen_app}_system_installer.zip` module
file generated. Copy that file to the phone and then in Magisk under the modules
tab use "Install from storage".

Reboot your phone.

Note that often the apps installed by the modules are just stubs and updates
need to be installed from the Play Store (Aurora Store works too!) to obtain
full functionality.

## Licensing

Build files: GPLv3 Magisk module template: MIT

## Attribution

* [NikGapps](https://nikgapps.com/)
* [Magisk module guide](https://topjohnwu.github.io/Magisk/guides.html)
* [Universal System App Installer](https://github.com/hc841/Universal_System_App_Installer)
