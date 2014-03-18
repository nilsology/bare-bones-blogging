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
my ($sql, $sth);

get '/' => sub {
  $sql = "SELECT post_id, post_title, FROM_UNIXTIME(post_create_date, '%d %b %Y') AS create_date, FROM_UNIXTIME(post_change_date, '%d %b %Y') AS change_date FROM posts WHERE post_public=1 ORDER BY post_create_date DESC LIMIT 5;";
  $sth = database->prepare($sql);
  $sth->execute or die $sth->errstr;
  my @row = $sth->fetchall_arrayref({});
  template 'index', {
    #obviously you should provide an appropriate name here
    page_title => "Nilsology's Weblog",
    row => \@row
  };

};

load 'account_routes.pl', 'login_routes.pl', 'admin_routes.pl', 'blog_routes.pl', 'blog_display.pl', 'page_routes.pl';


true;
