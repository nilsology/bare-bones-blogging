package blog;
use Dancer ':syntax';
use Dancer::Plugin::RequireSSL;
#use Dancer::Plugin::ProxyPath;
use Dancer::Plugin::Database;
use CGI;
use Crypt::SaltedHash;
use Data::UUID;
use DBI;
use POSIX qw(strftime);
use MIME::Lite;
use strict;
use warnings;

our $VERSION = '0.1';
set behind_proxy => true;
require_ssl();
#my $external_path = proxy->uri_for("/admin/blog/posts/overview");
#
get '/' => sub {
    template 'index', {
      posts_overview => "/admin/blog/posts/overview"
    };
};

load 'account_routes.pl', 'login_routes.pl', 'admin_routes.pl', 'blog_routes.pl', 'blog_display.pl', 'page_routes.pl';


true;
