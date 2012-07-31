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
use URI::Escape qw(uri_escape uri_escape_utf8);


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

#    Slim::Player::ProtocolHandlers->registerHandler(
#        cloudplaya => 'Plugins::SBCloudPlayer::ProtocolHandlerCloudPlaya');

    # Slim::Menu::AlbumInfo->registerInfoProvider(sbcloudplayer => (
        # below => 'addalbum',
        # func  => \&album_info_handler,
    # ));
}


sub getDisplayName {
    return 'PLUGIN_SBCLOUDPLAYER_DISPLAY_NAME'
}


# Don't add this to any menu
sub playerMenu {
    return shift->can('nonSNApps') && $prefs->get('is_app') ? undef : 'RADIO';
}


# sub album_info_handler {
    # return _object_info_handler('album', @_);
# }


# sub _object_info_handler {
    # my ($object_type, $client, $url, $obj, $remote_meta, $tags) = @_;
    # $tags ||= {};

    # my $special;

    # if ($objectType eq 'album') {
        # $special->{'actionParam'} = 'album_id';
        # $special->{'modeParam'}   = 'album';
        # $special->{'urlKey'}      = 'album';
    # }

    # if ($mixable) {
        # return {
            # type => 'redirect',
            # jive => {
                # actions => {
                    # go => {
                        # player => 0,
                        # cmd => ['musicip', 'mix'],
                        # params => {
                            # menu => 1,
                            # useContextMenu => 1,
                            # $special->{'actionParam'} = $obj->id,
                        # },
                    # },
                # },
            # },
        # };
    # }
# }


sub toplevel {
    my ($client, $callback, $args) = @_;

    my @menu = (
        {
            name => $client->string('PLUGIN_SBCLOUDPLAYER_BROWSE_ARTISTS'),
            url => \&list_artists,
            icon => 'html/images/artists.png',
            type => 'link',
        },
        {
            name => $client->string('PLUGIN_SBCLOUDPLAYER_BROWSE_ALBUMS'),
            url => \&list_albums,
            icon => 'html/images/albums.png',
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
    my %actions;
    my $albumData;
    my $albumInfo;

    if ($by_type eq 'by-artist') {
        # my $artist = shift;

        # @menu = &populate_from_cloudplaya(
            # $client,
            # sub {
                # my $song = shift;
                # my $item = {
                    # name => $song->{'title'},
                    # type => 'audio',
                    # line1 => $song->{'title'},
                    # line2 => $song->{'artist'},
                    # artist => $song->{'artist'}, # TODO: trackartst vs. artist
                    # #play_index => $song->{'track_num'},
                    # #discc => $song->{'disc_num'},
                    # playall => 1,
                    # hasMetadata => 'track',
                    # duration => $song->{'duration'},
                    # url => $song->{'url'},
                # };

                # # if (my $secs = $song->{'duration'}) {
                    # # $item->{'secs'} = $secs;
                    # # $item->{'duration'} = sprintf('%d:%02d', int($secs / 60),
                                                  # # $secs % 60);
                    # # $item->{'duration'} = $secs;
                # # }

                # return $item;
            # },
            # Plugins::SBCloudPlayer::CloudPlaya->get_songs_by_artist(
                # $artist));
    } elsif ($by_type eq 'by-album') {
        my $album = shift;
        my $offset = 0;

        $cover_image_url = $album->{'cover_image_url'};

        @menu = &populate_from_cloudplaya(
            $client,
            sub {
                my $song = shift;
                my $year = $song->{'album_release_date'};
                $year =~ s/^(\d{4})-.*/$1/g;

                my $item = {
                    type => 'audio',
                    title => $song->{'title'},
                    name => $song->{'title'},
                    name2 => $song->{'artist'},
                    album => $song->{'album'},
                    artist => $song->{'artist'}, # TODO: trackartst vs. artist
                    tracknum => $song->{'track_num'},
                    track => $song->{'track_num'},
                    play_index => $offset++,
                    playall => 1,
                    disc => $song->{'disc_num'},
                    hasMetadata => 'track',
                    year => $year,
                    url => $song->{'url'},
                    image => $cover_image_url,
                };

                if (my $secs = $song->{'duration'}) {
                    $item->{'secs'} = $secs;
                    $item->{'duration'} = $secs;
                    #$item->{'duration'} = sprintf('%d:%02d', int($secs / 60),
                    #                              $secs % 60);
                }

                return $item;
            },
            Plugins::SBCloudPlayer::CloudPlaya->get_songs_by_album($album));

        # my $album = Slim::Schema->find(Album => $albumId);
        # my $feed = Slim::Menu::AlbumInfo->menu($client, $album->url,
                                               # $album, undef) if $album;
        # $albumMetadata = $feed->{'items'} if $feed;

        %actions = (
            allAvailableActionsDefind => 1,
            commonVariable => [album_id => 'id'],
            info => {
                command => ['albuminfo', 'items'],
            },
            play => {
                command => ['playlistcontrol'],
                fixedParams => {cmd => 'load'},
            },
            add => {
                command => ['playlistcontrol'],
                fixedParams => {cmd => 'add'},
            },
            insert => {
                command => ['playlistcontrol'],
                fixedParams => {cmd => 'insert'},
            },
            remove => {
                command => ['playlistcontrol'],
                fixedParams => {cmd => 'delete'},
            },
        );
        $actions{'playall'} = $actions{'play'};
        $actions{'addall'} = $actions{'add'};

        # if ($args->{'wantMetadata'}) {
            # $ret->{'albumInfo'} = {
                # info => {
                    # command => ['sbcloudplayerinfocmd', 'items'],
                # },
            # };

            # $ret->{'albumData'} = [
                # {
                    # type => 'link',
                    # label => 'ARTIST',
                    # name => $album->{'artist'},
                    # url => 'anyurl',
                    # #itemActions
                # },
                # {
                    # type => 'link',
                    # label => 'ALBUM',
                    # name => $album->{'name'},
                # },
            # ];
        # }
    }

    $callback->({
        cover => $cover_image_url,
        items => \@menu,
        #actions => \%actions,
        sorted => 0,
#        albumInfo => $albumInfo,
#        albumData => $albumData,
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
                type => 'playlist',
                url => \&list_albums,
                playlist => \&list_songs,
                passthrough => ['by-artist', $artist],
            };
        },
        Plugins::SBCloudPlayer::CloudPlaya->get_artists());

    $callback->({
        items => \@menu,
        sorted => 1,
    });
}

sub list_albums {
    my ($client, $callback, $args, $by_type, $artist) = @_;

    my @menu = &populate_from_cloudplaya(
        $client,
        sub {
            my $album = shift;
            my $year = $album->{'release_date'};
            $year =~ s/^(\d{4})-.*/$1/g;

            return {
                name => $album->{'name'},
                image => uri_escape($album->{'cover_image_url'}),
                icon => $album->{'cover_image_url'},
                type => 'playlist',
                playlist => \&list_songs,
                artist => $album->{'artist_name'},
                url => \&list_songs,
                hasMetadata => 'album',
                year => $year,
                passthrough => ['by-album', $album],
            };
        },
        Plugins::SBCloudPlayer::CloudPlaya->get_albums($artist));

    $callback->({
        items => \@menu,
        sorted => 0,
    });
}


1;

# vim: set et ts=4 sw=4:
