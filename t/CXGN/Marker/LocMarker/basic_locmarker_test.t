#!/usr/bin/perl 
use strict;
use Test::More 'no_plan';
use CXGN::DB::Connection;
use CXGN::Marker::LocMarker;
use CXGN::Marker::Search;
# use Test::Pod; # should test the pod eventually

my $dbh = CXGN::DB::Connection->new();

for (0..200){ # test a few times
  
  my $msearch = CXGN::Marker::Search->new($dbh);
  $msearch->must_be_mapped();
  $msearch->has_subscript();
  $msearch->random();
  #$msearch->marker_id(518);
  $msearch->perform_search();
##  diag("search finished, creating locations\n");
  my ($loc) = $msearch->fetch_location_markers();
##  diag("finished creating locations\n");


  isa_ok($loc, 'CXGN::Marker::LocMarker');
  
#  use Data::Dumper;
#  diag(Dumper $loc->{loc});
  
  my $loc_id = $loc->location_id();
  ok($loc_id, "loc_id is $loc_id");
  
  my $chr = $loc->chr();
  ok($chr > 0, "chromosome = $chr");
  
  my $pos = $loc->position();
ok($pos >= 0 , "position = $pos");
  
  my $sub = $loc->subscript();
  ok($sub =~ /^[ABC]$/i, "subscript = $sub");
  
  my $conf = $loc->confidence();
  ok($conf =~ /I|LOD|uncalc/, "confidence = $conf");
  
  my $mv = $loc->map_version();
  ok($mv > 0, "map version = $mv");
  
  my $map = $loc->map_id();
  ok($map > 0, "map_id = $map");
  
}
















