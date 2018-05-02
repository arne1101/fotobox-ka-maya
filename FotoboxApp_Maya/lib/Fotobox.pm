#!/usr/bin/perl

#########################################
# Fotobox fotobox.pm                    #
# Author: Arne Allisat                  #
# Moduldatei Fotobox Maya Edition       #
# Version: 2.2                          #
# Date: 10.09.2016                      #
#########################################

package Fotobox;
use Mail::Sender;
use Config::Simple;


# config
# Pi
my $fotoboxCfg = '/var/www/FotoboxApp/conf/fotobox.conf';
my $appPath = '/var/www/FotoboxApp/';
my $photoPath = '/var/www/FotoboxApp/public/gallery/';
my $tmpPhotoPath = '/var/www/FotoboxApp/public/tmpgallery/';
my $tempPath = '/var/tmp/';
my $brandingDir = '/var/www/FotoboxApp/public/branding/';

my $cfg = new Config::Simple($fotoboxCfg);

sub new {
	my $Objekt = shift;
	my $Referenz = {};
	bless($Referenz,$Objekt);
	return($Referenz);
}

sub getConfig {
	my $Objekt = shift;
	my $value = shift;
	
	return $cfg->param($value);
}

sub getPhotoPath {
	my $Objekt = shift;
	# Path for photos
	return $photoPath;	
	}

sub getThumbnailPath {
	my $Objekt = shift;
	# Path for Thumbnails
	return $thumbnailPath;	
}

sub getTempPhotoPath {
	my $Objekt = shift;
	# Path for temp photos
	return $tmpPhotoPath;	
}

sub startMotion {
	my $Objekt = shift;
	system("sudo service motion start");	
}

sub stopMotion {
	my $Objekt = shift;
	system("sudo service motion stop &");
}

sub takePicture {

	my $Objekt = shift;
	my $rc;
	my $return;
	undef $return;
	
	
	my $counter;
	my $filename;
	my $thumbExec;
	my $branding;
	
       
			
	# Bildernummer holen / erstellen
	$counter = countPhoto("Fotobox");
	
	# Dateiname bestimmen
	$filename = "foto_$counter.jpg";
	
	
	
	# Foto aufnehmen
	
	system("curl -u cam:cam http://localhost:8082/0/action/snapshot");
	sleep(1);
	system("sudo cp /tmp/motion/lastsnap.jpg $tmpPhotoPath$filename");
	
		
	
	# Pruefe ob Foto erfolgreich gespeichert wurde
	if (!-e $tmpPhotoPath.$filename) {
		# wenn kein Foto gespeichert
		die;
	}
	else {
		# Alles Gut
		return $filename;	
	}
	
	
	
}

sub brandingPhoto {
	
	# Wenn Branding, dann wird das Foto gebranded
	
	my $Objekt = shift;
	my $foto = shift;
	# Hauptlogo
	my $brandingLogo = $brandingDir.'logo.png';

	
	# Original Foto
	my $orig = $tmpPhotoPath.$foto;
	
	# epeg befehl zum verkleinern
	my $cmd = 'sudo epeg --width=680 --height=1080 '."$orig".' '."$orig";
	system($cmd);       
	
	# Fertiges Foto
	my $branding = $tmpPhotoPath."maya_".$foto;
	
	my $cmd1 = "composite -geometry +950+0 $orig $brandingLogo $branding &";

	system($cmd1);
	
	#system("sudo rm $orig &");
	
	return $foto;
	
}


# Mail versenden
sub sendMail {
	my $Objekt = shift;
	my $from = shift;
	my $to = shift;
	my $subject = getConfig("Fotobox", "email_subject");;
	my $message = getConfig("Fotobox", "email_message");
	my $foto = shift;
	my $intern = shift;
	my $attachment;
	
	if ($intern eq "no") {
        $foto = "maya_".$foto;
		my $rc = system("sudo cp $tmpPhotoPath$foto $photoPath$foto");
		my $rc2 = system("sudo chmod 677 $photoPath$foto");
		$attachment = $photoPath.$foto;
    } else {
		$attachment = $appPath."public/".$foto;
	}
	
	if (-e $attachment) {
		
		my $sender = new Mail::Sender {
					smtp => getConfig("Fotobox", "smtp"),
					port => getConfig("Fotobox", "port"),
					from => $from,
					auth => 'LOGIN',
					authid => getConfig("Fotobox", "authid"),
					authpwd => getConfig("Fotobox", "authpwd"),
					on_errors => 'die',
			}  or die "Can't create the Mail::Sender object: $Mail::Sender::Error\n";
		
		
		 $sender->OpenMultipart({
			  to => "$to",
					  subject  => "$subject",
#					  msg 	   => "$message",
					  ctype    => "text/html",
					  encoding => "quoted-printable"
			}) or die $Mail::Sender::Error,"\n";

		$sender->Body($message);
		$sender->Attach(
			{description => 'Foto',
			 ctype => 'image/jpeg',
			 encoding => 'Base64',
			 disposition => 'attachment; filename="'.$foto.'"; type="Image"',
			 file => $attachment
			});
		$sender->Close();

		
	} else {
		die "Mailanhang nicht da.\n";
	}

	
}




# Laufende Nr an Foto anhaengen
sub countPhoto {
	my $Objekt = shift;
	my $param = shift;
	
	my $counter;
	my $datecounter;
	
	my $file = $appPath.'lib/counter';
	
	#Pruefe ob Counter Datei vorhanden
	if (!-e $file) {
		#wenn datei nicht vorhanden, anlegen mit Inhalt "0"
		open COUNT, "> $file" or die "Cannot write file $file";
		print COUNT "0"; 
		close COUNT;
	}
	
	# Zaehlerdatei zum Lesen oeffnen
	open COUNT, "< $file" or die "Counter file $file not found";
	$counter = <COUNT>; # Zaehlerstand lesen
	close COUNT; # Datei schliessen

	$counter++;
	
	# Zaehlerdatei zum Schreiben oeffnen
	open COUNT, "> $file" or die "Cannot write file $file";
	print COUNT $counter; # aktuellen Zaehlerstand in Datei schreiben
	close COUNT;
	
	return $counter;
}

# Temporaere Bilder loeschen
sub cleanTemp {
	system("sudo rm $tmpPhotoPath*.jpg &");
}

1;
