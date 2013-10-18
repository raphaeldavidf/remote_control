# 
# Remote control v1.0
#
# This perl script is a simple web interface remote control for alsa sound and 
# umplayer. Can be easily be adapt for other players.
# 
# HOW TO USE:
# 
# Run the script on your computer. open a web browser in your favorite mobile
# device and acess "http://computer.ip.adress:9000".  
#
# Note that the computer and the mobile device must be in the same network
#
#
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Copyright 2013 Raphael David François
#
# getIPAdress function by chrisjarzebiak on 
# http://chrisjarzebiak.blogspot.com.br/2013/05/relearning-things-few-codes.html
#
#

#!/usr/bin/perl
use IO::Socket;

sub getIPAddress() {
    my $ifconfig = `which ifconfig`
        or return "UNDEFINED1";
    chomp $ifconfig;
    my @ifconfig_output = `$ifconfig -a 2>&1`
        or return "UNDEFINED2";

    my $interface;
    my $STATE;
    my $IP;
    foreach  (@ifconfig_output) {
        $interface = $1 if /^(\S+?):?\s/;
        next unless defined $interface;
        $STATE = uc($1) if /\b(up|down)\b/i;
        $IP = $1 if /inet\D+(\d+\.\d+\.\d+\.\d+)/i;
        if ( defined $STATE and $STATE eq "UP" ) {
            if ( defined $IP and $IP ne "0.0.0.0" and $IP ne "127.0.0.1" ) {
                return $IP;
            }
        }
    }
    return "UNDEFINED3";
}

my $IP_LOCAL = getIPAddress();

my $HEADER = <<HTML_HEADER;
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8


HTML_HEADER

my $PAGE1 = <<HTML_PAGE1;
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<title></title>
</head>
<body bgcolor="#000000" text="ffffff">
<div align="center">
<table  style="height:200px; width:500x">
<tr>
	<td colspan="3"><div style="text-align: center; font-size: 30px">Volume</div></td>
</tr>
HTML_PAGE1

my $PAGE3 = <<HTML_PAGE3;
<tr>
	<td>
		<div style="text-align: center"><a href="http://$IP_LOCAL:9000/vol_up_master" style="text-decoration: none"><input style="font-size: 180px; height: 200px; width: 200px" type="button" value="+" /></div>
		<div style="text-align: center"><a href="http://$IP_LOCAL:9000/vol_down_master" style="text-decoration: none"><input style="font-size: 180px; height: 200px; width: 200px" type="button" value="-" /></div>
	</td>
	<td></td>
	<td>
		<div style="text-align: center"><a href="http://$IP_LOCAL:9000/vol_up_umplayer" style="text-decoration: none"><input style="font-size: 180px; height: 200px; width: 200px" type="button" value="+" /></div>
		<div style="text-align: center"><a href="http://$IP_LOCAL:9000/vol_down_umplayer" style="text-decoration: none"><input style="font-size: 180px; height: 200px; width: 200px" type="button" value="-" /></div>	
	</td>
</tr>
<tr>
	<td colspan="3"><div style="text-align: center; font-size: 30px"><br>Umplayer</div></td>
</tr>
<tr>
	<td colspan="3"><div style="text-align: center"><a href="http://$IP_LOCAL:9000/play_pause_umplayer" style="text-decoration: none"><input style="font-size: 80px; height: 200px; width: 520px" type="button" value="PLAY/PAUSE" /></div></td>	
</tr>
<tr>
	<td colspan="3"><div style="text-align: center"><a href="http://$IP_LOCAL:9000/rewind_umplayer" style="text-decoration: none"><input style="font-size: 80px; height: 200px; width: 200px" type="button" value="<<" /><a href="http://$IP_LOCAL:9000/forward_umplayer" style="text-decoration: none"><input style="font-size: 80px; height: 200px; width: 200px" type="button" value=">>" /></div></td>	
</tr>
</table>
</div>
</body>
</body>
</html>
HTML_PAGE3

$port = 9000;
$server = IO::Socket::INET->new( Proto     => 'tcp',
                                 LocalPort => $port,
                                 Listen    => SOMAXCONN,
                                 Reuse     => 1 );

die "server error" unless $server;

while ($client = $server->accept()) {
	$client->autoflush(1);
	$i = 0;
	while (<$client>) {
		if ($i == 0) {	
			if ($_ =~ /vol_up_master/) {
				print "VOL_UP\n";
				$out = `amixer sset Master 5+`;
			}	
			elsif ($_ =~ /vol_down_master/)	{
				print "VOL_DOWN\n";
				$out = `amixer sset Master 5-`;
			}
			elsif ($_ =~ /vol_up_umplayer/)	{
				print "VOL_UP_UMPLAYER\n";
				$out = `umplayer -send-action increase_volume`;
			}
			elsif ($_ =~ /vol_down_umplayer/) {
				print "VOL_DOWN_UMPLAYER\n";
				$out = `umplayer -send-action decrease_volume`;
			}
			elsif ($_ =~ /rewind_umplayer/) {
				print "BACK_UMPLAYER\n";
				$out = `umplayer -send-action rewind1`;
			}
			elsif ($_ =~ /forward_umplayer/) {
				print "FORWARD_UMPLAYER\n";
				$out = `umplayer -send-action forward1`;
			}
			elsif ($_ =~ /play_pause/) {
				print "PLAY_PAUSE\n";
				$out = `umplayer -send-action pause`;
			}
			else {
				print ".\n";
			}
			
			my $MASTER_VOL = `amixer get Master | grep %| cut -d ' ' -f 6`;
			
			$PAGE2 = <<HTML_PAGE2;
<tr>
<td width=40%><div style="text-align: center; font-size: 25px"> Master <b>$MASTER_VOL</b></div></td>
<td width=20%><div style="text-align: center"></div></td>
<td width=40%><div style="text-align: center; font-size: 25px"> Umplayer <b>?%</b></div></td>
</tr>
HTML_PAGE2
			
			print $client "$HEADER $PAGE1.$PAGE2.$PAGE3";
			$i=1;
			close $client;
			last;
		}
	}
} 
close $client;
