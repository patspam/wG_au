package wG_au::Cmd;
# ABSTRACT: App::Cmd::Simple wG_au CLI

use warnings;
use strict;
use base qw(App::Cmd::Simple);
use wG_au;
use Cwd;
use Path::Class;
use File::Spec;

sub root_fallback { $ENV{WEBGUI_ROOT} || '/data/WebGUI' }

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $dir = Path::Class::Dir->new($args->[0] || $self->root_fallback);
    $self->usage_error("Directory not found: $dir") if !-e $dir;
    $self->usage_error("Does not look like the WebGUI root: $dir") 
        if !-e File::Spec->catfile($dir, 'lib', 'WebGUI.pm');
}
  
sub execute {
    my ( $self, $opt, $args ) = @_;

    my $root = Path::Class::Dir->new($args->[0] || $self->root_fallback);
    my $to = Path::Class::Dir->new(getcwd);
    print "Creating Australian translation (source: $root, target: $to)\n";
    
    wG_au->translate($root, $to);
}

1;
