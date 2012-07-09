package Plugins::SBCloudPlayer::Settings;


use strict;
use base qw(Slim::Web::Settings);
use Plugins::SBCloudPlayer::CloudPlaya;
use Slim::Utils::Log;
use Slim::Utils::Prefs;


my $log = logger('plugin.sbcloudplayer');
my $prefs = preferences('plugin.sbcloudplayer');

$prefs->init({
    username => 'username',
    is_app   => 1,
});


sub name {
    return Slim::Web::HTTP::CSRF->protectName('PLUGIN_SBCLOUDPLAYER');
}

sub page {
    return Slim::Web::HTTP::CSRF->protectURI(
        'plugins/SBCloudPlayer/settings/basic.html');
}

sub handler {
    my ($class, $client, $params, $callback) = @_;

    #if ($params->{'saveSettings'} && $params->{'mypref'}) {
    #   my $value = $params->{'mypref'};
    #   $prefs->set('mypref', " $value"); # Add a leading space to make messages display nicely
    #}
    #
    # This puts it on the webpage.
    #$params->{'prefs'}->{'mypref'} = $prefs->get{'mypref'};

    my $password = $params->{'password'};
    $params->{'password'} = '';

    if ($params->{'username'} ne '' and $password ne '') {
        my $result = Plugins::SBCloudPlayer::CloudPlaya->authenticate(
            $params->{'username'},
            $params->{'password'});

        if ($? != 0) {
            $log->error("Failed to authenticate: $result");
            $callback->();
        }
    }

    return $class->SUPER::handler($client, $params, $callback);
}

1;

# vim: set et ts=4 sw=4:
