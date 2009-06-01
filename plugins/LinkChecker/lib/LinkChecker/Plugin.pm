package LinkChecker::Plugin;
use strict;

use LWP::Simple;
use HTML::SimpleLinkExtor;
use Carp qw( croak );

sub check_links {
    my $app = shift;
    my ($param) = @_;
    my $q = $app->{query};
    require MT::Blog;
    my $blog = MT::Blog->load($q->param('blog_id'));

    $param ||= {};

    my (@message_loop);
    my @ids = $app->param('id');
    my $blog = $app->blog;
    require MT::Entry;
    foreach my $id (@ids) {
#	my $iter = MT::Entry->load_iter( { id => $id,
#					   blog_id => $blog->id } , undef );
#	my $data = build_link_table($app, 
#				    iter => $iter,
#				    param => $param 
#				    );
#	return $app->load_tmpl( 'link_check.tmpl', $param );
    }
}

sub do_check {
    my $app = shift;
    my $q = $app->{query};

    my $blog = $app->blog;
    require MT::Entry;

    my $iter = MT::Entry->load_iter( { blog_id => $blog->id } );
    my %param;
    my $data = build_link_table($app, 
				iter => $iter,
				param => \%param 
				);

    return $app->load_tmpl( 'link_check.tmpl', \%param );
}

sub itemset_handler {
    my ($app) = @_;
    $app->validate_magic or return;
    my $blog = $app->blog;

    require MT::Entry;
    my @ids = $app->param('id');
    my $iter = MT::Entry->load_iter( { id => \@ids } );

    my %param;
    my $data = build_link_table($app, 
				iter => $iter,
				param => \%param 
				);
    $param{link_data} = $data;
    $param{ids} = join(',',@ids);
    return $app->load_tmpl( 'link_check.tmpl', \%param );
}

sub build_link_table {
    my $app = shift;
    my (%args) = @_;
    my $iter = $args{iter};
    my $param = $args{param} || {};

    my @data;

    while (my $e = $iter->()) {
	# TODO - run entry through its text formatter 
	my $extor = HTML::SimpleLinkExtor->new();
        $extor->parse( MT->apply_text_filters($e->text, $e->text_filters) );
        $extor->parse( MT->apply_text_filters($e->text_more, $e->text_filters) );

	foreach my $type (qw(img frame area base href)) {
	    my @links = $extor->$type();
	    foreach my $link (@links) {
		my $row;
		$row->{type}     = $type;
		$row->{uri}      = $link;
		$row->{title}    = $e->title();
		$row->{entry_id} = $e->id();
		if ( head $link ) {
		    $row->{link_status} = "OK";
		    $row->{status} = 1;
		} else {
		    $row->{link_status} = "ERR";
		    $row->{status} = 0;
		}
		push @data, $row;# unless $row->{status};
	    }
	}
    }
    return [] unless @data;

    $param->{link_table} = 1;
    $param->{object_loop} = \@data;

    \@data;
}

1;
