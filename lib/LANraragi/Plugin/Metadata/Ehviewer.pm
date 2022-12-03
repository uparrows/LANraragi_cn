package LANraragi::Plugin::Metadata::Ehviewer;

use strict;
use warnings;
use LANraragi::Utils::Logging qw(get_plugin_logger);
use LANraragi::Utils::Archive qw(is_file_in_archive extract_file_from_archive);
use utf8;
# Meta-information about the plugin.
sub plugin_info {

    return (
        # Standard metadata:
        name        => 'Ehviewer plugin',
        type        => 'metadata',
        namespace   => 'ehviewerplugin',
        login_from  => "ehlogin",
        author      => 'Me',
        version     => '1.0',
        description => '使用从Ehviewer下载的文件中的.ehviewer提供的Gid和Token搜索画廊',
        icon => 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAYAAADE6YVjAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAQXSURBVEhLtZXNT1RnFMbfO5e2YtKmXXXTjRsTV+1CF03T9g+ouybdNKZpHeRrEJgZmC+ZAUEcBgexLahoWpu0VoM1UrAiMiMGRLFKIqO1RsuHJtWmWoR/4Olz3nvvwEwHicYuHt5779x7fu85zzkvSnU0Qmtv0/+jDkr/KfTji5RR6OGL1jNBVirratV4nkxepkzqFbnX4FU8fbZMYjASEXx1ZRSZ+/dwanICKh6GStqQlTLNQuSFPVF81nccoeHTCKd+QSR1Jiu5b+D6Bt/bdLgTJ38dR/rGFFTdNn7XYH2/KkTEl5MjQ5icuYu/Hj/C0PXJrEZ/y2BhYQHrol6YfK97NI30zetQvhKoQBlU+44lkPZoGTAnE8oVD8Fz7Aimpu/CrP4cZs0XMGvd2LgrhMXFRawLV+OlQAW6xy9oiOEvgRnywNhRDTMZYwyRHc8B5UPMZBSVAycwNfMHXDVb9U4NrxuvByvx0dd7UBwoh8tfii6WTiBFPjc2JXfik2/34+19rUsZaUA+xAYJxNPfa0FqCaHWNwexNsjd1rEslFFXiu70IEboSUfqLG7cm0OGevjob7zT2crmIEhnZW28ACQGz0AvMjPTKPaWYE3Zpxi7fQsfdO5GUaCS9a+AUV+G/efPYv7JE5Qe/w6vharwaqgC/YQemxiHavTpJsqCCkGqBn7C4/l5zD18gNkHf/L6H3z4ZRyukEDKdUZdqUGcZzPIvUv8CJbj4NgIzt1kx8W8UDvrLNBqmaz1bsOayi24dOc23t8X1wZrSLBCe5KSgLxW4Sr9rGfUhkgmTX6oloCVTWGIbTwhRm0JNh/sxJvcXZFkEqY3VBc90RB5Fq2FwQ30MJNhB9IShGJHqlZqCWKZZDJFgWRmp+HycdBk5/Wlum038KPiBglYhS56kpaAke0M6tfgnrELGJYBbWYGAhEVgrhsiM5EppllcFFvxXx6Tt6jN0ZEIEPMhMNIPzQk4sGhi4QIWMrkAHbnQCgC3DxWTmUmtemxn09oNfafROJMn574d/e24OMjB5Cm6bfuz2HL0W+gGqqxmXNy6c7vbOVZuHu/t0ACkLMtC5Eu4HHRfO40frw8ZunKRWo8RxviEWznRo5O8LdrEwgN9hFSgzJuRu5/uHoZjYyhWuqh2ghoi+RBRDxllZ9l4pTrw4+taYldJCvPLtm5LpOIpqtdLE0TW5Zl060rAB5PGpDg4ZlTLhtksMMMGpoVg2lJQOkcymCLGjqgGGx5YNADwymRzoKAHIgAnGvpbRkkCSq7lQ6S1QZo6TmwO8gxWaQzIECCt/F4STDOfzJZDhJJcNY8ByBaCZBYDnAyedr/Z4EKSHadBfA6fw5EUiYnA1E7M3BWy4cVALI6pZP6CyQfoD0QgG1yex4gEcW/X0p3UAMSG4wAAAAASUVORK5CYII=',

        # Custom arguments:
        parameters => [
            { type => 'bool', desc => '如果可用，请保存原始日文标题，而不是英文或 ' . '罗马化标题' },
            { type => 'bool', desc => '保存额外的时间戳（发布时间）和上传者元数据' },
            { type => 'bool', desc => '使用 ExHentai 链接作为源而不是 E-Hentai 链接' }
        ],
        oneshot_arg => '输入有效的 EH 库 URL 以将此 EH 库中的元数据复制到此 LANraragi 存档',
        cooldown    => 4
    );
}

# Mandatory function implemented by every plugin.
sub get_tags {

    shift;
    my $lrr_info      = shift;
    my $ua            = $lrr_info->{user_agent};
    my $logger        = get_plugin_logger();
    my $gallery_id    = '';
    my $gallery_token = '';
    my ( $save_jpn_title, $save_additional_metadata, $use_exhentai ) = @_;

    # Use the URL from oneshot parameters or source tag first when applicable.
    if ( $lrr_info->{oneshot_param} =~ /e(?:x|-)hentai\.org\/g\/(\d+)\/([0-9a-z]+)/i ) {
        $gallery_id    = $1;
        $gallery_token = $2;
        $logger->debug("Directly using gallery ID $gallery_id and token $gallery_token from oneshot parameters.");
    } elsif ( $lrr_info->{existing_tags} =~ /source:e(?:x|-)hentai\.org\/g\/(\d+)\/([0-9a-z]+)/i ) {
        $gallery_id    = $1;
        $gallery_token = $2;
        $logger->debug("Directly using gallery ID $gallery_id and token $gallery_token from source tag.");
    } else {

        # Use the gallery ID and token in the filename to directly locate the gallery. Note that the regex does not have
        # "$" at the end, so the filename can have other information attached after the identifiers.

        #获取压缩包内.ehviewer文件
        my $path_in_archive = is_file_in_archive( $lrr_info->{file_path}, ".ehviewer" );

        my $filepath;
        my $delete_after_parse;

        #把.ehviewer从解压包提取出来
        if($path_in_archive) {
            $filepath = extract_file_from_archive( $lrr_info->{file_path}, $path_in_archive );
            $logger->debug("Found file in archive at $filepath");
            $delete_after_parse = 1;
        } else {
            return ( error => "No in-archive .ehviewer file found!" );
        }

        #打开.ehviewer
        open( my $fh, '<:encoding(UTF-8)', $filepath )
            or return ( error => "Could not open $filepath!" );

        #读取.ehviewer第三行和第四行的画廊Gid和Token
        while( <$fh> ) {
            if( $. == 3 ) {
                $gallery_id = $_;
                chomp $gallery_id;

                $logger->debug("Gid:" . $gallery_id);
            }elsif( $. == 4 ) {
                $gallery_token = $_;
                chomp $gallery_token;

                $logger->debug("Gtoken:" . $gallery_token);
                last;
            }
        }

        #删除解压的文件
        if ($delete_after_parse){
            unlink $filepath;
        }

        if ( $gallery_id eq '' || $gallery_token eq '' ) {
            my $file_error = 'Skipping archive without connecting to EH, because the archive title does not have valid '
              . 'gallery identifiers from Mayriad\'s EH Master Script.';
            $logger->error($file_error);
            return ( error => $file_error );
        }
    }

    # Retrieve metadata directly using EH API.
    $logger->info('Source identified. Calling E-Hentai metadata plugin to retrieve metadata from EH API.');
    my ( $eh_all_tags, $eh_title ) = LANraragi::Plugin::Metadata::EHentai::get_tags_from_EH( $ua, $gallery_id,
        $gallery_token, $save_jpn_title, $save_additional_metadata );

    # Add source URL and title if possible.
    if ( $eh_all_tags ne "" ) {

        # Title is always updated to hide the identifiers and also to reflect title changes due to rename petitions.
        my %metadata = ( tags => $eh_all_tags, title => $eh_title );

        # Add the source tag outside get_tags_from_EH(), so that this tag is only added when metadata has been
        # successfully retrieved; otherwise $metadata{tags} may only contain this source tag and truly untagged
        # galleries may be incorrectly hidden.
        my $host = ( $use_exhentai ? 'exhentai.org' : 'e-hentai.org' );
        $metadata{tags} .= ", source:$host/g/$gallery_id/$gallery_token";

        # Return a hash containing the new metadata to be added to LRR.
        return %metadata;
    } else {
        my $source_error = 'No matching EH gallery found. The archive title may have incorrect gallery identifiers.';
        $logger->error($source_error);
        return ( error => $source_error );
    }

}

1;
