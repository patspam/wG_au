package wG_au;
# ABSTRACT: Creates the Australian WebGUI translation

use 5.10.0;
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

=head1 DESCRIPTION

Creates an Australian translation from the default WebGUI "English" translation

    wG_au [target_dir]
    
Review with e.g.

    ack -i "'message'.*\bcrikey\b" Australian/

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
    say "Creating language definition $defn";
    # my $share = dist_dir(__PACKAGE__);
    # copy(File::Spec->catfile($share, 'Australian.tmpl'), File::Spec->catfile($to, 'Australian.pm'))
        # or die $!;
    
    # Create the dir that will hold all the translated language files
    mkdir $subdir unless -e $subdir;
    
    # Start with VarCon
    open my $abbc, '<', Lingua::EN::VarCon->abbc_file;
    my $dic;
    while(my $line = $abbc->getline) {
        chop $line;
        my ($us, $au) = split /\t/, $line;
        $dic->{$us} = $au;
    }
    
    # Add extra Australianisms
    $class->add_extras($dic);
    
    # Translate!
    find(sub {
        my $file = $_;
        return unless $file =~ m{\.pm$};
        # return unless $file =~ m/GalleryAlbum/;
        require Path::Class::File->new($file)->absolute;
        my $package = $file;
        $package =~ s{\.pm$}{};
        say "Translating $package..";
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
    
    say "Finished!";
}

sub translate_phrase {
    my ($class, $phrase, $dic) = @_;
    my $orig = $phrase;
    for my $word ($class->words($phrase)) {
        my $trans = $dic->{$word};
        if (defined $trans) {
            $phrase =~ s/\Q$word\E/$trans/;
        }
        
        # Try again to catch Capitalised words
        $trans = $dic->{lcfirst $word};
        if (defined $trans) {
            $phrase =~ s/\Q$word\E/\u$trans/;
        }
    }
    # Uncomment to see alterations
    # say "$orig -> $phrase" if $orig ne $phrase;
    return $phrase;
}

sub add_extras {
    my ($class, $dic) = @_;
    
    my %extras = (
        friend => 'mate',
        friends => 'mates',
        hello => 'gday',
        thanks => 'cheers',
        error => 'crikey',
    );
    @$dic{keys %extras} = values %extras;
}

# Split text into words
sub words {
    my ($class, $input) = @_;
    return split qr{\W+}, $input;
}


1;
