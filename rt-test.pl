#!/usr/bin/perl -w
# Copyright (C) 2005, 2006   Software Freedom Law Center, Inc.
# Author: Orion Montoya <orion@mdcclv.com>
#
# This software gives you freedom; it is licensed to you under version
# 3 of the GNU Affero General Public License, along with the
# additional permission in the following paragraph.
#
# This notice constitutes a grant of such permission as is necessary
# to combine or link this software, or a modified version of it, with
# Request Tracker (RT), published by Jesse Vincent and Best Practical
# Solutions, LLC, or a derivative work of RT, and to copy, modify, and
# distribute the resulting work.  RT is licensed under version 2 of
# the GNU General Public License.
# 
# This software is distributed WITHOUT ANY WARRANTY, without even the
# implied warranties of MERCHANTABILITY and FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU Affero General Public License for further
# details.
#  
# You should have received a copy of the GNU Affero General Public
# License, version 3, and the GNU General Public License, version 2,
# along with this software.  If not, see <http://www.gnu.org/licenses/>.

use CGI qw(:standard);
use lib '/usr/share/request-tracker3.4/lib/';
use lib '/etc/request-tracker3.4/';

use lib '/usr/share/request-tracker3.2/lib/';
use lib '/etc/request-tracker3.2/';

use MIME::Base64;
use Frontier::Client;


use RT::Interface::CLI qw(CleanEnv GetCurrentUser GetMessageContent);
use RT::Interface::Web;

use RT;
RT::LoadConfig();
RT::Init();
use RT::Ticket;
use RT::Transactions;
use RT::CurrentUser;
use RT::CustomField;
use Data::Dumper;

sub debug {
    print STDERR @_ . "\n";

}

$printargs = "default (20 most recent comments)";

if (($name, $pass) = split(/:/, decode_base64(cookie('__ac')))) {

    $name =~ s/\"//g;
    $server = Frontier::Client->new(url => "http://gplv3.fsf.org:8800/launch/acl_users/Users/acl_users",
				    username => "stet_auth",
				    password =>  "fai1Iegh");
    
    
    $resp = $server->call('authRemoteUser',$name,$pass);
}
else {
    ${$resp} = 0;
}

if (${$resp} == 0) {
    print STDERR "auth boolean was 0\n";
}


#my $CurrentUser = RT::Interface::CLI::GetCurrentUser();
#my $CustomFieldObj = RT::CustomField->new($CurrentUser);

#my $Query;
#if(param()) {
#    $NoteUrl = param('NoteUrl');
# }
my $CurrentUser = $RT::SystemUser;
my $TicketObj = new RT::Tickets( $CurrentUser );
if (param('WatcherOp') == "LIKE") {
    $arg = "%".param('ValueOfWatcher')."%";
}
else {
    $arg = param('ValueOfWatcher');
}
$Query = param('WatcherField')." ".param('WatcherOp'). 'Requestor.Name LIKE "%'.param('ValueOfWatcher').'%"'
$TicketObj->FromSQL($Query);
%session = '';
# as a result of next line, searches are *not* sticky.

%ARGS = param();
$TicketObj->Query();
&LimitByArgs;




# $TicketObj->FromSQL($Query);

# $TicketObj->LimitCustomField(
# 			     CUSTOMFIELD => 3,
# 			     VALUE => $NoteUrl,
# 			     OPERATOR => "="
# 			     );


$count = $TicketObj->CountAll();
print STDERR $TicketObj->loc("Found [quant,_1,annotation].\n",$count);

print header('text/xml');
my $returnme;
$returnme .=  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'."\n";
$returnme .= "<response>\n";
$TicketObj->GotoFirstItem();
my $annotation;
while (my $item = $TicketObj->Next) {
    $annotation = "";
    my $Transactions = $item->Transactions;
    while (my $Transaction = $Transactions->Next) {
	next unless ($Transaction->Type =~ /^(Create|Correspond|Comment$)/);
		     
	my $attachments = $Transaction->Attachments;
#    my $CustomFields = $item->QueueObj->TicketCustomFields();
	my $CustomFields = $item->QueueObj->CustomFields();
	$attachments->GotoFirstItem;
	my $message = $attachments->Next;
	$annotation .= $message->Content;
    }

	$showagree = '';	
	$agr_vals = $item->CustomFieldValues(7);
	if ($$resp == 1) {

	    while ($value = $agr_vals->Next) {
		if (($name) && ($value->Content eq $name)) {
		    print STDERR "the user agrees with ".$item->id."\n";
#		    $showagree = "<a label=\"you have indicated that you agree with this\" name=\"you have indicated that you agree with this\">unagree</a>";
		    $showagree = "unagree";
		}
	    }
	    if (!$showagree) {
		$showagree = "agree";
	    }
	}
	else {
	    $showagree = "<a href=\"gplv3.fsf.org:8800/launch/login_form\">login</a> to agree";
	    
	}
	
#print "ticket has ".$values->count." customfieldvalues\n";

#
#    my $Attachs = $item->TransactionObj->Attachments->First;
#    my $content = $Attachs->Content;
# while (my $CustomField = $CustomFields->Next()) {
# my $CustomFieldValues=$Ticket->CustomFieldValues($CustomField->Id);
	$returnme .= "<cs>Currently showing: $printargs.  <a href=\"javascript:newQuery()\">change</a></cs>\n";
	  $returnme .= "<annotation>\n";
#    $returnme .= " <url>" . $item->FirstCustomFieldValue('NoteUrl') . "</url>\n";
#    $returnme .= " <dompath>" . $item->FirstCustomFieldValue('NoteDomPath') . "</dompath>\n";
	  $returnme .= " <n>$annotation</n>\n";
	  $returnme .= " <e>" . $item->FirstCustomFieldValue('NoteEndNodeId') . "</e>\n";
	  $noteSelection = $item->FirstCustomFieldValue('NoteSelection');
	  $noteSelection =~ s/</&lt;/g;
	  $noteSelection =~ s/>/&gt;/g;
	  $returnme .= " <s>" . $noteSelection . "</s>\n"; 
	  $returnme .= " <i>" . $item->FirstCustomFieldValue('NoteStartNodeId') . "</i>\n";
	  $returnme .= " <u>" . $item->Requestors->MemberEmailAddressesAsString . "</u>\n";
	  $returnme .= " <ua>" . $showagree . "</ua>\n";
	  $returnme .= " <at>" . $agr_vals->count . "</at>\n";
	  $returnme .= " <id>" . $item->id . "</id>\n";
	  $returnme .= "</annotation>\n";
	  
#    print STDERR Dumper($item);
#	  print STDERR $item->requestors;
    }

$returnme .= "</response>\n";
#    printf ("%s", $item->CustomField-3);

print $returnme;
#print Dumper($TicketObj);

# LimitByArgs adapted from $RT/lib/Interface/Web.pm's ProcessSearchQuery
# (out of desperation)

sub LimitByArgs {

    # {{{ Limit priority
    if ( param('ValueOfPriority') ne '' ) {
        $TicketObj->LimitPriority(
            VALUE    => param('ValueOfPriority'),
            OPERATOR => param('PriorityOp')
        );
	debug('limiting by '.param('ValueOfPriority'));
    }

    # }}}
    # {{{ Limit owner
    if ( param('ValueOfOwner') ne '' ) {
        $TicketObj->LimitOwner(
            VALUE    => param('ValueOfOwner'),
            OPERATOR => param('OwnerOp')
        );
	debug('limiting by '.param('ValueOfOwner'));
    }

    # }}}
    # {{{ Limit requestor email
     if ( param('ValueOfWatcher') ne '' ) {
	 my ($field, $property) = split(/\./,param('WatcherField'));
         $TicketObj->LimitWatcher(
#             TYPE     => $field,
             VALUE    => param('ValueOfWatcher'),
             OPERATOR => param('WatcherOp'),

        );
	debug('limiting by '.param('ValueOfWatcher'));
    }

    # }}}
    # {{{ Limit Queue
    if ( param('ValueOfQueue') ne '' ) {
        $TicketObj->LimitQueue(
            VALUE    => param('ValueOfQueue'),
            OPERATOR => param('QueueOp')
        );
	debug('limiting by '.param('ValueOfQueue'));
    }

    # }}}
    # {{{ Limit Status
    if ( param('ValueOfStatus') ne '' ) {
        if ( ref( param('ValueOfStatus') ) ) {
            foreach my $value ( @{ param('ValueOfStatus') } ) {
                $TicketObj->LimitStatus(
                    VALUE    => $value,
                    OPERATOR => param('StatusOp'),
                );
            }
	    debug('limiting by '.@{param('ValueOfStatus')}[0]);
        }
        else {
            $TicketObj->LimitStatus(
                VALUE    => param('ValueOfStatus'),
                OPERATOR => param('StatusOp'),
            );
	    debug('limiting by '.param('ValueOfStatus'));
        }

    }

    # }}}
    # {{{ Limit Subject
    if ( param('ValueOfSubject') ne '' ) {
            my $val = param('ValueOfSubject');
        if (param('SubjectOp') =~ /like/) {
            $val = "%".$val."%";
        }
        $TicketObj->LimitSubject(
            VALUE    => $val,
            OPERATOR => param('SubjectOp'),
        );
	debug('limiting by '.$val);
    }

    # }}}    
    # {{{ Limit Dates
    if ( param('ValueOfDate') ne '' ) {
        my $date = ParseDateToISO( param('ValueOfDate') );
        ARGS{'DateType'} =~ s/_Date$//;

        if ( ARGS{'DateType'} eq 'Updated' ) {
            $TicketObj->LimitTransactionDate(
                                            VALUE    => $date,
                                            OPERATOR => param('DateOp'),
            );
        }
        else {
            $TicketObj->LimitDate( FIELD => ARGS{'DateType'},
                                            VALUE => $date,
                                            OPERATOR => param('DateOp'),
            );
        }
    }

    # }}}    
    # {{{ Limit Content
    if ( param('ValueOfAttachmentField') ne '' ) {
        my $val = param('ValueOfAttachmentField');
        if (param('AttachmentFieldOp') =~ /like/) {
            $val = "%".$val."%";
        }
        $TicketObj->Limit(
            FIELD   => param('AttachmentField'),
            VALUE    => $val,
            OPERATOR => param('AttachmentFieldOp'),
        );
    }

    # }}}   

 # {{{ Limit CustomFields

    foreach my $arg ( keys %ARGS ) {
        my $id;
        if ( $arg =~ /^CustomField(\d+)$/ ) {
            $id = $1;
        }
        else {
            next;
        }
        next unless ( param($arg) );

        my $form = param($arg);
        my $oper = param->{ "CustomFieldOp" . $id };
        foreach my $value ( ref($form) ? @{$form} : ($form) ) {
            my $quote = 1;
            if ($oper =~ /like/i) {
                $value = "%".$value."%";
            }
            if ( $value =~ /^null$/i ) {

                #Don't quote the string 'null'
                $quote = 0;

                # Convert the operator to something apropriate for nulls
                $oper = 'IS'     if ( $oper eq '=' );
                $oper = 'IS NOT' if ( $oper eq '!=' );
            }
            $TicketObj->LimitCustomField( CUSTOMFIELD => $id,
                                                   OPERATOR    => $oper,
                                                   QUOTEVALUE  => $quote,
                                                   VALUE       => $value );
        }
    }


}
# {{{ sub ParseDateToISO

=head2 ParseDateToISO

Takes a date in an arbitrary format.
Returns an ISO date and time in GMT

=cut

sub ParseDateToISO {
    my $date = shift;

    my $date_obj = RT::Date->new($session{'CurrentUser'});
    $date_obj->Set(
        Format => 'unknown',
        Value  => $date
    );
    return ( $date_obj->ISO );
}

# }}}



=cut

# http://gplv3.fsf.org/stet/rt-test.pl?SearchId=new
Query=
Format=%27+++%3Cb%3E%3Ca+href%3D%22%2Frt%2FTicket%2FDisplay.html%3Fid%3D__id__%22%3E__id__%3C%2Fa%3E%3C%2Fb%3E%2FTITLE%3A%23%27%2C+%0D%0A%27%3Cb%3E%3Ca+href%3D%22%2Frt%2FTicket%2FDisplay.html%3Fid%3D__id__%22%3E__Subject__%3C%2Fa%3E%3C%2Fb%3E%2FTITLE%3ASubject%27%2C+%0D%0A%27__Status__%27%2C+%0D%0A%27__QueueName__%27%2C+%0D%0A%27__OwnerName__%27%2C+%0D%0A%27__Priority__%27%2C+%0D%0A%27__NEWLINE__%27%2C+%0D%0A%27%27%2C+%0D%0A%27%3Csmall%3E__Requestors__%3C%2Fsmall%3E%27%2C+%0D%0A%27%3Csmall%3E__CreatedRelative__%3C%2Fsmall%3E%27%2C+%0D%0A%27%3Csmall%3E__ToldRelative__%3C%2Fsmall%3E%27%2C+%0D%0A%27%3Csmall%3E__LastUpdatedRelative__%3C%2Fsmall%3E%27%2C+%0D%0A%27%3Csmall%3E__TimeLeft__%3C%2Fsmall%3E%27
AndOr=AND
AttachmentField=Subject
AttachmentOp=LIKE
ValueOfAttachment=
QueueOp=%3D
ValueOfQueue=
StatusOp=%3D
ValueOfStatus=
ActorField=Owner
ActorOp=%3D
ValueOfActor=
WatcherField=Requestor.Name
WatcherOp=LIKE
ValueOfWatcher=orion
DateField=Created
DateOp=%3C
ValueOfDate=
TimeField=TimeWorked
TimeOp=%3C
ValueOfTime=
PriorityField=Priority
PriorityOp=%3C
ValueOfPriority=
LinksField=HasMember
LinksOp=%3D
ValueOfLinks=
idOp=%3C
ValueOfid=
%27CF.NoteSelection%27Op=LIKE
ValueOf%27CF.NoteSelection%27=
%27CF.NoteDomPath%27Op=LIKE
ValueOf%27CF.NoteDomPath%27=
%27CF.NoteUrl%27Op=LIKE
ValueOf%27CF.NoteUrl%27=
%27CF.NoteStartNodeId%27Op=LIKE
ValueOf%27CF.NoteStartNodeId%27=
%27CF.NoteEndNodeId%27Op=LIKE
ValueOf%27CF.NoteEndNodeId%27=
%27CF.NoteText%27Op=LIKE
ValueOf%27CF.NoteText%27=
%27CF.Agreeers%27Op=LIKE
ValueOf%27CF.Agreeers%27=
AddClause=Add
Owner=RT%3A%3AUser-12
Description=
LoadSavedSearch=
Link=None
Title=
Size=
Face=
OrderBy=id
Order=ASC
RowsPerPage=50
