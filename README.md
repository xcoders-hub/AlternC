![](https://alternc.com/logo.png)

## AlternC: Web and Email Hosting Software Suite 

AlternC is a software helping system administrators to handle Web and Email services management. It should be easy to install, based only on free software. 

This software consist of an automatic install and configuration system, a web control panel to manage hosted users and their web services such as domains, email accounts, ftp accounts, web statistics...

Technically, AlternC is based on Debian GNU/Linux distribution and it depends on other software such as Apache, Postfix, Dovecot, Mailman (...). It also contains an API documentation so that users can easily customize their web desktop.

This project native tongue is French. However, the packages are available at least in French and English. 


## Installation

[To install AlternC, please follow our install documentation](https://alternc.com/Install-en)

[Pour installer AlternC, merci de suivre la documentation d'installation](https://alternc.com/Install-fr)

## Developper information

* This software is built around a Debian package for Squeeze whose packaging instructions are located in [debian/](debian/) folder
* To **build the packages**, clone this repository in a Debian machine and use `debuild` or `dpkg-buildpackage` from source code root.
* If you want to **build it for Wheezy**, clone the source and patch it for Wheezy using [wheezy/patch.sh](wheezy/patch.sh) script. You'll be able to use dpkg-buildpackage to build the Wheezy version.
* If you want to **build it for Jessie**, clone the source and patch it for Wheezy using [wheezy/patch.sh](wheezy/patch.sh) script then patch it for Jessie using [jessie/patch.sh](jessie/patch.sh) script. You'll be able to use dpkg-buildpackage to build the Jessie version.

* The web control panel pages written in php are located in [bureau/admin](bureau/admin) and the associated PHP classes doing the stuff are in [bureau/class](bureau/class).



## License

AlternC is distributed under the GPL v2 or later license. See `COPYING`.

AlternC's translations (po files) are distributed under the [Creative Commons CC0 license](https://creativecommons.org/publicdomain/zero/1.0/). Don't participate to the translation if you don't agree to publish your translations under that license.

