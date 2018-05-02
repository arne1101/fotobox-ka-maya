package FotoboxApp;
use Dancer ':syntax';
use Fotobox;
use List::MoreUtils 'first_index'; 

our $VERSION = '2.1';

# init all stuff
my $fotobox = Fotobox->new();
my $foto;
my $print;
my $skip = 1;
my $collage = 0;
my $x1 = 1;
my $xMail = 1;
my $xMailIntern = 1;
my $xGal = 1;
my $fotoNumber = 0;
my $galleryFotoNumber = 0;
my $selectedGalleryFoto;

$| = 1;

get '/' => sub {
    # start screen - everything is reset
    undef $foto;
    $skip = 0;
    $x1 = 1;
	undef $xMail;
	$xMail = 1;
#	undef = $xGal;
	$xGal = 1;
#	undef $xMailIntern;
	$xMailIntern = 1;
	$fotoNumber = 0;
	
    #$fotobox->cleanTemp();
	
    set 'layout' => 'fotobox-main';
    template 'fotobox_index';    

    
};

get '/new' => sub {
    # /new is to reset all variables and take a new picture
    undef $foto;
    $skip = 0;
    undef $x1;
	undef $xMail;
	$xMail = 1;
#	undef $xGal;
	$xGal = 1;
#	undef $xMailIntern;
	$xMailIntern = 1;
    $x1 = 1;
	$fotoNumber = 0;
    
    redirect '/live';
};


# /live is liveview of webcam image
get '/live' => sub {
    set 'layout' => 'fotobox-main';
    template 'fotobox_live';
};

# Liveview with counter
get '/start' => sub {
	my $timer = $fotobox->getConfig("timer");

	set 'layout' => 'fotobox-main';
        template 'fotobox_start',
    	{
        	'timer' => $timer,
            'redirect_uri' => "foto1",
    	};
};

# take a picture
get '/foto1' => sub {

    
    if ($x1 == 1) {
		# do stuff only once
        $foto = $fotobox->takePicture();
        $fotobox->brandingPhoto($foto);
        $x1 = 0;
    }

	redirect '/mail';
   
};


# Random Photo
get '/random' => sub {
    
    my $dir = $fotobox->getPhotoPath();
    my @gallery;
        
    opendir DIR, $dir or die $!;
    while(my $entry = readdir DIR ){
            if ($entry =~ m/foto_/) {
                push (@gallery, $entry);
            }
    }
    closedir DIR;
    
      
    my $randomelement = $gallery[rand @gallery];
       
     
    set 'layout' => 'fotobox-main';
    template 'fotobox_random',
    {
        'foto_filename' => $randomelement
    };
};




# Send Photo via Mail
get '/mail' => sub {
          
	if ($xMail eq 1)
	{
		$foto =~ /(?:\d*\.)?\d+/g;
		$fotoNumber = $&;
		$xMail = 0;
	}			  
	    set 'layout' => 'fotobox-main';
	    template 'fotobox_mail',
	    {
	        'foto_filename' => $foto,
			'foto_number' => $fotoNumber
	    };
    
};

get '/mailintern' => sub {

	$selectedGalleryFoto = params->{foto};

	if ($xMailIntern eq 1)
	{
		$selectedGalleryFoto =~ /(?:\d*\.)?\d+/g;
		$galleryFotoNumber = $&;
		$xMailIntern = 0;
	}			  
	    set 'layout' => 'fotobox-gallery';
	    template 'fotobox_mailintern',
	    {
	        'foto_filename' => $selectedGalleryFoto,
			'foto_number' => $galleryFotoNumber
	    };
	
};


# Successfull Mail-Send Page
get '/mail/send/' => sub {
    
    my $to = params->{mail};
    $to =~ tr/[%40]/[@]/;
    my $from = params->{mailfrom};
    $from =~ tr/[%40]/[@]/;
    
    if ($to =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/ && $from =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/) {
    
	$fotobox->sendMail($from, $to, $foto, "no");

        set 'layout' => 'fotobox-main';
        template 'fotobox_mailsuccess',
        {
            'mail' => $to,
            'foto_filename' => $foto,
			'foto_number' => $fotoNumber			
        };
    } else {
			redirect '/mail';
    }

};

get '/mailintern/send/' => sub {
    
    my $to = params->{mail};
    $to =~ tr/[%40]/[@]/;
    my $from = params->{mailfrom};
    $from =~ tr/[%40]/[@]/;
    
    if ($to =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/ && $from =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/) {
    
	$fotobox->sendMail($from, $to, $selectedGalleryFoto, "yes");

        set 'layout' => 'fotobox-gallery';
        template 'fotobox_mailinternsuccess',
        {
            'mail' => $to,
            'foto_filename' => $selectedGalleryFoto,
			'foto_number' => $galleryFotoNumber			
        };
    } else {
			redirect '/mail';
    }

};

get '/delete' => sub {
    
        set 'layout' => 'fotobox-main';
        template 'fotobox_delete',
};

get '/delete/confirm/' => sub {
     
    my $number = params->{number};
    my $dir = $fotobox->getPhotoPath();
    
    my $deleteFoto = $dir."maya_foto_".$number.".jpg";
    
    my $message = "";
    
    if (-e $deleteFoto) {
        system("sudo rm $deleteFoto &");
        $message = "$number gelöscht";
    } else {
       $message = "$number nicht vorhanden";
    }
    
    set 'layout' => 'fotobox-main';
    template 'fotobox_delete',
       {
           'message' =>	$message		
       };
};

# Gallerie
get '/gallery' => sub {
    
    my $dir = $fotobox->getPhotoPath();
    my $thDir = $fotobox->getTempPhotoPath();

    my @galleryFoto;
    my $gal;

    #if ($xGal == 1) {
        
		opendir DIR, $dir or die $!;
			while(my $entry = readdir DIR ){
				if ($entry =~ m/maya_/) {
                    push (@galleryFoto, "gallery/".$entry);
                }
			}
		closedir DIR;
		
		opendir TEMPDIR, $thDir or die $!;
			while(my $entry = readdir TEMPDIR ){
				if ($entry =~ m/maya_/) {
               			    push (@galleryFoto, "tmpgallery/".$entry);
		                }
			}
		
		closedir TEMPDIR;
    
	#	$xGal = 0;
	#}
    
        

    @galleryFoto = sort @galleryFoto;
    
    $gal = ''."\n";
    foreach (@galleryFoto) {
        $_ =~ /(?:\d*\.)?\d+/g;
        my $timestamp=(stat("/var/www/FotoboxApp/public/$_"))[9];
        my ($Sekunde, $Minute, $Stunde, $Tag, $Monat, $Jahr) = localtime($timestamp);
        $gal = $gal.'<div class="responsive"><div class="img"><a href="mailintern?foto='.$_.'"><img width="300" src="'.$_.'"></a><div class="desc">Datum: '.$Tag.'.'.$Monat.' '.$Stunde.':'.$Minute.' Foto: '.$&.'</div></div></div>'."\n";
    }   
     
    set 'layout' => 'fotobox-gallery';
    template 'fotobox_gallery',
    {
        'gallery' => $gal
    };
};


true;
