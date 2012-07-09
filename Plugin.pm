# SBCloudPlayer
#
# Copyright (C) 2012 Christian Hammond

package Plugins::SBCloudPlayer::Plugin;

use strict;
use warnings;

use base qw(Slim::Plugin::OPMLBased);

use Plugins::SBCloudPlayer::CloudPlaya;
use Plugins::SBCloudPlayer::Settings;
use File::Spec::Functions qw(:ALL);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Strings qw(string);


my $log = Slim::Utils::Log->addLogCategory({
    category     => 'plugin.sbcloudplayer',
    defaultLevel => 'DEBUG',
    description  => 'PLUGIN_SBCLOUDPLAYER',
});

my $prefs = preferences('plugin.sbcloudplayer');


sub initPlugin {
    my $class = shift;

    $class->SUPER::initPlugin(
        tag    => 'sbcloudplayer',
        feed   => \&toplevel,
        is_app => $class->can('nonSNApps') && $prefs->get('is_app') ? 1 : undef,
        menu   => 'music_services',
        weight => 2,
    );

    Plugins::SBCloudPlayer::Settings->new;
}


sub getDisplayName {
    return 'PLUGIN_SBCLOUDPLAYER_DISPLAY_NAME'
}


# Don't add this to any menu
sub playerMenu {
    return shift->can('nonSNApps') && $prefs->get('is_app') ? undef : 'RADIO';
}


sub toplevel {
    my ($client, $callback, $args) = @_;

    my @menu = (
        {
            name => $client->string('PLUGIN_SBCLOUDPLAYER_BROWSE_ARTISTS'),
            url => \&list_artists,
            type => 'link',
        },
        {
            name => $client->string('PLUGIN_SBCLOUDPLAYER_BROWSE_ALBUMS'),
            url => \&list_albums,
            type => 'link',
        },
        {
            name => $client->string('PLUGIN_SBCLOUDPLAYER_BROWSE_SONGS'),
            url => \&list_songs,
            type => 'link',
        },
    );

    $callback->(\@menu);
}


sub populate_from_cloudplaya {
    my ($client, $build_item, $results_ref) = @_;
    my ($err, @items) = @$results_ref;
    my @menu;

    if ($err eq '') {
        foreach my $item (@items) {
            push @menu, &$build_item($item);
        }
    } elsif ($err =~ /authenticate/i) {
        push @menu, {
            name => 'You must authenticate in settings in order to ' .
                    'access your account.',
            type => 'text',
        };
    } else {
        $log->error("Error loading data: $err");
        push @menu, {
            name => $client->string('PLUGIN_SBCLOUDPLAYER_ERROR_LOADING'),
            type => 'text',
        };
        push @menu, {
            name => $err,
            type => 'text',
        };
    }

    return @menu;
}


sub play_song {
}


sub list_songs {
    my $client = shift;
    my $callback = shift;
    my $args = shift;
    my $by_type = shift;
    my $cover_image_url = '';
    my @menu;

    if ($by_type eq 'by-artist') {
        my $artist = shift;

        @menu = &populate_from_cloudplaya(
            $client,
            sub {
                my $song = shift;
                my $item = {
                    name => $song->{'title'},
                    type => 'audio',
                    line1 => $song->{'title'},
                    line2 => $song->{'artist'},
                    #play_index => $song->{'track_num'},
                    #discc => $song->{'disc_num'},
                    playall => 1,
                    hasMetadata => 'track',
                };

                if (my $secs = $song->{'duration'}) {
                    $item->{'secs'} = $secs;
                    $item->{'duration'} = sprintf('%d:%02d', int($secs / 60),
                                                  $secs % 60);
                }

                return $item;
            },
            Plugins::SBCloudPlayer::CloudPlaya->get_songs_by_artist(
                $artist));
    } elsif ($by_type eq 'by-album') {
        my $album = shift;

        $cover_image_url = $album->{'cover_image_url'};

        @menu = &populate_from_cloudplaya(
            $client,
            sub {
                my $song = shift;
                my $item = {
                    name => $song->{'track_num'} . '. ' . $song->{'title'},
                    type => 'audio',
                    line1 => $song->{'title'},
                    line2 => $song->{'artist'},
                    #play_index => $song->{'track_num'},
                    #discc => $song->{'disc_num'},
                    playall => 1,
                    hasMetadata => 'track',
                };

                if (my $secs = int($song->{'duration'})) {
                    $item->{'secs'} = $secs;
                    $item->{'duration'} = sprintf('%d:%02d', int($secs / 60),
                                                  $secs % 60);
                }

                return $item;
            },
            Plugins::SBCloudPlayer::CloudPlaya->get_songs_by_album($album));
    }

    $callback->({
        cover => $cover_image_url,
        items => \@menu,
    });
}


sub list_artists {
    my ($client, $callback) = @_;
    my @menu = &populate_from_cloudplaya(
        $client,
        sub {
            my $artist = shift;

            return {
                name => $artist,
                type => 'link',
                url => \&list_albums,
                passthrough => [$artist],
            };
        },
        Plugins::SBCloudPlayer::CloudPlaya->get_artists());
    $callback->(\@menu);
}

sub list_albums {
    my ($client, $callback, $args, $artist) = @_;

    $log->error("Artist = $artist");
    my @menu = &populate_from_cloudplaya(
        $client,
        sub {
            my $album = shift;

            return {
                name => $album->{'name'},
                image => $album->{'cover_image_url'},
                type => 'link',
                url => \&list_songs,
                passthrough => ['by-album', $album],
            };
        },
        Plugins::SBCloudPlayer::CloudPlaya->get_albums($artist));
    $callback->(\@menu);
}


1;

# vim: set et ts=4 sw=4:
