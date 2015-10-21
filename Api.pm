#!/usr/bin/perl -w
package Api;

use strict;
use JSON -support_by_pp;
use JSON::RPC::Client;
use warnings;
use LWP::Simple;
use LWP::UserAgent;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use String::Random;
use bignum;
use URI::Encode;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(GET POST getFreeAccount);
%EXPORT_TAGS = ( DEFAULT => [] );

$| = 1;

our $port;
our $host;
my $lwp;
my $json;
my $client;
my $url;

BEGIN {
	$lwp = LWP::UserAgent->new;
	$lwp->agent("perl $]");
	$json = new JSON;

	$client = new JSON::RPC::Client;
	$url = URI::Encode->new({encode_reserved => 1, double_encode => 1});

	$port = $port;
	$host = $host;
}

END {
}

sub getJSON {
        my ($raw) = shift;
        my $res = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($raw->content);
        return $res;
};

sub buildContent {
        my ($req) = shift;
	my $con;

	foreach my $key (keys %{ $req }) 
	{
		my $atr = $url->encode($key).'='.$url->encode($req->{$key});
    		$con = defined $con ? $con.'&'.$atr : $atr;
	}

	return $con;	
}

sub getHostPort {
	return 'http://'.$host.':'.$port.'/nxt';	
}

sub buildURI {
        my ($req) = shift;
	return getHostPort().'?'.buildContent($req);
}

sub GET {
        my ($req) = shift;
        my $res = $lwp->request(HTTP::Request->new(GET => buildURI($req)));
        my $ans = getJSON($res);
        return $ans;
}

sub POST {
        my ($req) = shift;
        my $request = HTTP::Request->new(POST => getHostPort());
        $request->content_type('application/x-www-form-urlencoded');
        $request->content(buildContent($req));
        my $res = $lwp->request($request);
        die "Request failed!" unless $res->is_success;
        my $ans = getJSON($res);
        return $ans;
}

sub getFreeAccount {
        my ($sec) = shift;

	my $ref = GET({ 'requestType' => 'getAccountId', 'secretPhrase' => $sec });
        #print Dumper($ref);
	my $pub = GET({ 'requestType' => 'getAccountPublicKey', 'account' => $ref->{accountRS} });
        my $ret;
        #print Dumper($pub);

        if($pub->{errorCode} == 5)
        {
		my $txs = GET({ 'requestType' => 'getBlockchainTransactions', 'account' => $ref->{accountRS}, 'timestamp' => 0  });
                #print Dumper($txs);
                if($txs->{errorCode} == 5)
                {
                        $ret = $ref;
                }
        }

        return $ret;
};

1;
