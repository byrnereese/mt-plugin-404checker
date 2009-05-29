package LinkChecker::Plugin;
use strict;

use MT::Plugin;
use LWP::Simple;
use URI::Find;

@LinkChecker::Plugin::ISA = qw( MT::Plugin );

sub new {
    my $self = shift;
    $self->SUPER::new(@_) or return;
}

sub init_app {
    my $plugin = shift;
    my ($app) = @_; 
    if ($app->isa('MT::App::CMS')) {
        $app->add_methods(
			  link_check => \&do_check,
			  );
    }
}

sub check_links {
    my $plugin = shift;
    my ($app) = @_;
    $app->{cfg}->AltTemplatePath('plugins/LinkChecker/tmpl');

    my (%param, @message_loop);
    my @ids = $app->param('id');
    my $config = $plugin->get_config_hash;
    my $text = $config->{text};
    my $blog = $app->blog;
    require MT::Entry;
    foreach my $id (@ids) {
	my $iter = MT::Entry->load_iter( { id => $id,
					   blog_id => $blog->id } , undef );
	my $data = build_link_table($app, 
				    iter => $iter,
				    param => \%param 
				    );
	
	use Data::Dumper;
	print STDERR Dumper(%param);
	
	return $app->build_page('linkchecker_check.tmpl',\%param);
    }
}

sub do_check {
    my $app = shift;
    $app->{cfg}->AltTemplatePath('plugins/LinkChecker/tmpl');

    my $q = $app->{query};

    my $blog = $app->blog;
    require MT::Entry;
    my $iter = MT::Entry->load_iter( { blog_id => $blog->id } , undef );
    my %param;
    my $data = build_link_table($app, 
				iter => $iter,
				param => \%param 
				);

    use Data::Dumper;
    print STDERR Dumper(%param);

    $app->build_page('linkchecker_check.tmpl',\%param);
}

sub build_link_table {
    my $app = shift;
    my (%args) = @_;
    my $iter = $args{iter};
    my $param = $args{param} || {};

    my @data;
    while (my $e = $iter->()) {
	print STDERR $e->title() . "\n";
	my $finder = URI::Find->new(sub {
	    my($uri, $orig_uri) = @_;
	    my $row;
	    $row->{uri}      = $orig_uri;
	    $row->{title}    = $e->title();
	    $row->{entry_id} = $e->id();
	    if ( head $uri ) {
		print STDERR "$orig_uri is okay\n";
		$row->{link_status} = "OK";
		$row->{status} = 1;
	    } else {
		print STDERR "$orig_uri cannot be found\n";
		$row->{link_status} = "ERR";
		$row->{status} = 0;
	    }
	    push @data, $row;
	    return $orig_uri;
	});
	$finder->find(\$e->text());
    }
    return [] unless @data;

    $param->{link_table} = 1;
    $param->{object_loop} = \@data;

    \@data;
}

1;
