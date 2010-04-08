use strict;
use warnings;

use wG_au;
use Test::More tests => 2;
use File::Temp;
use Test::File;

my $dir = File::Temp->newdir;
warn File::Spec->catfile($dir, 'Australian.pm');
wG_au->translate('/data/WebGUI', $dir);
file_exists_ok(File::Spec->catfile($dir, 'Australian.pm'));
file_exists_ok(File::Spec->catfile($dir, 'Australian', 'Workflow.pm'));
