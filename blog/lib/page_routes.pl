#!/usr/bin/perl

use Dancer ':syntax';
use Dancer::Plugin::Database;
use CGI;
use Crypt::SaltedHash;
use Data::UUID;
use DBI;
use POSIX qw(strftime);
use MIME::Lite;
use Text::Markdown::Hoedown;
use DR::SunDown;
use strict;
use warnings;

get '/about' => sub {
  template 'pages/about', {
    page_title => 'About' 
  };
};

get '/about/new' => sub {
  template 'pages/about_2', {
    page_title => 'About (Test)'
  }
};

get '/gallery' => sub {
  template 'pages/gallery', {
    page_title => 'Gallery' 
  };
};

get '/gallery/new' => sub {
  template 'pages/gallery_2', {
    page_title => 'Gallery' 
  };
};

get '/impress' => sub {
  template 'pages/impress', {
    page_title => 'Impress'
  }
};
