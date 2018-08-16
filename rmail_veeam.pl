#! C:\perl\bin\perl -w
# Sistema        : Read Mail desde IMAP 
# Modulo         : rmail1.pl   
# Version		 : 0.1 para IMAP
# Objetivo       : Leer correos de Veeam B&R
# Autor          : J.T.S.
# Fecha          : 25-Abril-2018
# Modificaciones : Falta tema password de la cuenta 

use Net::IMAP::Simple;
use Email::Simple;
use MIME::Parser;
use HTML::TableExtract;
use Mojo::DOM;
use Data::Dumper;
#use Data::Dumper::GUI;  <<<---
use Config::Tiny;

use strict;
use warnings;

my $DEBUG = 1;   # >0 Si incluye debug

# Parametros en config.  ## Falta tema password
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read( 'file.conf', 'utf8' );

my $account     = shift || 'imap_acc_1';

my $host        = $Config->{$account}->{host} ||'10.25.51.31';
my $foldername  = $Config->{$account}->{forldername} ||'INBOX/veeam_alerts';
my $user        = $Config->{$account}->{user} ||'jtrumper@e-contact.cl';
my $pass        = 'Jt654321';  ############ <<<<  usar KeePass

print "conectandome al servidor de IMAP ...\n";
my $imap = Net::IMAP::Simple->new( $host ) ||
                 die "No pude conectarme al IMAP\n[ $Net::IMAP::Simple::errstr ]\n";

if(!$imap->login($user,$pass)){
    print STDERR "Login erroneo: " . $imap->errstr . "\n";
    exit(64);
}
print "conectado\n";

print "seleccionado $foldername ...\n";
my $nm = $imap->select($foldername);

print "revisando correos en $foldername ...\n"; 
for(my $i = 1; $i <= $nm; $i++){
    print "Revisando ... ";
    if($imap->seen($i)){
        print "*";
    } else {
        print " ";
    }
    my $es = Email::Simple->new(join '', @{ $imap->top($i) } );
    printf("[%03d] %s\n", $i, $es->header('Subject'));

    my $msg = $imap->get( $i ) or die $imap->errstr;
    # print Dumper $msg;
    my $message = "$msg";  # Lo "transforma" a texto
    # print $message;

    # Parse del mensaje
    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);      # Para no escribir attachments a disco
    my $message2  = $parser->parse_data($message);
    #print Dumper $message2;
    my $body = $message2->{ME_Bodyhandle}->{MBS_Data}."\n";

    #open( my $fh, "+>>C:\\tmp\\perl_snipeets\\rimap\\out\\util.html" ) or die "$!\n";
    #print $fh $body;
    #close $fh;

    # Extrae la tabla de interes
    my $te = HTML::TableExtract->new( headers => [qw(Name Status Size Duration Details)] );
    $te->parse($body);
    my $cont;
    foreach my $row ($te->rows) {
        if ( $DEBUG ) {
            # print join(',', @$row), "\n";
            $cont .= "Name: $$row[0]\n";
            $cont .= "Status: $$row[1]\n";
            $cont .= "Size: $$row[2]\n";
            $cont .= "Duration: $$row[3]\n";
            $cont .= "Details: $$row[4]\n";
            print $cont;
        }
        #$cont = join(',', @$row);
    }

    my $dom = Mojo::DOM->new($body);
    my $all_text = $dom->all_text;
    $all_text =~ /Replication job: (.*)(\s+)/;
    my $job = $1;
    print "Job: $job\n";

    #print $all_text;

    if (  $es->header('Subject') =~ /Failed/ and $imap->seen($i) ) {
        alarma(\$all_text, $cont);
    }

    print "=========== fin mail ==============\n";
}



sub alarma {
    my $rbody=shift;
    my $cont=shift;
    my $body = $$rbody;
    print "************************************************\n";
    print " Se detecto una Falla Aca Enviando Alarma !!!\n";
    print $cont."\n";
    print "************************************************\n";
}

END {
    $imap->quit if $imap;
    print "terminando sesion.\n";
}
