SBCloudPlayer
=============

SBCloudPlayer is a plugin for Squeezebox that provides integration with
Amazon's Cloud Player service. All the albums, artists, and songs on a
Cloud Player account can be played on any Squeezebox device connected to
a server with this plugin enabled.


Installation
------------

To install SBCloudPlayer, you will first need to install the cloudplaya_
utility application. This provides a set of command line utilities that
SBCloudPlayer will use to communicate with Amazon.

.. _cloudplaya: http://github.com/chipx86/cloudplaya/

You must first have Python Setuptools installed. This should be available
through your Linux distribution, or by downloading a setup file for Windows.

Once that's installed, you can install cloudplaya by typing::

    $ sudo easy_install cloudplaya


You will then want to add this plugin to your server.

If you are working off of the Git checkout, just copy this source tree into a
subdirectory named ``SBCloudPlayer`` in your Squeezebox Plugins directory. For
example::

    $ sudo cp -av . /usr/share/squeezeboxserver/Plugins/SBCloudPlayer


Otherwise, download_ a copy and extract the files in the
``chipx86-sbcloudplayer-*`` directory to the Plugins directory as above.

.. _download: https://github.com/chipx86/sbcloudplayer/zipball/master


Then restart your Squeezebox service.


Configuration
-------------

You will need to authenticate once with your Amazon username and password.
Go into :guilabel:`Settings -> Advanced -> SBCloudPlayer`, enter your Amazon
username and password, and hit :guilabel:`Apply`.

Authentication might take several seconds to complete.

Note that your password will not be stored anywhere. It is only used to get
an authentication token.


Usage
-----

Once you have authenticated, you can close the settings and go back
to your main Squeezebox UI. You should see an Amazon Cloud Player entry
under :guilabel:`My Apps`. Just browse for what you want to play!


Known Problems
--------------

I suspect that the URLs for streaming songs change every so often. Right now,
we cache the URLs, but this doesn't seem to be a good long-term solution.
If this is a proble, clear out your
:file:`/var/lib/squeezeboxserver/cache/sbcloudplayer.db*` caches.
