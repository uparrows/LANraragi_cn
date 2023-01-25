package LANraragi::Plugin::Login::Fakku;
use utf8;
use strict;
use warnings;
no warnings 'uninitialized';

use Mojo::UserAgent;
use LANraragi::Utils::Logging qw(get_logger);

sub plugin_info {

    return (
        name      => "Fakku",
        type      => "login",
        namespace => "fakkulogin",
        author    => "Nodja",
        version   => "0.1",
        description =>
          "处理fakku登录。cookie的有效期只有 7 天，所以不要忘记更新它.",
        parameters => [
            { type => "string", desc => "fakku_sid cookie value" }
        ]
    );

}

sub do_login {

    shift;
    my ( $fakku_sid ) = @_;

    my $logger = get_logger( "Fakku Login", "plugins" );
    my $ua     = Mojo::UserAgent->new;

    if ( $fakku_sid ne "" ) {
        $logger->info("Cookie provided ($fakku_sid)!");
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'fakku_sid',
                value  => $fakku_sid,
                domain => 'fakku.net',
                path   => '/'
            )
        );
    } else {
        $logger->info("No cookies provided, returning blank UserAgent.");
    }

    return $ua;
}
1;