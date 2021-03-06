#!/usr/bin/perl

use Dancer ':syntax';
use Dancer::Plugin::Database;
use CGI;
use Crypt::SaltedHash;
use Data::UUID;
use DBI;
use POSIX qw(strftime);
use MIME::Lite;
#use Text::MultiMarkdown 'markdown';
use Text::Markdown::Hoedown;
use DR::SunDown;
use strict;
use warnings;

#Just in case
our ($error_msg, $sth, $sql);

# until `prefix undef;` all routes are prefixed with /blog
prefix '/blog';
  
get '/archive' => sub {
  $sql = "SELECT post_id, post_title, FROM_UNIXTIME(post_create_date, '%d %b %Y') AS create_date, FROM_UNIXTIME(post_change_date, '%d %b %Y') AS change_date FROM posts WHERE post_public=1 ORDER BY post_create_date DESC;";
  $sth = database->prepare($sql);
  $sth->execute or die $sth->errstr;
  my @row = $sth->fetchall_arrayref({});
  template 'blog_archive', {
    page_title => 'Posts Archive',
    row => \@row
  };
};

get '/post/:post_id' => sub {
  if ( session('user') ) {
  $sql = "SELECT post_id, post_title, FROM_UNIXTIME(post_create_date, '%d %b %Y') AS create_date, FROM_UNIXTIME(post_change_date, '%d %b %Y') AS change_date, post_text FROM posts WHERE post_id=?;";
  } else {
  $sql = "SELECT post_id, post_title, FROM_UNIXTIME(post_create_date, '%d %b %Y') AS create_date, FROM_UNIXTIME(post_change_date, '%d %b %Y') AS change_date, post_text FROM posts WHERE post_public=1 and post_id=?;";
  }
  $sth = database->prepare($sql);
  $sth->execute(params->{'post_id'}) or die $sth->errstr;
  my @row = $sth->fetchall_arrayref({});
  my $text = database->quick_lookup('posts', { post_id => params->{'post_id'} }, 'post_text');
  my $html = markdown($text);
#  my $html = markdown2html($text);
  my $list = markdown_toc($text);
  my $tags = '';
  $sql = "SELECT tag_slug, tags.tag_id FROM tags JOIN tags_posts ON post_id = ? AND tags_posts.tag_id = tags.tag_id;";
  $sth = database->prepare($sql);
  $sth->execute(params->{'post_id'}) or die $sth->errstr;
  my @tags = $sth->fetchall_arrayref({});
  my $title = database->quick_lookup('posts', { post_id => params->{'post_id'} }, 'post_title');
  template 'post_single', {
    row => \@row,
    text => $html,
    list => $list,
    tags => \@tags,
    page_title => $title
  };
};

get '/tag/:tag_id' => sub {
  my $tag_slug = database->quick_lookup('tags', { tag_id => params->{'tag_id'} }, 'tag_slug');
  $sql = "SELECT posts.post_id, post_title, FROM_UNIXTIME(post_create_date, '%d %b %Y') AS create_date, FROM_UNIXTIME(post_change_date, '%d %b %Y') AS change_date FROM posts JOIN tags_posts ON tag_id = ? AND tags_posts.post_id = posts.post_id AND post_public = 1 ORDER BY posts.post_id DESC;";
  $sth = database->prepare($sql);
  $sth->execute(params->{'tag_id'}) or die $sth->errstr;
  my @posts = $sth->fetchall_arrayref({});
  template 'tag_single', {
    page_title => "Posts associated with &raquo;$tag_slug&laquo;",
    row => \@posts
  };
};

get '/archive/rss' => sub {
  content_type 'application/rss+xml';
  $sql = "SELECT post_text, post_id, post_title, FROM_UNIXTIME(post_create_date, '%a, %d %b %Y %T') AS create_date FROM posts WHERE post_public=1 ORDER BY post_create_date DESC;";
  $sth = database->prepare($sql);
  $sth->execute or die $sth->errstr;
  #convert markdown_text to html -> rss friendly
  my $row = $sth->fetchall_arrayref({});
  my @posts = ();
  my ($post_text, $post_title, $post_id, $create_date);
  foreach my $res (@$row) {
    $post_text = "<![CDATA[".markdown($res->{post_text})."]]>"; 
    $post_title = $res->{post_title};
    $create_date = $res->{create_date}." GMT";
    $post_id = $res->{post_id};
    my %row = ( post_id => $post_id, create_date => $create_date, post_text => $post_text, post_title => $post_title );
    push ( @posts, \%row );
  } 
  $sql = "SELECT MAX(post_change_date), MAX(FROM_UNIXTIME(post_change_date, '%a, %d %b %Y %T')), MAX(post_create_date), MAX(FROM_UNIXTIME(post_create_date, '%a, %d %b %Y %T')) FROM posts LIMIT 1;";
  $sth = database->prepare($sql);
  $sth->execute or die $sth->errstr;
  my @date = $sth->fetchrow_array;
  my $lastBuildDate;
  if ( $date[0] > $date[2] ) {
    $lastBuildDate = $date[1]." GMT";
  } else {
    $lastBuildDate = $date[3];
  }
  template 'rss_archive', {
    row => \@posts,
    lastBuildDate => $lastBuildDate
  }, { layout => 0 };
};

get '/archive/atom' => sub {
  content_type 'application/atom+xml';
  $sql = "SELECT post_text, post_id, post_title, FROM_UNIXTIME(post_change_date, '%Y-%m-%dT%TZ') AS update_date, FROM_UNIXTIME(post_create_date, '%Y-%m-%dT%TZ') AS create_date FROM posts WHERE post_public=1 ORDER BY post_create_date DESC;";
  $sth = database->prepare($sql);
  $sth->execute or die $sth->errstr;
  #convert markdown_text to html -> rss friendly
  my $row = $sth->fetchall_arrayref({});
  my @posts = ();
  my ($post_text, $post_title, $post_id, $create_date, $change_date);
  foreach my $res (@$row) {
    $post_text = markdown($res->{post_text}); 
    $post_title = $res->{post_title};
    $create_date = $res->{create_date};
    $change_date = $res->{update_date};
    $post_id = $res->{post_id};
    my %row = ( post_id => $post_id, create_date => $create_date, change_date => $change_date, post_text => $post_text, post_title => $post_title );
    push ( @posts, \%row );
  } 
  $sql = "SELECT MAX(post_change_date), MAX(FROM_UNIXTIME(post_change_date, '%Y-%m-%dT%TZ')), MAX(post_create_date), MAX(FROM_UNIXTIME(post_create_date, '%Y-%m-%dT%TZ')) FROM posts LIMIT 1;";
  $sth = database->prepare($sql);
  $sth->execute or die $sth->errstr;
  my @date = $sth->fetchrow_array;
  my $lastBuildDate;
  if ( $date[0] > $date[2] ) {
    $lastBuildDate = $date[1];
  } else {
    $lastBuildDate = $date[3];
  }
  template 'atom_archive', {
    row => \@posts,
    lastBuildDate => $lastBuildDate
  }, { layout => 0 };
};

# unset the prefix /blog
prefix undef;
