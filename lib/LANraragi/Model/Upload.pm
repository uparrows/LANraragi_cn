package LANraragi::Model::Upload;

use strict;
use warnings;

use Redis;
use URI::Escape;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use File::Find qw(find);
use File::Copy qw(move);

use LANraragi::Utils::Database qw(invalidate_cache compute_id);
use LANraragi::Utils::Logging qw(get_logger);
use LANraragi::Utils::Database qw(redis_encode);
use LANraragi::Utils::Generic qw(is_archive remove_spaces remove_newlines trim_url);

use LANraragi::Model::Config;
use LANraragi::Model::Plugins;
use LANraragi::Model::Category;

# Handle files uploaded by the user, or downloaded from remote endpoints.

# Process a file.
# First argument is the filepath, preferably in a temp directory,
# as we'll copy it to the content folder and delete the original at the end.
#
# The file will be added to a category, if its ID is specified.
# You can also specify tags to add to the metadata for the processed file before autoplugin is ran. (if it's enabled)
#
# Returns a status value, the ID and title of the file, and a status message.
sub handle_incoming_file {

    my ( $tempfile, $catid, $tags )   = @_;
    my ( $filename, $dirs,  $suffix ) = fileparse( $tempfile, qr/\.[^.]*/ );
    $filename = $filename . $suffix;
    my $logger = get_logger( "文件上传/下载", "lanraragi" );

    # Check if file is an archive
    unless ( is_archive($filename) ) {
        return ( 0, "deadbeef", $filename, "不支持的文件扩展名" );
    }

    # Compute an ID here
    my $id = compute_id($tempfile);
    $logger->debug("ID of uploaded file is $id");

    # Future home of the file
    my $userdir     = LANraragi::Model::Config->get_userdir;
    my $output_file = $userdir . '/' . $filename;

    #Check if the ID is already in the database, and
    #that the file it references still exists on the filesystem
    my $redis  = LANraragi::Model::Config->get_redis();
    my $isdupe = $redis->exists($id) && -e $redis->hget( $id, "file" );

    # Stop here if file is a dupe.
    if ( -e $output_file || $isdupe ) {

        # Trash temporary file
        unlink $tempfile;

        # The file already exists
        my $msg =
          $isdupe
          ? "该文件已存在于库中。"
          : "库中存在具有相同名称的文件。";

        return ( 0, $id, $filename, $msg );
    }

    # Add the file to the database ourselves so Shinobu doesn't do it
    # This allows autoplugin to be ran ASAP.
    my $name = LANraragi::Utils::Database::add_archive_to_redis( $id, $output_file, $redis );

    # If additional tags were given to the sub, add them now.
    if ($tags) {
        $redis->hset( $id, "tags", redis_encode($tags) );

        # Check for a source: tag, and if it exists amend the urlmap by hand.
        # This is faster than queueing a full recalculation job.
        my @tags = split( /,\s?/, $tags );

        foreach my $t (@tags) {
            remove_spaces($t);
            remove_newlines($t);

            # If the tag is a source: tag, add it to the URL index
            if ( $t =~ /source:(.*)/i ) {
                my $url = $1;
                $logger->debug("Adding $url as an URL for $id");
                trim_url($url);
                $logger->debug("Trimmed: $url");
                $redis->hset( "LRR_URLMAP", $url, $id );    # No need to encode the value, as URLs are already encoded by design
            }
        }
    }

    $redis->quit();

    # Move the file to the content folder.
    # Move to a .tmp first in case copy to the content folder takes a while...
    move( $tempfile, $output_file . ".upload" );

    # Then rename inside the content folder itself to proc Shinobu.
    move( $output_file . ".upload", $output_file );

    unless ( -e $output_file ) {
        return ( 0, $id, $name, "该文件无法移动到您的内容文件夹！" );
    }
    $logger->debug("在新上传的文件上运行自动插件 $id...");

    my ( $succ, $fail, $addedtags, $newtitle ) = LANraragi::Model::Plugins::exec_enabled_plugins_on_file($id);
    my $successmsg = "$succ 插件已成功使用, $fail 插件运行失败, $addedtags 标签已添加. ";

    if ( $newtitle ne "" ) {
        $name = $newtitle;
    }

    if ($catid) {
        $logger->debug("添加上传文件到分类 $catid");

        my ( $catsucc, $caterr ) = LANraragi::Model::Category::add_to_category( $catid, $id );
        if ($catsucc) {
            my %category = LANraragi::Model::Category::get_category($catid);
            my $catname  = $category{name};
            $successmsg .= "添加到分类 '$catname'!";
        } else {
            $successmsg .= "无法添加到分类: $caterr";
        }
    }

    # Invalidate search cache ourselves, Shinobu won't do it since the file is already in the database
    invalidate_cache();

    return ( 1, $id, $name, $successmsg );
}

# Download the given URL, using the given Mojo::UserAgent object.
# This downloads the URL to a temporaryfolder and returns the full path to the downloaded file.
sub download_url {

    my ( $url, $ua ) = @_;

    my $logger = get_logger( "文件上传/下载", "lanraragi" );

    # Download to a temp folder
    die "Not a proper URL" unless $url;
    $logger->info("下载 URL $url...这将需要一些时间。");

    my $tempdir      = tempdir();
    my $tx           = $ua->max_redirects(5)->get($url);
    my $content_disp = $tx->result->headers->content_disposition;
    my $filename     = "Not_an_archive";                            #placeholder;

    $logger->debug("Content-Disposition Header: $content_disp");
    if ( $content_disp =~ /.*filename=\"(.*)\".*/gim ) {
        $filename = $1;
    } elsif ( $content_disp =~ /.*filename\*=UTF-8''(.*)/gim ) {

        # This is an UTF8 filename as per rfc5987.
        # URL-decode to get the full filename.
        $filename = uri_unescape($1);

    } elsif ( $url =~ /([^\/]+)\/?$/gm ) {

        # Fallback to the last element of the URL as the filename.
        $filename = $1;
    }

    $logger->debug("Filename: $filename");
    $tx->result->save_to("$tempdir\/$filename");

    # Update $tempfile to the exact reference created by the host filesystem
    # This is done by finding the first (and only) file in $tempdir.
    my $tempfile = "";
    find(
        sub {
            return if -d $_;
            $tempfile = $File::Find::name;
            $filename = $_;
        },
        $tempdir
    );

    return "$tempdir\/$filename";
}

1;
