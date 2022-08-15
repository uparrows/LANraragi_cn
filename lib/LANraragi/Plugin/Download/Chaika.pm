package LANraragi::Plugin::Download::Chaika;

use strict;
use warnings;
no warnings 'uninitialized';
use utf8;
# Meta-information about your plugin.
sub plugin_info {

    return (
        # Standard metadata
        name        => "Chaika.moe Downloader",
        type        => "download",
        namespace   => "chaikadl",
        author      => "Difegue",
        version     => "1.0",
        description => "下载给定的 chaika.moe URL 并将其添加到 LANraragi。 暂时不支持图库链接!",

        # Downloader-specific metadata
        # https://panda.chaika.moe/archive/_____/
        url_regex => "https?:\/\/panda.chaika.moe\/archive\/.*"
    );

}

# Mandatory function to be implemented by your downloader
sub provide_url {
    shift;
    my $lrr_info = shift;

    # Get the URL to download
    my $url = $lrr_info->{url};

    # Wow!
    return ( download_url => $url . "/download" );
}

1;
