#!/usr/bin/perl -w

package MT::Plugin::Elise;

use LinkChecker::Plugin;
use strict;
use MT;

use vars qw( $VERSION $plugin %cfg $DEBUG );
$VERSION = '1.0';
$DEBUG = 0;

eval {
    $plugin = new LinkChecker::Plugin({
	name            => 'Elise',
        version         => $VERSION,
	author_name     => "Byrne Reese",
	author_link     => "http://www.majordojo.com/",
	plugin_link     => "http://www.majordojo.com/projects/LinkChecker/",
	description     => '"Elise" is a link checker for Movable Type blogs. This plugins helps keep your blog up to date by helping you to keep links current.",
    });
    MT->add_plugin($plugin);
};

MT->add_itemset_action({type => 'entry',
			key => "check_links",
			label => "Validate Links",
			code => sub { $plugin->check_links(@_) },
			});

1;
