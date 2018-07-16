use RMail;

# Parametros en config.  ## Falta tema password
my $Config = Config::Tiny->new;
$Config    = Config::Tiny->read( 'rimap.conf', 'utf8' );

my $account     = shift || 'imap_acc_1';
my $host        = $Config->{$account}->{host} ||'10.25.51.31';
my $user        = $Config->{$account}->{user} ||'jtrumper@e-contact.cl';
my $pass        = 'Jt654321';  ############ <<<<  usar KeePass
my $foldername  = 'INBOX/ApexSQL_Monitor'; #$Config->{$account}->{forldername} 

my $res;
my $sesion = RMail->new(host => $host, user => $user, pass => $pass);
$sesion->foldername($foldername);

print "msql 0.1 - suerte! :) \n";
print "msql> ";
while (<>) {
  chomp;
  my $command = $_;
  $res = exec_cmd ($command);
  print "\nmsql> $res";
  print "\nmsql> ";
}

sub exec_cmd {
    my $command = shift;
    my $respta;
    exit if ( lc ( $command) =~ /(quit|exit)/ );
    if ( lc ( $command) =~ /conecta/ ) {
        $sesion->conecta();
        return;
    }
    elsif ( lc ( $command) =~ /desconecta/) {
        $sesion->desconecta();
    }
    elsif ( lc ( $command) =~ /usef/ ) {
        $command =~ s/usef(\s+)//ig;
        my $foldername = $command;
        $sesion->usef(foldername => $foldername);
    } 
    elsif ( lc ( $command) =~ /select/) {
        $command =~ s/select(\s+)//ig;
        my $select = $command;
        $sesion->revisa();
    }
    elsif ( lc ( $command) =~ /help/) {
        help();
        return;
    }
    else {
        print "comando desconocido.\n";
        return;
    }
    return $respta;
}


sub help {
    print "quit|exit\n";
    print "conecta\tdesconecta\n";
    print "usef <foldername>\n";
    print "select ... \n";
}