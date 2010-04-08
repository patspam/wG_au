package wG_au;
# ABSTRACT: Creates the Australian WebGUI translation

use warnings;
use strict;
use Path::Class;
use File::Spec;
use File::Slurp;
use File::ShareDir qw(dist_dir);
use File::Copy;
use File::Find;
use Perl::Tidy;
use autodie;
use Data::Dumper;
use Lingua::EN::VarCon;
use Lingua::EN::Splitter qw(words);

=head1 DESCRIPTION

Creates an Australian translation from the default WebGUI "English" translation

    wG_au [target_dir]

=cut

sub translate {
    my ($class, $root, $to) = @_;
    
    # Create sub-folder
    
    my $subdir = File::Spec->catfile($to, 'Australian');
    my $i18n = File::Spec->catfile($root, 'lib/WebGUI/i18n/');
    my $en = File::Spec->catfile($i18n, 'English');
    my $now = time;
    
    # Create the Language definition file
    my $defn = File::Spec->catfile($to, 'Australian.pm');
    print "Creating language definition $defn\n";
    my $share = dist_dir(__PACKAGE__);
    copy(File::Spec->catfile($share, 'Australian.tmpl'), File::Spec->catfile($to, 'Australian.pm'))
        or die $!;
    
    # Create the dir that will hold all the translated language files
    mkdir $subdir unless -e $subdir;
    
    open my $abbc, '<', Lingua::EN::VarCon->abbc_file;
    my $dic;
    while(my $line = $abbc->getline) {
        chop $line;
        my ($us, $au) = split /\t/, $line;
        $dic->{$us} = $au;
    }
    
    # Translate!
    find(sub {
        my $file = $_;
        return unless $file =~ m{\.pm$};
        require Path::Class::File->new($file)->absolute;
        my $package = $file;
        $package =~ s{\.pm$}{};
        print "Translating $package..\n";
        my $i = eval "\$WebGUI::i18n::English::${package}::I18N";
        for my $v (values %$i) {
            $v->{lastUpdated} = $now;
            $v->{message} = $class->translate_phrase($v->{message}, $dic);
        }
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Sortkeys = 1;
        my $dump = Dumper($i);
        my $t = File::Spec->catdir($subdir, $file);
        
        my $contents = <<"END_CONTENTS";
package WebGUI::i18n::Australian::$package;
# ABSTRACT: Australian WebGUI (auto) Translation
use strict;
our \$I18N = $dump;
1;
END_CONTENTS
        Perl::Tidy::perltidy( source => \$contents, destination => $t);
    }, $en);
    
    print "Finished!\n";
}

sub translate_phrase {
    my ($class, $phrase, $dic) = @_;
    my $orig = $phrase;
    for my $word (@{words($phrase)}) {
        my $trans = $dic->{$word};
        if (defined $trans) {
            $phrase =~ s/\Q$word\E/$trans/;
        }
    }
    # Uncomment to see alterations
    # print "$orig -> $phrase" if $orig ne $phrase;
    return $phrase;
}

1;
