#!/usr/bin/python
# -*- coding: utf-8 -*-
from freddist.core import setup
from freddist.version import get_git_version

PROJECT_NAME = 'fred-distutils'
PACKAGE_NAME = 'fred-distutils'

setup(
        name=PROJECT_NAME,
        description='Fred Distutils',
        author='Aleš Doležal, CZ.NIC',
        author_email='ales.dolezal@nic.cz',
        url='http://www.nic.cz/',
        license='GNU GPL',
        platforms=['posix'],
        long_description='Fred Distutils, utilities for easier way to build packages.',

        packages=['freddist', 'freddist.command', 'freddist.nicms'],
        package_data={'freddist': ['README']},

      )

