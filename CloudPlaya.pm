package Plugins::SBCloudPlayer::CloudPlaya;

use strict;

use Slim::Utils::Log;


my $log = logger('plugin.sbcloudplayer');


sub authenticate {
    my ($class, $username, $password) = @_;

    return $class->run("authenticate --username='$username' " .
                       "--password='$password'")
}


sub get_artists {
    my $class = shift;

    return $class->run("get-artists --format='%(name)s'", 1);
}


sub get_albums {
    my ($class, $artist) = @_;
    my $params = '';

    if ($artist) {
        $artist =~ s/'/\\'/g;
        $params = "--artist='$artist'";
    }

    my $query_result =
        $class->run("get-albums $params " .
                    "--format='%(name)s\t%(artist_name)s\t" .
                    "%(cover_image_url)s'");
    my ($errcode, @lines) = @$query_result;

    my @result;
    my @albums;

    $result[0] = $errcode;

    foreach my $line (@lines) {
        my @info = split('\t', $line);

        push @albums, {
            name => shift @info,
            artist => shift @info,
            cover_image_url => shift @info,
        }
    }

    push @result, sort { $a->{'name'} <=> $b->{'name'} } @albums;

    return \@result;
}


sub get_songs_by_artist {
    my ($class, $artist) = @_;
    my $query_result =
        $class->run("get-songs --artist='$artist' " .
                    "--format='%(track_num)s\t%(artist_name)s\t" .
                    "%(album_name)s\t%(title)s\t" .
                    "%(duration)s\t%(disc_num)s'");
    my ($errcode, @lines) = @$query_result;

    my @result;
    my @songs;

    $result[0] = $errcode;

    foreach my $line (@lines) {
        my @info = split('\t', $line);

        push @songs, {
            track_num => shift @info,
            artist => shift @info,
            album => shift @info,
            title => shift @info,
            duration => shift @info,
            disc_num => shift @info,
        };
    }

    push @result, sort {
        if ($a->{'track_num'} == $b->{'track_num'}) {
            $a->{'title'} <=> $a->{'title'},
        } else {
            $a->{'track_num'} <=> $a->{'track_num'},
        }
    } @songs;

    return \@result;
}


sub get_songs_by_album {
    my ($class, $album) = @_;

    my $artist_name = $album->{'artist'};
    my $album_name = $album->{'name'};
    $artist_name =~ s/'/\\'/g;
    $album_name =~ s/'/\\'/g;

    my $query_result =
        $class->run("get-songs --artist='$artist_name' --album='$album_name' " .
                    "--format='%(track_num)s\t%(artist_name)s\t" .
                    "%(album_name)s\t%(title)s\t" .
                    "%(duration)s\t%(disc_num)s'");
    my ($errcode, @lines) = @$query_result;

    my @result;
    my @songs;

    $result[0] = $errcode;

    foreach my $line (@lines) {
        my @info = split('\t', $line);

        push @songs, {
            track_num => shift @info,
            artist => shift @info,
            album => shift @info,
            title => shift @info,
            duration => shift @info,
            disc_num => shift @info,
        };
    }

    push @result, sort {
        # if ($a->{'track_num'} eq $b->{'track_num'}) {
            # $a->{'title'} <=> $a->{'title'},
        # } else {
            # $a->{'track_num'} <=> $a->{'track_num'},
        # }
        $a->{'track_num'} <=> $a->{'track_num'},
    } @songs;

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
