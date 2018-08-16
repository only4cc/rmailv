#! C:\perl\bin\perl -w
# Sistema        : Read Mail desde IMAP 
# Modulo         : RMAIL.pm   
# Version		 : 0.1 para IMAP
# Objetivo       : Interaccion IMAP Para Leer correos 
# Autor          : J.Trumper S.
# Fecha          : 16-Julio-2018
#
# Modificaciones : Falta tema password de la cuenta 
package RMail;

use Moo;
#use strict;
#use warnings;

use Net::IMAP::Simple;
use Email::Simple;
use MIME::Parser;
use Mojo::DOM;
#use Data::Dumper;
#use Data::Dumper::GUI;  <<<---
use Config::Tiny;
use Date::Parse;
use DateTime;
use Date::Calc qw(Delta_Days);

# Constantes
my $DEBUG    = 1;   # >0 Si incluye debug

my($day_hoy, $month_hoy, $year_hoy)=(localtime)[3,4,5];
++$month_hoy;
$year_hoy = $year_hoy+1900;

my $imap;
my $nm;

has host => ( is => "rw" );
has user => ( is => "rw" );
has pass => ( is => "rw" );
has foldername => ( is => "rw" );

my $DIF_DIAS    = 6; # || $Config->{$account}->{dias};  # Dias hacia atras para considerar 
my $patrones    = 'System availability|Free space';

sub conecta {   
    my $self = shift;
    print "conectandome al servidor ...\n"; #Servidor de IMAP 
    $imap = Net::IMAP::Simple->new( $self->host ) ||
                    die "No pude conectarme al IMAP\n[ $Net::IMAP::Simple::errstr ]\n";
    if(!$imap->login($self->user, $self->pass)){
        print STDERR "Login erroneo: " . $imap->errstr . "\n";
        exit(64);
    }
    print "conectado\n";
}

sub usef {
    my $self = shift;
    print "seleccionado [".$self->foldername."] ...\n";
    $nm = $imap->select($self->foldername);
}

sub revisa {
    my $self = shift;
    my ($c,$cc);
    print "revisando correos en $self->foldername ...\n"; 
    for(my $i = 1; $i <= $nm; $i++){
        print "Revisando ...";
        ++$c;
        if($imap->seen($i)){
=begin
            print " *\t"; # Ya fue revisado
            $cc = "-"  if ( $c % 4 == 0 );
            $cc = "\\" if ( $c % 4 == 1 );
            $cc = "|"  if ( $c % 4 == 2 );
            $cc = "/"  if ( $c % 4 == 3 );
            print "$cc\n";
=cut
        } else {
            my $es = Email::Simple->new(join '', @{ $imap->top($i) } );
            printf("[%03d] %s\n", $i, $es->header('Subject'));

            # Fceha formato: Thu, 10 May 2018 17:02:37 -0300
            my $fecha = $es->header('Date');
            my ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime($fecha);
            ++$month;
            $year = 1900 + $year;
            print "Fecha correo: $fecha [ $day $month $year ]\n";
            my $fecha_email = DateTime->new(
                year       => $year,
                month      => $month,
                day        => $day,
                hour       => $hh,
                minute     => $mm,
                second     => $ss,
            );
            my $Dd = Delta_Days($year,$month,$day,
                                $year_hoy,$month_hoy,$day_hoy);
            print "Diferencia: $Dd [dias]\n";
            if ( $Dd <= $DIF_DIAS ) {
                my $msg = $imap->get( $i ) or die $imap->errstr;  # print Dumper $msg;
                my $message = "$msg";  # Lo "transforma" a texto

                # Parse del mensaje
                my $parser = MIME::Parser->new();
                $parser->output_to_core(1);      # Para no escribir attachments a disco
                my $message2  = $parser->parse_data($message);  #print Dumper $message2;
                my $body = $message2->{ME_Bodyhandle}->{MBS_Data}."\n";

                my $dom = Mojo::DOM->new($body);
                my $all_text = $dom->all_text;

                #if (  $es->header('Subject') =~ /High alert/ and $imap->seen($i) ) {
                if (  $all_text =~ /High alert/ and $imap->seen($i) ) {
                    if ( $all_text =~ /($patrones)/ ) {
                        alarma(\$all_text, 0);
                    }
                }
                print "fin revision mail $i\n";
            }
            else {
                print "correo antiguo ... \n";
            }
        }
    }
}

sub desconecta {
    $imap->quit if $imap;
    print "\nTerminando sesion.\n";
}

END {
    $imap->quit if $imap;
    print "\nTerminando sesion.\n";
}


1;