# --
# Kernel/Output/HTML/DashboardTicketOverview.pm
# Copyright (C) 2013 Daniel Obée
# --
# $Id: 
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::DashboardTicketOverview;

use strict;
use warnings;

use vars qw($VERSION);                                                                 
$VERSION = qw($Revision: 1.31 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for (qw(ParamObject LayoutObject ConfigObject QueueObject TicketObject)) {
        if ( !$Self->{$_} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $_!" );
        }
    }

    return $Self;
}

sub Preferences {
    my ( $Self, %Param ) = @_;

    return;
}

sub Config {
    my ( $Self, %Param ) = @_;

    return (
        %{ $Self->{Config} }
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get queues
 	  my %Queues = $Self->{QueueObject}->GetAllQueues( 
        UserID => $Self->{UserID}, 
        Type => $Self->{Config}->{DisplayBy} 
    );

    my %Total = (
                Name      => 'Sum' ,
    );
    
    #create list of queues with open Tickets
#    foreach my $QueueID ( keys %Queues ) {
#    my $QueueID;
    foreach my $QueueID (sort { $Queues{$a} cmp $Queues{$b} } keys %Queues ) {

        #exclude queues from config
        next if $QueueID == $Self->{Config}->{QueueExcluded} ;

        my @OpenTickets;
        
        # tickets day 0-8
        foreach (0, 24, 48, 72, 96, 120, 144, 168, 192) {
            my $TicketIDs = $Self->{TicketObject}->TicketSearch(
                Result     => 'COUNT' ,
                QueueIDs   =>  [ $QueueID ] ,
                StateTypeIDs  => [ 1, 2, 4, 5 ] ,
                UserID     => $Self->{UserID} ,
                Type       => $Self->{Config}->{DisplayBy} ,
                CacheTTL   => 60 * 3 ,
                TicketCreateTimeOlderMinutes => 60 * $_ ,
                TicketCreateTimeNewerMinutes => 60 * ($_ + 24) ,          
            );

            # don't display 0 except <24h
            $TicketIDs = undef if $TicketIDs == 0 && $_ != 0; 

            push (@OpenTickets, $TicketIDs);
        }

        # tickets day 9
        my $TicketIDs = $Self->{TicketObject}->TicketSearch(
            Result     => 'COUNT' ,
            QueueIDs   =>  [ $QueueID ] ,
            StateTypeIDs  => [ 1, 2, 4, 5 ] ,
            UserID     => $Self->{UserID} ,
            Type       => $Self->{Config}->{DisplayBy} ,
            CacheTTL   => 60 * 3 ,
            TicketCreateTimeOlderMinutes => 60 * 216,
        );            

        # don't display 0
        $TicketIDs = undef if $TicketIDs == 0; 

        push (@OpenTickets, $TicketIDs);

        # Werte Summieren
        my $Sum;
        $Sum += $_ for @OpenTickets;
        # Leerzeilen unterdrücken
        next if $Sum == 0;
        # <24h rausrechnen
        $Sum -= $OpenTickets[0];
        push (@OpenTickets, $Sum);

        # add up Total
        $Total{'Day1'} += $OpenTickets[0]; 
        $Total{'Day2'} += $OpenTickets[1]; 
        $Total{'Day3'} += $OpenTickets[2]; 
        $Total{'Day4'} += $OpenTickets[3]; 
        $Total{'Day5'} += $OpenTickets[4]; 
        $Total{'Day6'} += $OpenTickets[5]; 
        $Total{'Day7'} += $OpenTickets[6]; 
        $Total{'Day8'} += $OpenTickets[7]; 
        $Total{'Day9'} += $OpenTickets[8]; 
        $Total{'Day10'} += $OpenTickets[9]; 
        $Total{'Sum'} += $Sum; 

        $Self->{LayoutObject}->Block(
            Name => 'ContentLargeTicketOverView',
            Data => {
                Name      => $Queues{$QueueID} ,
                QueueID   => $QueueID,
                Day1      => $OpenTickets[0] ,
                Day2      => $OpenTickets[1] ,
                Day3      => $OpenTickets[2] ,
                Day4      => $OpenTickets[3] ,
                Day5      => $OpenTickets[4] ,
                Day6      => $OpenTickets[5] ,
                Day7      => $OpenTickets[6] ,
                Day8      => $OpenTickets[7] ,
                Day9      => $OpenTickets[8] ,
                Day10     => $OpenTickets[9] ,
                Sum       => $OpenTickets[10] ,
            },
        );
    }

        $Self->{LayoutObject}->Block(
            Name => 'ContentLargeTicketOverViewSum',
            Data => \%Total ,
        );
 
     	   	  
# build output
    my $Output = $Self->{LayoutObject}->Output(
        TemplateFile => 'AgentDashboardTicketOverview',
        Data         => \%Param,
    );

    return $Output;
}

1;
