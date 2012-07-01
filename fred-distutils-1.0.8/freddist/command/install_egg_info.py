#!/usr/bin/python
# -*- coding: utf-8 -*-
"""This module was created due to change behavoir for create deb package.
The egg info is not installed in this mode.
"""
from distutils import log
from distutils.command.install_egg_info import install_egg_info \
                as _install_egg_info


class install_egg_info(_install_egg_info):
    """Install an .egg-info file for the package"""

    def run(self):
        "Run install egg or skip it if the debian option is set"
        if self.distribution.command_options.get('install', 
                                            {}).get('prepare_debian_package'):
            log.info("Skip file %s", self.target)
        else:
            # install egg info only if install has not debian option
            _install_egg_info.run(self)
