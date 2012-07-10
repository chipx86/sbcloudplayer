package Plugins::SBCloudPlayer::CloudPlaya;

use strict;

use Slim::Utils::Log;


my $log = logger('plugin.sbcloudplayer');
my $cache = Slim::Utils::Cache->new('sbcloudplayer');


sub authenticate {
    my ($class, $username, $password) = @_;

    return $class->run("authenticate --username='$username' " .
                       "--password='$password'")
}


sub get_stream_urls {
    my ($class, $song_ids_ref) = @_;
    my @song_ids = @$song_ids_ref;

    return $class->run("get-stream-urls " . join(' ', @song_ids));
}


sub get_artists {
    my $class = shift;
    my $cache_key = 'sbcloudplayer_artists';
    my $cached = $cache->get($cache_key);
    my @result;

    if ($cached) {
        $result[0] = '';
        push @result, @$cached;
        return \@result;
    }

    my $query_result = $class->run("get-artists --format='%(name)s'", 1);
    my ($errcode, @lines) = @$query_result;

    if ($errcode ne '') {
        return $query_result;
    }

    $cache->set($cache_key, \@lines, 86400);

    return $query_result;
}


sub get_albums {
    my ($class, $artist) = @_;
    my $cache_key = 'sbcloudplayer_albums';

    if ($artist) {
        $cache_key .= '__' . $artist;
    }

    my $cached = $cache->get($cache_key);
    my @result;

    if ($cached) {
        $result[0] = '';
        push @result, @$cached;
        return \@result;
    }

    my $params = '';

    if ($artist) {
        $artist =~ s/'/\\'/g;
        $params = "--artist='$artist'";
    }

    my $query_result =
        $class->run("get-albums $params " .
                    "--format='%(id)s\t%(name)s\t%(artist_name)s\t" .
                    "%(cover_image_url)s'");
    my ($errcode, @lines) = @$query_result;

    my @albums;

    $result[0] = $errcode;

    foreach my $line (@lines) {
        my @info = split('\t', $line);

        push @albums, {
            id => shift @info,
            name => shift @info,
            artist => shift @info,
            cover_image_url => shift @info,
        }
    }

    @albums = sort { $a->{'name'} cmp $b->{'name'} } @albums;

    $cache->set($cache_key, \@albums, 86400);

    push @result, @albums;
    return \@result;
}


sub get_songs_by_artist {
    # my ($class, $artist) = @_;
    # my $query_result =
        # $class->run("get-songs --artist='$artist' " .
                    # "--format='%(id)s\t%(track_num)s\t%(artist_name)s\t" .
                    # "%(album_name)s\t%(title)s\t" .
                    # "%(duration)s\t%(disc_num)s'");
    # my ($errcode, @lines) = @$query_result;

    # my @result;
    # my @songs;

    # $result[0] = $errcode;

    # if ($errcode ne '') {
        # push @result, undef;
        # return \@result;
    # }

    # my @song_ids;
    # my $num_songs = 0;

    # foreach my $line (@lines) {
        # my @info = split('\t', $line);
        # my $id = shift @info;

        # push @songs, {
            # id => $id,
            # track_num => shift @info,
            # artist => shift @info,
            # album => shift @info,
            # title => shift @info,
            # duration => shift @info,
            # disc_num => shift @info,
        # };

        # push @song_ids, $id;

        # $num_songs += 1;
    # }

    # my $query_result = $class->get_stream_urls(\@song_ids);
    # my ($errcode, @urls) = @$query_result;

    # if ($errcode ne '') {
        # $log->error("Error fetching URLs: $errcode");
        # $result[0] = '';
        # $result[1] = undef;
        # return \@result;
    # }

    # $log->error("Got $num_songs songs");
    # for (my $i = 0; $i < $num_songs; $i++) {
        # $songs[$i]->{'url'} = $urls[$i];
    # }

    # push @result, sort {
        # if ($a->{'track_num'} == $b->{'track_num'}) {
            # $a->{'title'} cmp $a->{'title'},
        # } else {
            # $a->{'track_num'} cmp $a->{'track_num'},
        # }
    # } @songs;

    # return \@result;
}


sub get_songs_by_album {
    my ($class, $album) = @_;

    my $cache_key = 'sbcloudplayer_album_songs_' . $album->{'id'};
    my $cached_songs = $cache->get($cache_key);
    my @result;

    if ($cached_songs) {
        $log->error("Loading songs from cache");
        $result[0] = '';
        push @result, @$cached_songs;
        return \@result;
    }

    my $artist_name = $album->{'artist'};
    my $album_name = $album->{'name'};
    $artist_name =~ s/'/\\'/g;
    $album_name =~ s/'/\\'/g;

    my $query_result =
        $class->run("get-songs --artist='$artist_name' --album='$album_name' " .
                    "--format='%(id)s\t%(track_num)s\t%(artist_name)s\t" .
                    "%(album_name)s\t%(title)s\t" .
                    "%(duration)s\t%(disc_num)s'");
    my ($errcode, @lines) = @$query_result;

    my @result;

    $result[0] = $errcode;

    if ($errcode ne '') {
        push @result, undef;
        return \@result;
    }

    my @songs;
    my @song_ids;
    my $num_songs = 0;

    foreach my $line (@lines) {
        my @info = split('\t', $line);
        my $id = shift @info;

        push @songs, {
            id => $id,
            track_num => shift @info,
            artist => shift @info,
            album => shift @info,
            title => shift @info,
            duration => shift @info,
            disc_num => shift @info,
        };

        push @song_ids, $id;

        $num_songs += 1;
    }

    my $query_result = $class->get_stream_urls(\@song_ids);
    my ($errcode, @urls) = @$query_result;

    if ($errcode ne '') {
        $log->error("Error fetching URLs: $errcode");
        $result[0] = '';
        $result[1] = undef;
        return \@result;
    }

    $log->error("Got $num_songs songs");
    for (my $i = 0; $i < $num_songs; $i++) {
        $songs[$i]->{'url'} = $urls[$i];
    }

    @songs = sort {
        # if ($a->{'track_num'} eq $b->{'track_num'}) {
            # $a->{'title'} cmp $a->{'title'},
        # } else {
            # $a->{'track_num'} cmp $a->{'track_num'},
        # }
        $a->{'track_num'} cmp $a->{'track_num'},
    } @songs;

    $cache->set($cache_key, \@songs, 86400);

    push @result, @songs;
    return \@result;
}


sub run {
    my ($class, $args, $sorted) = @_;
    my $cmd = "cloudplaya --session-file=/tmp/cloudplayasession $args 2>&1";
    my @result;

    $log->debug($cmd);

    my $data = `$cmd`;

    if ($? == 0) {
        my @lines = split('\n', $data);
        $result[0] = '';

        if ($sorted == 1) {
            @lines = sort(@lines);
        }

        push @result, @lines
    } else {
        $result[0] = $data;
        $result[1] = [];
    }

    return \@result;
}

1;

# vim: set et ts=4 sw=4:
