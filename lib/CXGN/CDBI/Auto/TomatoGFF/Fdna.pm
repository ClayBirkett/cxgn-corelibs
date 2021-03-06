package CXGN::CDBI::Auto::TomatoGFF::Fdna;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::TomatoGFF::Fdna - object abstraction for rows in the tomato_gff.fdna table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      fref
      foffset

  Columns:
      fref
      foffset
      fdna

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'tomato_gff.fdna' );

our @primary_key_names =
    qw/
      fref
      foffset
      /;

our @column_names =
    qw/
      fref
      foffset
      fdna
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
