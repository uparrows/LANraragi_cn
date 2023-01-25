package LANraragi::Plugin::Metadata::MEMS;
use utf8;
use strict;
use warnings;
use LANraragi::Utils::Logging qw(get_plugin_logger);

# Meta-information about the plugin.
sub plugin_info {

    return (
        # Standard metadata:
        name        => 'Mayriad\'s EH Master Script',
        type        => 'metadata',
        namespace   => 'memsplugin',
        login_from  => "ehlogin",
        author      => 'Mayriad',
        version     => '1.1.1',
        description => '使用附加到 的标识符准确地从 e-hentai.org 检索元数据 '
          . '下载档案的文件名通过 Mayriad\'s EH 的主脚本提供.',
        icon => 'data:image/png;base64,AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAAAAAAAAAAAAA'
          . 'AAAAAAAAAD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD'
          . '///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wARBmb/EQZm/xEGZv8RBmb/EQZm/'
          . '////wD///8A////ABEGZv8RBmb/////AP///wARBmb/EQZm/////wD///8AEQZm/xEGZv8RBmb/EQZm/xEGZv////8A////AP///wARBmb'
          . '/EQZm/////wD///8AEQZm/xEGZv////8A////ABEGZv8RBmb/////AP///wD///8A////AP///wD///8AEQZm/xEGZv////8A////ABEGZ'
          . 'v8RBmb/////AP///wARBmb/EQZm/////wD///8A////AP///wD///8A////ABEGZv8RBmb/////AP///wARBmb/EQZm/////wD///8AEQZ'
          . 'm/xEGZv////8A////AP///wD///8A////AP///wARBmb/EQZm/////wD///8AEQZm/xEGZv////8A////ABEGZv8RBmb/EQZm/xEGZv///'
          . '/8AEQZm/xEGZv////8AEQZm/xEGZv8RBmb/EQZm/xEGZv8RBmb/////AP///wARBmb/EQZm/xEGZv8RBmb/////ABEGZv8RBmb/////ABE'
          . 'GZv8RBmb/EQZm/xEGZv8RBmb/EQZm/////wD///8AEQZm/xEGZv////8A////AP///wD///8A////AP///wARBmb/EQZm/////wD///8AE'
          . 'QZm/xEGZv////8A////ABEGZv8RBmb/////AP///wD///8A////AP///wD///8AEQZm/xEGZv////8A////ABEGZv8RBmb/////AP///wA'
          . 'RBmb/EQZm/////wD///8A////AP///wD///8A////ABEGZv8RBmb/////AP///wARBmb/EQZm/////wD///8AEQZm/xEGZv8RBmb/EQZm/'
          . 'xEGZv////8A////AP///wARBmb/EQZm/////wD///8AEQZm/xEGZv////8A////ABEGZv8RBmb/EQZm/xEGZv8RBmb/////AP///wD///8'
          . 'AEQZm/xEGZv////8A////ABEGZv8RBmb/////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///'
          . 'wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A//8'
          . 'AAP//AACDmQAAg5kAAJ+ZAACfmQAAn5kAAISBAACEgQAAn5kAAJ+ZAACfmQAAg5kAAIOZAAD//wAA//8AAA==',

        # Custom arguments:
        parameters => [
            {   type => 'bool',
                desc => '如果可用，请保存原始日文标题，而不是英文或 ' . '罗马化标题'
            },
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
        ( $gallery_id, $gallery_token ) = ( $lrr_info->{archive_title} =~ /.+? \[GID (\d+) GT ([0-9a-z]+)\]/ );
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
