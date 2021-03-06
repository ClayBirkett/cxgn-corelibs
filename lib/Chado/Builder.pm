# $Id: Builder.pm,v 1.34 2007/02/20 16:23:53 briano Exp $
package Chado::Builder;
# vim: set ft=perl ts=2 expandtab:

use strict;
use base 'Module::Build';
use Carp;
use Data::Dumper;
use File::Spec::Functions 'catfile';
use File::Path;
use File::Copy;
use Data::Dumper;
use Template;
use XML::Simple;
use LWP::Simple qw(mirror is_success status_message);
use Log::Log4perl;
use DBI;
Log::Log4perl::init('load/etc/log.conf');
no warnings;

=head1 ACTIONS

= item prepdb()

Calls the psql command and pipes in the contents of the 
load/etc/initialize.sql file.  Put any insert statements that
your data load needs here.

=item ncbi()

Load action for all NCBI data.

=item mageml()

fixfixfix

=item ontologies()

loads ontologies by running gmod_load_ontology.pl on all files in
$(DATA)/ontology

=item tokenize()

processes templates specified in configuration file, filling in
platform-specific variable values

=item _last

=cut

=head2 ACTION_prepdb

 Title   : ACTION_prepdb
 Usage   :
 Function: Executes any SQL statements in the load/etc/initialize.sql file.
 Example :
 Returns : 
 Args    :

=cut

sub ACTION_prepdb {
  # the build object $m
  my $m = shift;
  # the XML config object
  my $conf = $m->conf;

  $m->log->info("entering ACTION_prepdb");

  my $db_name   = $conf->{'database'}{'db_name'}  || '';
  my $db_host   = $conf->{'database'}{'db_host'}  || '';
  my $db_port   = $conf->{'database'}{'db_port'}  || '';
  my $db_user   = $conf->{'database'}{'db_username'}  || '';
  my $build_dir = $conf->{'build'}{'working_dir'} || '';
  my $init_sql  = catfile( $build_dir, 'load', 'etc', 'initialize.sql' );
  my $sys_call  = "psql -h $db_host -p $db_port -U $db_user -f $init_sql $db_name";

  $m->log->debug("system call: $sys_call");

  system( $sys_call ) == 0 or croak "Error executing '$sys_call': $?";

  $m->log->info("leaving ACTION_prepdb");
}

=head2 ACTION_ncbi

 Title   : ACTION_ncbi
 Usage   :
 Function: Load action for all NCBI data.
 Example :
 Returns :
 Args    :

=cut
sub ACTION_ncbi {
  # the build object $m
  my $m = shift;
  # the XML config object
  my $conf = $m->conf;

  $m->log->info("entering ACTION_ncbi");

  # print out the available refseq datasets
  my %ncbis = printAndReadOptions($m,$conf,"ncbi");

  # now that I know what you want mirror files and load
  # fetchAndLoadFiles is called for each possible type
  # but only actively loaded for those the user selects
  fetchAndLoadFiles($m, $conf, "refseq", "./load/bin/load_gff3.pl --organism Human --srcdb DB:refseq --gfffile", \%ncbis);
  fetchAndLoadFiles($m, $conf, "locuslink", "./load/bin/load_locuslink.pl", \%ncbis);
  $m->log->info("leaving ACTION_ncbi");
}

sub ACTION_mageml {
  my $m    = shift;
  my $conf = $m->conf;

  $m->log->info("entering ACTION_mageml");

  print "Available MAGE-ML annotation files:\n";

  my $i  = 1;
  my %ml = ();
  foreach my $mageml ( sort keys %{ $conf->{mageml} } ) {
    $ml{$i} = $mageml;
    print "[$i] $mageml\n";
    $i++;
  }
  print "\n";

  my $chosen = $m->prompt(
                          "Which ontologies would you like to load (Comma delimited)? [0]"
                         );
  $m->notes( 'affymetrix' => $chosen );

  my %mageml = map { $ml{$_} => $conf->{mageml}{ $ml{$_} } } split ',', $chosen;

  foreach my $mageml ( keys %mageml ) {
    print "fetching files for $mageml\n";

    my $load = 0;
    foreach my $file ( @{ $mageml{$mageml}{file} } ) {

      my $fullpath = catfile $conf->{path}{data}, $file->{local};
      $fullpath =~ s!^(.+)/[^/]*!$1!;

      unless ( -d $fullpath ) {
        $m->log->debug("mkpath $fullpath");
        mkpath( $fullpath, 0, 0711 )
          or print "Couldn't make path '$fullpath': $!\n";
      }

      print "  +", $file->{remote}, "\n";
      $load = 1 if $m->_mirror( $file->{remote}, $file->{local} );
      $load = 1 unless $m->_loaded( $fullpath );

      next unless $load;

      print "    loading...";

      my $sys_call = "./load/bin/load_affymetrix.pl $fullpath";
      $m->log->debug( "system call: $sys_call" );

      my $result = system( $sys_call );
      if ( $result != 0 ) { 
        die "failed: $!\n";
      }
      else {
        $m->_loaded( $fullpath, 1 );
        print "done!\n";
      }
    }
  }

  $m->log->info("leaving ACTION_mageml");
}

sub ACTION_ontologies {
  my $m    = shift;
  my $conf = $m->conf;

  my $db_name   = $conf->{'database'}{'db_name'}  || '';
  my $db_host   = $conf->{'database'}{'db_host'}  || '';
  my $db_port   = $conf->{'database'}{'db_port'}  || '';
  my $db_user   = $conf->{'database'}{'db_username'}  || '';
  my $db_pass   = $conf->{'database'}{'db_password'}  || '';

  $db_pass = '' if (ref $db_pass eq 'HASH');

  $m->log->info("entering ACTION_ontologies");

  print "Available ontologies:\n";

  my %ont = ();
  foreach my $ontology ( keys %{ $conf->{ontology} } ) {
    $ont{ $conf->{ontology}->{$ontology}->{order} } = $ontology;
  }
  foreach my $key ( sort {$a <=> $b} keys %ont ) { print "[$key] ", $ont{$key}, "\n"; }
  print "\n";

  my $chosen = $m->prompt("Which ontologies would you like to load (Comma delimited)? [0]");
  $m->notes( 'ontologies' => $chosen );

  my %ontologies = map { $_ => $conf->{ontology}{ $ont{$_} } } split ',',
    $chosen;

  foreach my $ontology ( sort {$a <=> $b} keys %ontologies ) {
    print "fetching files for ", $ont{$ontology}, "\n";

    my $file = $ontologies{$ontology}{file};

    my $load = 0;
    foreach my $file ( 
      grep { $_->{type} eq 'definitions' } @{ $ontologies{$ontology}{file} }
    ) {
      my $fullpath = catfile($conf->{path}{data}, $file->{local});
      $fullpath =~ s!^(.+)/[^/]*!$1!;
      unless ( -d $fullpath ) {
        $m->log->debug("mkpath $fullpath");
        mkpath( $fullpath, 0, 0711 )
          or print "Couldn't make path '$fullpath': $!\n";
      }
      if ($file->{method} =~ /mirror/) {
        print "  +", $file->{remote}, "\n";
        $load = 1 if $m->_mirror( $file->{remote}, $file->{local} ); 
      }
      else { # it is a local file
        copy( $file->{remote} , $fullpath );
        $load = 1;
      }
    }

    my ($deffile) =
      grep { $_ if $_->{type} eq 'definitions' }
      @{ $ontologies{$ontology}{file} };

    foreach my $file (
      grep { ($_->{type} eq 'ontology') or ($_->{type} eq 'obo') } @{ $ontologies{$ontology}{file} }
    ) {
      my $fullpath = catfile($conf->{path}{data}, $file->{local});
      $fullpath =~ s!^(.+)/[^/]*!$1!;
      unless ( -d $fullpath ) {
        $m->log->debug("mkpath $fullpath");
        mkpath( $fullpath, 0, 0711 )
          or print "Couldn't make path '$fullpath': $!\n";
      }

      print "  +", $file->{remote}, "\n";

      if ($file->{method} =~ /mirror/) {
        $load = 1 if $m->_mirror( $file->{remote}, $file->{local} );
      }
      else { #local file
        copy( $file->{remote}, $fullpath );
        $load = 1; 
      }

      next unless $load;

      print "    loading...";

#      my $sys_call = join( ' ', 
#        './load/bin/gmod_load_ontology.pl',
#        catfile( $conf->{'path'}{'data'}, $file->{'local'} ),
#        catfile( $conf->{'path'}{'data'}, $deffile->{'local'} )
#      );


      #creating chadoxml from either obo or ontology files
      my $sys_call;
      if ($file->{type} eq 'obo') {
        $sys_call = join( ' ',
           'go2fmt.pl -p obo_text -w xml',
           catfile( $conf->{'path'}{'data'}, $file->{'local'}),
           '| go-apply-xslt oboxml_to_chadoxml - >',
           catfile( $conf->{'path'}{'data'}, $file->{'local'}.'xml')
        );
      } elsif ($file->{type} eq 'ontology') {
        $sys_call = join( ' ',
           'go2fmt.pl -p go_ont -w xml',
           catfile( $conf->{'path'}{'data'}, $file->{'local'}),
           '| go-apply-xslt oboxml_to_chadoxml - >',
           catfile( $conf->{'path'}{'data'}, $file->{'local'}.'xml')
        );
      } else {
        die "what kind of file is ".$_->{type}."?";
      }

      $m->log->debug( "system call: $sys_call" );

      my $result = system( $sys_call );

      if ( $result != 0 ) {
        print "System call '$sys_call' failed: $?\n";
        $m->log->fatal("failed: $?");
        die;
      }

      # loading chadoxml
      my $stag_string = "stag-storenode.pl -d 'dbi:Pg:dbname=$db_name;host=$db_host;port=$db_port'";
      $stag_string .= " --user $db_user " if $db_user;
      $stag_string .= " --password $db_pass " if $db_pass;
      $sys_call = join( ' ',
        $stag_string,
        catfile( $conf->{'path'}{'data'}, $file->{'local'}.'xml')
      ); 

      $m->log->debug( "system call: $sys_call" );

      $result = system( $sys_call );

      if ( $result != 0 ) {
        print "System call '$sys_call' failed: $?\n";
        $m->log->fatal("failed: $?");
        die;
      }

      if ($deffile) {
        $sys_call = join( ' ',
          'go2fmt.pl -p go_def -w xml',
          catfile( $conf->{'path'}{'data'}, $deffile->{'local'}),
          '|  go-apply-xslt oboxml_to_chadoxml - >',
          catfile( $conf->{'path'}{'data'}, $deffile->{'local'}.'xml')
        );

        $m->log->debug( "system call: $sys_call" );

        $result = system( $sys_call );

        if ( $result != 0 ) {
          print "System call '$sys_call' failed: $?\n";
          $m->log->fatal("failed: $?");
          die;
        }


        $sys_call = join( ' ',
          "stag-storenode.pl -d 'dbi:Pg:dbname=$db_name;host=$db_host;port=$db_port'",
          catfile( $conf->{'path'}{'data'}, $deffile->{'local'}.'xml')
        );

        $m->log->debug( "system call: $sys_call" );

        $result = system( $sys_call );

      }

      if ( $result != 0 ) {
        print "System call '$sys_call' failed: $?\n";
        $m->log->fatal("failed: $?");
        die;
      }
      else {
        $m->_loaded( catfile($conf->{'path'}{'data'}, $file->{'local'}), 1 );
        $m->_loaded( catfile($conf->{'path'}{'data'}, $deffile->{'local'}), 1 ) if $deffile;
        print "done!\n";
        $m->log->debug("done!");
      }
    }
  }

  #fix up DBIx::DBStag stomping on part_of and derives_from
  $m->log->debug("fix up DBIx::DBStag stomping on part_of and derives_from");
  my $dbh = DBI->connect("dbi:Pg:dbname=$db_name;host=$db_host;port=$db_port",
                         $db_user, $db_pass);
  $dbh->do("UPDATE cvterm SET 
                     cv_id = (SELECT cv_id FROM cv WHERE name='relationship')
                     WHERE name='derives_from'"); 
  $dbh->do("UPDATE cvterm SET
                     cv_id = (SELECT cv_id FROM cv WHERE name='relationship')
                     WHERE name='part_of'");
  $dbh->disconnect;

  $m->log->info("leaving ACTION_ontologies");
}

sub ACTION_tokenize {
  my $m    = shift;
  my $conf = $m->conf;

  $m->log->info('entering ACTION_tokenize');

  my $template = Template->new(
    {
      INTERPOLATE => 0,
      RELATIVE    => 1,
    }
  ) || ( $m->log->fatal("Template error: $Template::ERROR") and die );

  foreach my $templatefile ( keys %{ $conf->{template}{file} } ) {

    #there is an order of preference in which keys are added.
    #this affects which config sections clobber which others, beware.
    my $tokens = {%{$conf->{database}}, %{$conf->{build}}};

    if(ref($conf->{template}{file}{$templatefile}) eq 'HASH'){
      $tokens->{ $_ } = $conf->{template}{file}{$templatefile}{$_} foreach keys %{ $conf->{template}{file}{$templatefile}};
    }

    #knock out empty hashes (like undef db_password)
    foreach my $token (keys %{$tokens}){
      undef($tokens->{$token}) if(ref($tokens->{$token}) eq 'HASH' and !keys %{$tokens->{$token}});
    }

    my $tokenized;

    $m->log->debug(Dumper($tokens));

    $template->process( 
      $conf->{template}{file}{$templatefile}{in}, 
      $tokens,
      \$tokenized,
    ) || ( $m->log->fatal( "Template error: " . $template->error() ) and die );
    open( OUT, '>' . $conf->{template}{file}{$templatefile}{out} );
    print OUT $tokenized;
    close(OUT);
  }

  $m->log->info('leaving ACTION_tokenize');
}

=head1 NON-ACTIONS

=cut

=head2 fetchAndLoadFiles

 Title   : fetchAndLoadFiles
 Usage   : fetchAndLoadFiles(<build_obj>, <xml_conf_obj>, <file_type>...)
 Function: Calls internal methods to mirror files specified for this file_type in the xml_conf_obj
 Example :
 Returns : 
 Args    :

=cut
sub fetchAndLoadFiles {
  my ( $m, $conf, $type, $command, $itm ) = @_;
  $m->log->info('entering fetchAndLoadFiles');

  foreach my $key ( keys %$itm ) {
    print "fetching files for $key\n";

    my $load = 0;
    foreach my $file ( @{ $itm->{$key}{file} } ) {

      # check to see if this command can handle this type
      if ( $file->{type} eq $type ) {
        my $fullpath = catfile( $conf->{path}{data}, $file->{local});
        $fullpath =~ s!^(.+)/[^/]*!$1!;

        unless ( -d $fullpath ) {
          $m->log->debug("mkpath $fullpath");
          mkpath( $fullpath, 0, 0711 )
            or print "Couldn't make path '$fullpath': $!\n";
        }

        print "  +", $file->{remote}, "\n";
        $load = 1 if $m->_mirror( $file->{remote}, $file->{local} );
        $load = 1 unless $m->_loaded( $fullpath );

        next unless $load;

        print "    loading...";

        my $sys_call = join( ' ', $command, $fullpath );
        $m->log->debug( "system call: $sys_call" );

        my $result = system( $sys_call );

        if ( $result != 0 ) {
          print "failed: $!\n";
          $m->log->fatal("failed: $!");
          die;
        }
        else {
          $m->_loaded( $fullpath, 1 );
          print "done!\n";
          $m->log->debug("done!");
        }
      }
    }
  }

  $m->log->info('leaving fetchAndLoadFiles');
}


=head2 printAndReadOptions

 Title   : printAndReadOptions
 Usage   : prints out and reads options from the XML file
 Function:
 Example :
 Returns :
 Args    : m=build obj, conf=conf obj, option=which option to pull from the conf XML file


=cut
sub printAndReadOptions
{
   my ($m,$conf,$option) = @_;
   print "Available $option Items:\n";

   my $i = 1;
   my %itm = ();
   foreach my $item (sort keys %{ $conf->{$option} })
   {
     $itm{$i} = $item;
     print "[$i] $item\n";
     $i++;
   }
   print "\n";

   my $chosen = $m->prompt("Which items would you like to load (Comma delimited)? [0]");
   $m->notes("$option"."s" => $chosen);

   my %options = map {$itm{$_} => $conf->{$option}{$itm{$_}}} split ',',$chosen;
   return(%options);
}

sub property {
  my $m = shift;
  my $key  = shift;
  my $val  = $m->{properties}{$key};
  $val     =~ s/^$key=//;
  return $val;
}

sub conf {
  my $self = shift;
  return $self->{conf} if defined $self->{conf};

  my $file = $self->property('load_conf');
  $self->{conf} = XMLin($file, 
    ForceArray  => ['token','path','file'], 
    KeyAttr     => [qw(tt2 input token name file)], 
    ContentKey  => '-value'
  );

  return $self->{conf};
}

sub log {
  my $m = shift;
  if(!$m->{log}){
	my $pack = ref($m);
	$pack =~ s/::/./g;
	$m->{log} = Log::Log4perl->get_logger($pack);
	$m->{log}->info("starting log for $pack");
  }
  return $m->{log};
}

sub _loaded {
  my $m    = shift;
  my $conf = $m->conf;
  my ( $file, $touch ) = @_;
  $file .= '_' . $conf->{'build'}{'load_touchext'};
  if ($touch) {
    open( T, '>' . $file );
    print T "\n";
    close(T);
    return 1;
  }
  else {
    return 1 if -f $file;
    return 0;
  }
}

sub _mirror {
  my $m = shift;
  my $conf = $m->conf;
  my ($remote,$local) = @_;
  $local = $conf->{'path'}{'data'} .'/'. $local;

  if( $m->_loaded($local) ){
	print "  already loaded, remove touchfile to reload.  skipping\n";
	return 0;
  }

  #mirror the file
  my $rc = mirror($remote, $local);

  if ($rc == 304) {
    print "    ". $local ." is up to date\n";
    return 0;
  } elsif (!is_success($rc)) {
    print "    $rc ", status_message($rc), "   (",$remote,")\n";
    return 0;
  } else {
    #file is new, load it
    print "    updated\n";
    return 1;
  }
}

1;
