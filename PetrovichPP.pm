# ------------------------------------------------------------------------------
package PetrovichPP;
use strict;
use warnings;
use utf8;
use FindBin qw/$RealBin/;
use JSON;

#use YAML::Loader;
use Carp;
use Exporter;

our @ISA    = ( 'Exporter' );
our @EXPORT = qw
  (
  setGender detectGender firstName lastName middleName fullName
);

# ------------------------------------------------------------------------------
use constant CASE_NOM  => -1;
use constant CASE_GEN  => 0;
use constant CASE_DAT  => 1;
use constant CASE_ACC  => 2;
use constant CASE_INS  => 3;
use constant CASE_PREP => 4;
use constant CASE_LAST => CASE_PREP;

use constant GENDER_MALE        => 1;
use constant GENDER_FEMALE      => 2;
use constant GENDER_ANDRO       => 3;

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $gender, $rules_path ) = @_;

    my $self = {
        gender => $gender || GENDER_ANDRO,
        genders => {
            male        => GENDER_MALE,
            female      => GENDER_FEMALE,
            androgynous => GENDER_ANDRO } };

    my $rpath = $rules_path || $RealBin;
    chomp $rpath;
    $rpath =~ s|/$||g;

#    my $cpath = $rpath.'/rules/rules.yml';
    my $cpath = $rpath . '/rules/rules.json';

    local $/;
    open my $cfile, '<', $cpath or confess "Can not open '$cpath': $!";
    my $cdata = <$cfile>;
    close $cfile;

    eval { $self->{rules} = decode_json( $cdata ); };
    confess "Can not decode JSON data: $@" if $@;

#    eval { $self->{rules} = YAML::Loader->new->load( $cdata ); };
#    confess "Can not decode YAML data: $@" if $@;

    foreach my $type ( qw/lastname firstname middlename/ )
    {
        foreach my $suffix ( @{ $self->{rules}->{$type}->{suffixes} } )
        {
            %{ $suffix->{htest} } =
              map { $_ => length $_ } @{ $suffix->{test} };
        }
        foreach my $except ( @{ $self->{rules}->{$type}->{exceptions} } )
        {
            %{ $except->{htest} } = map { $_ => 1 } @{ $except->{test} };
        }
    }

    bless( $self, $class );
    return $self;
}

# ------------------------------------------------------------------------------
sub __self_or_default
{
    return @_
      if ref( $_[0] ) eq __PACKAGE__
      or ( @_ > 2 and $_[0] eq __PACKAGE__ );
    unshift @_, PetrovichPP->new;
    return @_;
}

# ------------------------------------------------------------------------------
sub firstName  { return _inflect( @_, 'first' ); }
sub middleName { return _inflect( @_, 'middle' ); }
sub lastName   { return _inflect( @_, 'last' ); }
# ------------------------------------------------------------------------------
sub fullName
{
    my ( $self, $last, $first, $middle, $case ) = __self_or_default(@_);

    $self->setGender($self->detectGender($middle));

    (
        $self->_inflect( $last, $case, 'last' ),
        $self->_inflect( $first, $case, 'first' ),
        $self->_inflect( $middle, $case, 'middle' )
    );
}

# ------------------------------------------------------------------------------
sub detectGender
{
    my ( undef, $middlename ) = __self_or_default( @_ );

    confess '$middlename parameter required!' unless $middlename;

    $middlename =~ /(..)$/ and $middlename = lc $1;
    return GENDER_MALE   if $middlename eq 'ич' || $middlename eq 'ыч';
    return GENDER_FEMALE if $middlename eq 'на';
    return GENDER_ANDRO;
}

# ------------------------------------------------------------------------------
sub setGender
{
    my ( $self, $gender ) = __self_or_default( @_ );

    if(    $gender == GENDER_MALE
        || $gender == GENDER_FEMALE
        || $gender == GENDER_ANDRO )
    {
        $self->{gender} = $gender;
    }

    elsif( $self->{genders}->{$gender} )
    {
        $self->{gender} = $self->{genders}->{$gender};
    }
    else
    {
        confess "Invalid gender: '$gender'";
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _checkException
{
    my ( $self, $name, $case, $type ) = __self_or_default( @_ );

    return unless $self->{rules}->{$type}->{exceptions};

    my $lower_name = lc $name;

    foreach my $rule ( @{ $self->{rules}->{$type}->{exceptions} } )
    {
        next
          unless $self->{genders}->{ $rule->{gender} } == $self->{gender}
          || $self->{genders}->{ $rule->{gender} } == GENDER_ANDRO;

        #        next unless $self->_checkGender( $rule->{gender} );

        #        if( grep { $_ eq $lower_name } @{ $rule->{test} } )
        if( $rule->{htest}->{$lower_name} )
        {
            return $name if $rule->{mods}->[$case] eq '.';
            return $self->_applyRule( $rule->{mods}->[$case], $name );
        }
    }
    return;
}

# ------------------------------------------------------------------------------
sub _findInRules
{
    my ( $self, $name, $case, $type ) = __self_or_default( @_ );

    #    my $name_length = length $name;

    foreach my $rule ( @{ $self->{rules}->{$type}->{suffixes} } )
    {
        next
          unless $self->{genders}->{ $rule->{gender} } == $self->{gender}
          || $self->{genders}->{ $rule->{gender} } == GENDER_ANDRO;

        #        foreach my $last_char ( @{ $rule->{test} } )
        foreach my $last_char ( keys %{ $rule->{htest} } )
        {
            #            my $last_char_length = length $last_char;
#            my $last_char_length = $rule->{htest}->{$last_char};

            my $last_name_char =

                substr( $name, -$rule->{htest}->{$last_char}, $rule->{htest}->{$last_char} );
#              substr( $name, -$last_char_length, $last_char_length );

            if( $last_char eq $last_name_char )
            {
                next if $rule->{mods}->[$case] eq '.';
                return $self->_applyRule( $rule->{mods}->[$case], $name );
            }
        }
    }
    return $name;
}

# ------------------------------------------------------------------------------
sub _inflect
{
    my ( $self, $name, $case, $type ) = __self_or_default( @_ );

    confess '$name parameter required!' unless $name;

    $name =~ /^(.)(.*)$/ and $name = uc( $1 ) . lc( $2 );

    return $name if $case == CASE_NOM;

    confess "\$case parameter is invalid: '$case'!" if $case !~ /^\d+$/ && $case > CASE_LAST;

    my @names_arr = split( '-', $name );
    my @result;

    foreach my $arr_name ( @names_arr )
    {
        if( (   my $except =
                $self->_checkException( $arr_name, $case, $type . 'name' ) ) )
        {
            push @result, $except;
        }
        else
        {
            push @result,
              $self->_findInRules( $arr_name, $case, $type . 'name' );
        }
    }
    return join( '-', @result );
}

# ------------------------------------------------------------------------------
sub _applyRule
{
    my ( undef, $mc, $name ) = __self_or_default( @_ );

    my $dashes = $mc =~ s|-||g;
    $name =~ s|.{$dashes}$|| if $dashes;
####    $name = substr( $name, -$dashes, $dashes ) if $dashes;
    return $name . $mc;
}

# ------------------------------------------------------------------------------

1;

