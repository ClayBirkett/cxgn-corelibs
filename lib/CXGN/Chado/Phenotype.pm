=head1 NAME

CXGN::Chado::Phenotype
A class for handling phenotype objects

implements an object for the Chado 'phenotype' database table

=head1 SYNOPSIS



=head1 AUTHOR

Isaak Tecle (iyt2@cornell.edu)

=cut


use warnings;
use strict;



package CXGN::Chado::Phenotype;


use CXGN::DB::Object;
use base qw /CXGN::DB::Object/;


=head2 new

 Usage:        Constructor
 Desc:
 Ret:        
 Args:         a database handle and a unique ID.
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh=shift;
    my $phenotype_id=shift;
    my $self = $class->SUPER::new($dbh);
    
    $self->set_phenotype_id($phenotype_id);
    
    if ($phenotype_id) {
	$self->fetch();
    }

    return $self; 


}

sub fetch {
    my $self = shift;
    
    my $query = "SELECT phenotype_id, uniquename, observable_id, attr_id, value, cvalue_id, assay_id, individual_id, sp_person_id  FROM public.phenotype WHERE phenotype_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_phenotype_id());
    
    while (my ($phenotype_id, $uniquename, $observable_id, $attr_id, $value, $cvalue_id, $assay_id, $individual_id, $sp_person_id) = $sth->fetchrow_array()) { 
	$self->set_phenotype_id($phenotype_id);
	$self->set_unique_name($uniquename);
	$self->set_observable_id($observable_id);
	$self->set_attr_id($attr_id);
	$self->set_value($value);
	$self->set_cvalue_id($cvalue_id);
	$self->set_assay_id($assay_id);
	$self->set_individual_id($individual_id);
	$self->set_sp_person_id($sp_person_id);
    }
       
}

sub store {
    my $self = shift;
    
    if ($self->get_phenotype_id()) { 
	my $query = "UPDATE public.phenotype SET
                     uniquename=?, observable_id=?, attr_id=?, value=?, cvalue_id=?, assay_id=?, individual_id=?, sp_person_id=?
                     WHERE phenotype_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute( $self->get_unique_name(),
		       $self->get_observable_id(),
		       $self->get_attr_id(),
		       $self->get_value(),
		       $self->get_cvalue_id(),
		       $self->get_assay_id(),
		       $self->get_individual_id(),
		       $self->get_sp_person_id(),
		       $self->get_phenotype_id()
		       );
    }
    else { 
	       
	my $query = "INSERT INTO public.phenotype (uniquename, observable_id, attr_id, value, cvalue_id, assay_id, individual_id, sp_person_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute( $self->get_unique_name(),
		       $self->get_observable_id(),
		       $self->get_attr_id(),
		       $self->get_value(),
		       $self->get_cvalue_id(),
		       $self->get_assay_id(),
		       $self->get_individual_id(),
		       $self->get_sp_person_id()
		       );
		      
	my $phenotype_id=$self->get_currval("public.phenotype_phenotype_id_seq");
 	$self->set_phenotype_id($phenotype_id);
    }
    return $self->get_phenotype_id();
}


=head2 set_phenotype_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_phenotype_id {
    my $self=shift;
    $self->{phenotype_id}=shift;

}

=head2 get_phenotype_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_phenotype_id {
    my $self=shift;
    return $self->{phenotype_id};

}

=head2 set_unique_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_unique_name {
    my $self=shift;
    $self->{uniquename}=shift;

}

=head2 get_unique_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_unique_name {
    my $self =shift;
    return $self->{uniquename};

}

=head2 set_observable_id

 Usage:        
 Desc:         The observable ID must be an existing cvterm_id
               that denotes the observed character.
 Ret:
 Args:
 Side Effects:
 Example:      leaf size has a cvterm_id of 23015

=cut

sub set_observable_id {
    my  $self = shift;
    $self->{observable_id}=shift;

}
=head2 get_observable_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_observable_id {
    my $self =shift;
    return $self->{observable_id};
}

=head2 set_attr_id

 Usage:
 Desc:            
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_attr_id {
    my $self=shift;
    $self->{attr_id}=shift;

}

=head2 get_attr_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_attr_id {
    my $self=shift;
    return $self->{attr_id};

}

=head2 set_value

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_value {
    my $self=shift;
    $self->{value}=shift;

}

=head2 get_value

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_value {
    my $self=shift;
    return $self->{value};

}

=head2 set_cvalue_id

 Usage:
 Desc:         The cvalue_id is the unit of measurement
               associated with the value. This must be a term
               from the PATO ontology.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_cvalue_id {
    my $self=shift;
    $self->{cvalue_id}=shift;

}

=head2 get_cvalue_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cvalue_id {
    my $self=shift;
    return $self->{cvalue_id};

}
=head2 set_assay_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_assay_id {
    my $self=shift;
    $self->{assay_id}=shift;

}

=head2 get_assay_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_assay_id {
    my $self=shift;
    return $self->{assay_id};

}

=head2 get_individual_id, set_individual_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_individual_id {
    my $self=shift;
    $self->{individual_id}=shift;

}

sub get_individual_id {
    my $self = shift;
    return $self->{individual_id};
}


=head2 set_sp_person_id, get_sp_person_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_sp_person_id {
    my $self=shift;
    $self->{sp_person_id}=shift;

}

sub get_sp_person_id {
    my $self =shift;
    return $self->{sp_person_id};
}

=head2 insert_phenotype_cvterm_ids

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub insert_phenotype_cvterm_ids {
    my $self=shift;
    my $phenotype_id=shift;
    my $cvterm_id=shift;
    my $q = "INSERT INTO public.phenotype_cvterm (phenotype_id, cvterm_id) VALUES (?,?)";
    my $sth= $self->get_dbh()->prepare($q);
    if ($phenotype_id && $cvterm_id) {
    $sth->execute($phenotype_id, $cvterm_id);

# else {
    print "STORED  phenotype_id: $phenotype_id  and cvterm_id: $cvterm_id \n";
#}
}
}


=head2 get_pop_data_summary

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

=head2 cvterm_exists

 Usage: $self->cvterm_exists() 
 Desc:   check if another cvterm exists with the same cv_id, name, and is_obsolete value
         prior to updating 
 Ret:    cvterm_id or undef if no other cvterm exists
 Args:   non 
 Side Effects: none
 Example:

=cut

sub phenotype_id_exists {

    my $self=shift;
    my $observable_id=shift;
    my $individual_id=shift;
    my $query="SELECT phenotype_id FROM public.phenotype WHERE observable_id=? AND individual_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($observable_id, $individual_id);
    my ($existing_phenotype_id) = $sth->fetchrow_array();
    if ($existing_phenotype_id) {  return $existing_phenotype_id ; }
    else { return undef; }
}


 sub create_phenotype {
     my $self=shift;
    my $dbh= $self->get_dbh();
     my @create = ("CREATE TABLE public.phenotype (
         phenotype_id SERIAL NOT NULL,
         primary key (phenotype_id),
         uniquename TEXT NOT NULL,  
         observable_id INT,
         FOREIGN KEY (observable_id) REFERENCES public.cvterm (cvterm_id) ON DELETE CASCADE,
         attr_id INT, 
         FOREIGN KEY (attr_id) REFERENCES public.cvterm (cvterm_id) ON DELETE SET NULL,
         value VARCHAR,
        cvalue_id INT,
        FOREIGN KEY (cvalue_id) REFERENCES public.cvterm (cvterm_id) ON DELETE SET NULL,
        assay_id INT,
        FOREIGN KEY (assay_id) REFERENCES public.cvterm (cvterm_id) ON DELETE SET NULL,
        individual_id INT,
        FOREIGN KEY (individual_id) REFERENCES phenome.individual (individual_id) ON DELETE CASCADE,
        sp_person_id INT,
        FOREIGN KEY (sp_person_id) REFERENCES sgn_people.sp_person (sp_person_id) ON DELETE SET NULL,
        CONSTRAINT phenotype_c1 UNIQUE (uniquename)
       )", 
"CREATE INDEX phenotype_idx1 ON phenotype (cvalue_id)",
"CREATE INDEX phenotype_idx2 ON phenotype (observable_id)",
"CREATE INDEX phenotype_idx3 ON phenotype (attr_id)",
"COMMENT ON TABLE phenotype IS 'A phenotypic statement, or a single
atomic phenotypic observation, is a controlled sentence describing
observable effects of non-wild type function. E.g. Obs=eye, attribute=color, cvalue=red.'",
"COMMENT ON COLUMN phenotype.observable_id IS 'The entity: e.g. anatomy_part, biological_process.'",
"COMMENT ON COLUMN phenotype.attr_id IS 'Phenotypic attribute (quality, property, attribute, character) - drawn from PATO.'",
"COMMENT ON COLUMN phenotype.value IS 'Value of attribute - unconstrained free text. Used only if cvalue_id is not appropriate.'",
"COMMENT ON COLUMN phenotype.cvalue_id IS 'Phenotype attribute value (state).'",
"COMMENT ON COLUMN phenotype.assay_id IS 'Evidence type.'", 
"GRANT SELECT, UPDATE, INSERT ON public.phenotype TO web_usr", 
"GRANT SELECT, UPDATE, INSERT ON public.phenotype_phenotype_id_seq TO web_usr");

    foreach my $q (@create) {
  	$dbh->do($q);  
	$dbh->commit();
    	
  }   
}

sub create_phenotype_cvterm {
    my $self=shift;
    my $dbh= $self->get_dbh();
   
   my @create = ("CREATE TABLE public.phenotype_cvterm (
    phenotype_cvterm_id SERIAL NOT NULL,
    primary key (phenotype_cvterm_id),
    phenotype_id INT NOT NULL,
    FOREIGN KEY (phenotype_id) REFERENCES public.phenotype (phenotype_id) ON DELETE CASCADE,
    cvterm_id INT NOT NULL,
    FOREIGN KEY (cvterm_id) REFERENCES public.cvterm (cvterm_id) ON DELETE CASCADE,
    rank int not null default 0,
    CONSTRAINT phenotype_cvterm_c1 UNIQUE (phenotype_id, cvterm_id, rank))", 
    "CREATE INDEX phenotype_cvterm_idx1 ON phenotype_cvterm (phenotype_id)",
    "CREATE INDEX phenotype_cvterm_idx2 ON phenotype_cvterm (cvterm_id)", 
    "COMMENT ON TABLE phenotype_cvterm IS NULL", 
    "GRANT SELECT, UPDATE, INSERT ON public.phenotype_cvterm TO web_usr", 
    "GRANT SELECT, UPDATE, INSERT ON public.phenotype_cvterm_phenotype_cvterm_id_seq TO web_usr");

   foreach my $q (@create) {
  	$dbh->do($q);  
	$dbh->commit();
    	
  }   
}

return 1;
