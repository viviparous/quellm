#! /usr/bin/perl

=pod

quellm _ Perl client to query one or more LLMs via Ollama API, requires an Ollama server (see documentation at ollama.com)

project status _ Stable

2026 _ viviparous

=cut

use strict;
use warnings;
use feature 'say';
use JSON::PP;
use LWP::UserAgent; 
use LWP::Protocol::https;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use FindBin qw($Bin); # $Bin yields location of current programme
use File::Basename qw(dirname basename); #yields the parent directory _ dirname($Bin);
use Config::Tiny;
use Tie::IxHash;
use Try::Tiny qw(try catch); 
use Scalar::Util qw(looks_like_number);

##############################################

binmode STDOUT, ":utf8"; 
$Data::Dumper::Sortkeys=1;
$Data::Dumper::Terse=1;

my %dLogic=(null => "_nil_" , true => 1 , false => 0 , tint => "int" , tcsvint => "csvint" );
my %dAPI=( tags => "/api/tags" , generate => "/api/generate" , version => "/api/version" , pull => "/api/pull" , delete => "/api/delete" );
my %dAppState=( bHasValidEndpoint => $dLogic{false} , apiserver => $dLogic{null} , parpath => $Bin , bconfig_found => $dLogic{false}, 
  bconfig_useabsdir => $dLogic{false}  , tstt => time , tend => -1
);
my %dAppStrs=( bAppendQueryRules => $dLogic{true} , 
  queryRules => "(Be concise. Include a complete list of authoritative references.)" 
); 
# colours
my %dHues=( clrgr=>GREEN , clryw=>YELLOW, clrrd=>RED, clrblu=>BLUE, clrmgn=>MAGENTA, clrcyn=>CYAN, stybld=>BOLD, clr0=>RESET );

##############################################


sub getkbinput { my $msg=shift; say $msg; my $kbStr=<STDIN>;chomp($kbStr); return $kbStr; }
sub mksep { say '=' x 60; }
sub mksepc { my $clr=shift; say $clr; mksep(); say $dHues{clr0}; }
sub mkmsg { my $msg=shift; say $dHues{clryw}; mksep(); say $dHues{clr0} . $msg . $dHues{clryw}; mksep(); say $dHues{clr0};}
sub mkmsgc { my ($msg,$clr)=@_; mksepc($clr); say $msg; mksepc($clr); }
sub numtest { my $n=shift; my $rv=0; if(looks_like_number($n)){ $rv=1; } return $rv; }
sub roundXtoYdecimals { my ($f , $dp) = @_; return sprintf("%.".$dp."f", $f); }
sub doarfErrExit { 
  my $arf=shift; if(scalar(@$arf)<2){ say __LINE__. "Error: \"". join(" ;; ", @$arf) . "\""; exit(0); }
  else { my $Lint=shift @$arf; say mkbracketed($Lint) ." Error: ". join(". ", @$arf); exit(0); }
}
sub mkbracketed { my $m=shift; return " [ $m ] "; }
sub mkOrderedHash { tie my %dRVTie, 'Tie::IxHash'; return \%dRVTie; }

sub sendLLMreq { 
  my $hrf=shift; 
  mksep();mksep();
  say Dumper($hrf); 
  my $inQuery=$hrf->{question};
  if ($dAppStrs{bAppendQueryRules} == 1 ){ 
    say "Adding rules to the query: \"". $dAppStrs{queryRules} . "\"";
    $inQuery=$inQuery ." ". $dAppStrs{queryRules};
  }
  if( $hrf->{arg1type} eq $dLogic{tcsvint}  ){
    my @aModelInts=split(',', $hrf->{modelint});

    say "Using model numbers " . mkbracketed( join(" ;; ",@aModelInts) ); 
    
    for my $mint (@aModelInts){

      doarfErrExit([__LINE__, "\"". $mint . "\" not found in model list" ]) if (! exists $dAppState{hrfLUTModels}->{$mint} );
      my $modelnym=$dAppState{hrfLUTModels}->{$mint};

      my $jsdata = encode_json( { model => $modelnym , prompt => $inQuery , stream => JSON::PP->false }); 
      mksepc($dHues{clryw});
      say "Sending query to ($mint) \"$modelnym\" ...";

      my $rv = $dAppState{ua}->post(
          $dAppState{apiserver} . $dAPI{generate},
          'Content-Type' => 'application/json',
          Content        => $jsdata
      );

      mksepc($dHues{clryw});
      ### say $rv->content();
      
      try { 
        my $hrfRV = decode_json($rv->content()); 

        mksepc($dHues{clrgr});

        if( exists $hrfRV->{thinking} && exists $hrfRV->{response} ){ say "(Note: \"thinking\" models take more time to respond)"; mksep(); say $hrfRV->{response} ; }      
        elsif( exists $hrfRV->{response} ){ say $hrfRV->{response} ; }
        else { 
          say "Something went wrong. Response contains keys\n" . join("\n" , map { $_ . " (size=". length($hrfRV->{$_}) .")" } sort keys %$hrfRV);
          mksep(); say decode_json($rv->content());
        }##else
    
      } catch { mksepc($dHues{clrrd}); say "Something went wrong in processing the request."; mksepc($dHues{clrrd}); }; ##no finally

    }
  }##if tcsvint
  elsif( $hrf->{arg1type} eq $dLogic{tint}  ){
    doarfErrExit([__LINE__, "\"". $hrf->{modelint} . "\" not found in model list" ]) if (! exists $dAppState{hrfLUTModels}->{$hrf->{modelint}} );
    my $modelnym=$dAppState{hrfLUTModels}->{$hrf->{modelint}};

    my $jsdata = encode_json( { model => $modelnym , prompt => $inQuery , stream => JSON::PP->false }); 
    mksepc($dHues{clryw});
    say "Sending query to ($hrf->{modelint}) \"$modelnym\" ...";

    my $rv = $dAppState{ua}->post(
        $dAppState{apiserver} . $dAPI{generate},
        'Content-Type' => 'application/json',
        Content        => $jsdata
    );

    ###say $rv->content();  
    try { 

      my $hrfRV = decode_json($rv->content()); 
      mksepc($dHues{clrgr}); 
    
      if( exists $hrfRV->{thinking} && exists $hrfRV->{response} ){ say "(Note: \"thinking\" models take more time to respond)"; mksep(); say $hrfRV->{response} ; }      
      elsif( exists $hrfRV->{response} ){ say $hrfRV->{response} ; }
      else { 
        say "Something went wrong. Response contains keys\n" . join("\n" , map { $_ . " (size=". length($hrfRV->{$_}) .")" } sort keys %$hrfRV);
        mksep(); say decode_json($rv->content());
      }##else
        
    } 
    catch { mksepc($dHues{clrrd});  say "Something went wrong in processing the request."; mksepc($dHues{clrrd}); }; ##no finally

  }##elsif tint
  
}## end sendLLMreq

sub pullCurrentList {

  my $rvVer=$dAppState{ua}->get( $dAppState{apiserver} . $dAPI{version});
  my $jsRVVer=decode_json($rvVer->content());
  $rvVer=$jsRVVer->{version};

  my $rv=$dAppState{ua}->get( $dAppState{apiserver} . $dAPI{tags});
  my $jsRV=decode_json($rv->content());
  my $arfModels=$jsRV->{models};
  mkmsgc("Server version: >> $rvVer <<", $dHues{clryw} );

  say "Numbered list of models:";
  
  my $ordHModels=mkOrderedHash();
  $dAppState{hrfLUTModels}=$ordHModels;
  while ( my ($idx,$hrf)=each @$arfModels){
      my @aMN = split(':',$hrf->{name});
      say "$idx => " . $aMN[0];
      $ordHModels->{$idx}=$aMN[0];
      $ordHModels->{$aMN[0]}=$idx;
  }  

}## end pullCurrentList


sub doDoneMsg {
  $dAppState{tend}=time;
  mkmsgc( basename($0) ." response took " . ($dAppState{tend}-$dAppState{tstt}) ." seconds (" . roundXtoYdecimals(($dAppState{tend}-$dAppState{tstt})/60 , 3) . " minutes)." , $dHues{clrgr} );
  exit(0);
}

sub showHelp {
 mksepc($dHues{clrcyn});
 my $shortnym=basename($0); 
 say "Usage:";
 say "$shortnym <no arguments> (lists current local models)";
 say "$shortnym library (lists models available at ollama.com, requires Internet connexion)"; 
 say "$shortnym pull \"modelname\" (requires Internet connexion; obtain list of models using \"library\")"; 
 say "$shortnym modelint \"question\"";
 say "$shortnym int1,int2,int3 \"question\"";
 say "$shortnym all \"question\"";
 say "$shortnym delete \"modelname\" (deletes model from local server)"; 
 
 mksepc($dHues{clrcyn});
}


##############################################
##############
############## I N I T ##############
##############


mksepc($dHues{clrgr});
say basename($0) . "\n$0 running...";
#say mkbracketed(__LINE__). " parent path => " . $dAppState{parpath};
mksepc($dHues{clrgr});


$dAppState{ua} = LWP::UserAgent->new;
$dAppState{ua}->default_header('Content-Type' => 'application/json');

my $dataFileNym=basename($0)."_data.cfgtxt";

if( -e $dataFileNym ){ $dAppState{bconfig_found}=$dLogic{true}; $dAppState{bconfig_useabsdir}=$dLogic{false}; }
elsif( -e $dAppState{parpath}."/$dataFileNym"){ $dAppState{bconfig_found}=$dLogic{true}; $dAppState{bconfig_useabsdir}=$dLogic{true};}


say "Config file name = \"$dataFileNym\""; 
say "Property bconfig_found = " . $dAppState{bconfig_found};
say "Property bconfig_useabsdir = " . $dAppState{bconfig_useabsdir};

my $oConf = Config::Tiny->new;

if( $dAppState{bconfig_found} ){ 
  say "Reading data file \"$dataFileNym\" ... "; 

  my $pathConfFile=$dataFileNym;
  $pathConfFile = $dAppState{parpath}."/".$dataFileNym if $dAppState{bconfig_useabsdir}==$dLogic{true};

   my $hrfcfg = $oConf->read($pathConfFile);
   $dAppState{apiserver}=$hrfcfg->{Server}->{URL};
   $dAppState{bAppendQueryRules} = $hrfcfg->{Logic}->{bAppendQueryRules}; 
   

}
elsif( ! $dAppState{bconfig_found} ){ ### create a config file 
 say "Create a configuration...";
 my $EPtest=getkbinput("Enter an API endpoint URL to use (e.g. http://xxx.xxx.xxx.xxx.:portnum) :");

 my $rv=$dAppState{ua}->get( $EPtest . $dAPI{tags});
 say "Testing the endpoint...";
  if ($rv->is_success) {
    mksepc($dHues{clrgr});
    say $rv->content;
    mksep();


   $oConf->{Server} = { "URL" => $EPtest }; 
   $oConf->{Logic} = { "bAppendQueryRules" => 1 }; 
   
   $oConf->write($dataFileNym); 
   $dAppState{apiserver}=$EPtest;   
    
  } else { ### FAILED, alert and exit
    mkmsgc("Failed to query the endpoint \"$EPtest\"", $dHues{clrrd});
    say $rv->status_line;
    mksep();
    exit(0);
  } 
} 

##############
############## M A I N ##############
##############

pullCurrentList(); 

mksepc( $dHues{clryw} );

if(scalar(@ARGV)==0){ showHelp(); exit(0); }
elsif(lc($ARGV[0]) eq "library" ){ ##################################################### LIBRARY
 say "Reading the latest Ollama library page...";
 #curl -s https://ollama.com/library | grep -oP 'href="/library/\K[^"]+' | sort
 my $rv = $dAppState{ua}->get("https://ollama.com/library?sort=newest"); ### calling ollama with sort parameter
 my $ohLibrary=mkOrderedHash(); 
 my %dLUTbIsCloud=();

 if ( ! $rv->is_success) { 
  mksepc($dHues{clrrd}); say $rv->status_line; say $rv->{content}; doarfErrExit( [__LINE__, "library request failed" ] ); 
 }

 my $resp=$rv->content();
 # >cloud</span> ###<<<--- Indicates a cloud model (requires Internet)
 my %dlocModelwords=();
 while ( $resp =~ m{a href=\"\/library\/(\S+)\"}g) {
  my $mnym=$1; chomp($mnym);
  $ohLibrary->{$mnym}=$-[0] ; #say "library model $1";
  $dlocModelwords{$-[0]}=$mnym;
  $dLUTbIsCloud{$mnym}=$dLogic{false};  
 }
 while ( $resp =~ m{>cloud<\/span>}g) {  
  $dlocModelwords{$-[0]}="cloud";  
 }
 
 say "Ollama library models: " . scalar(keys %$ohLibrary);
 mksepc($dHues{clrgr});
 my $iCols=0;
 my @sorted_keys = sort { length($a) <=> length($b) } keys %$ohLibrary; ## order name strings by length for layout
 my $maxlen=length($sorted_keys[-1])+4; ###<<<=== ensure value of 1 at least  
 my $firstchar="a";
 for my $ky (sort keys %$ohLibrary){
    my $mpos=$ohLibrary->{$ky}; 
    my @aLocs=sort {$a<=>$b} keys %dlocModelwords; 
    my $bIsCM=0;
    my $bCheckNext=0;
    while ( my ($widx,$LCval)=each @aLocs) { 
      if($LCval < $mpos){ next; } 
      elsif($LCval==$mpos){ $bCheckNext=1; next; }
      elsif($bCheckNext==1 && $dlocModelwords{$LCval} eq "cloud"){ $bIsCM=1; $dLUTbIsCloud{$ky}=$dLogic{true}; last; }
      else{ last; }
    }
    my $currchar1=substr($ky, 0, 1);
    if($currchar1 ne $firstchar){ 
      say "\n$dHues{clryw}-----$dHues{clr0}";
      $firstchar=$currchar1; ### add alphbetical separator 
      $iCols=0;
    } elsif($iCols>3){ $iCols=0; print "\n"; }
    
    if( $bIsCM==1 ) { print "$dHues{clrcyn}$ky$dHues{clr0}" . ' ' x ($maxlen-length($ky)) ; }
    else { print $ky . ' ' x ($maxlen-length($ky)); }
    $iCols++; 

 }

 ### Most recent LLMs #https://ollama.com/library?sort=newest
 ### Show the five latest models
 my $limit=5; 
 say "\n";
 mksepc($dHues{clrgr});
 say "Most recently updated models in library: ". mkbracketed( join(" ;; ", map { $dLUTbIsCloud{$_}==$dLogic{true}?"$dHues{clrcyn}$_$dHues{clr0}":$_ } (keys %$ohLibrary )[0..$limit] ) );

 mkmsgc( "$dHues{clrcyn}colour$dHues{clr0} indicates \"cloud model\" , not \"local-only\".\nRead more at: < https://ollama.com/library >." , $dHues{clrcyn}); 
 doDoneMsg();
}
elsif(lc($ARGV[0]) eq "pull" && scalar(@ARGV)==2 ){ ##################################################### PULL
 say "Pulling $ARGV[1] ...";

    my $jsdata = encode_json( { model => $ARGV[1] , stream => JSON::PP->false }); 
    mksepc($dHues{clryw});
    say "Sending pull request for \"$ARGV[1]\" ... (download speed depends on Internet connexion and the size of the LLM)";

    my $rv = $dAppState{ua}->post(
        $dAppState{apiserver} . $dAPI{pull},
        'Content-Type' => 'application/json',
        Content        => $jsdata
    );

  if ($rv->is_success) {
    mksepc($dHues{clrgr});
    say $rv->content;
    mksep();
  } else { mksepc($dHues{clrrd}); say $rv->content; }
    

 pullCurrentList();
 doDoneMsg();
}

elsif(lc($ARGV[0]) eq "delete" && scalar(@ARGV)==2 ){ ##################################################### DELETE
 say "Sending request to delete \"$ARGV[1]\" ... "; 

    my $jsdata = encode_json( { model => $ARGV[1] }); 
    mksepc($dHues{clryw});

    my $rv = $dAppState{ua}->delete(
        $dAppState{apiserver} . $dAPI{delete},
        'Content-Type' => 'application/json',
        Content        => $jsdata
    );

  if ($rv->is_success) {
    mksepc($dHues{clrgr});
    say "Success, deleted model \"$ARGV[1]\" ... ";
    mksep();
  } else { mksepc($dHues{clrrd}); say $rv->content; }
    
 pullCurrentList();
 doDoneMsg();
}

elsif(scalar(@ARGV)==2){
  if( lc($ARGV[0]) eq "all"){ ##################################################### QUERY ALL
    my $hLUTmdl=$dAppState{hrfLUTModels};
    mkmsgc( "Sending the query to ALL available models..." , $dHues{clrblu});
    for my $val (keys %$hLUTmdl){ if(numtest($val)){ my %dParms=( modelint => $val, question => $ARGV[1] , arg1type => $dLogic{tint} ); sendLLMreq(\%dParms); }} 
  }
  elsif( ! $ARGV[0] =~ /,/ && $ARGV[0] =~ /\d+/ ){ my %dParms=( modelint => $ARGV[0], question => $ARGV[1] , arg1type => $dLogic{tint} ); sendLLMreq(\%dParms); }
  elsif( $ARGV[0] =~ /(\d+)(,\d+)*/ ){ my %dParms=( modelint => $ARGV[0], question => $ARGV[1] , arg1type => $dLogic{tcsvint} ); sendLLMreq(\%dParms);  }
  else { mkmsgc("arg1 should be int|csvint, not \"$ARGV[0]\"" , $dHues{clrrd}); exit(0); }
}
else { mkmsgc("Wrong number of arguments" , $dHues{clrrd}); showHelp(); exit(0); }

doDoneMsg();
