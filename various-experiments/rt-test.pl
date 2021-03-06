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
use RT::Interface::CLI qw(CleanEnv GetCurrentUser GetMessageContent);


use RT;
RT::LoadConfig();
RT::Init();
use RT::Ticket;
use RT::Transactions;
use RT::CurrentUser;
use RT::CustomField;
use Data::Dumper;
my $CurrentUser = RT::Interface::CLI::GetCurrentUser();
my $CustomFieldObj = RT::CustomField->new($CurrentUser);
#my $Query= " Requestor.EmailAddress LIKE 'moglen' ";
my $Query;
 if(param()) {

     $NoteUrl = param('NoteUrl');
#     $Query = " CustomFields.NoteUrl LIKE '$NoteUrl' ";
 }
# else {
    $Query= " Requestor.EmailAddress LIKE 'moglen' ";
#}

my $TicketObj = new RT::Tickets( $RT::SystemUser );
$TicketObj->FromSQL($Query);
$TicketObj->Query();
$TicketObj->LimitCustomField(
     CUSTOMFIELD => 3,
     VALUE => $NoteUrl,
     OPERATOR => "="
);
$count = $TicketObj->CountAll();
#print $TicketObj->loc("Found [quant,_1,annotation].\n",$count);

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
     my $CustomFields = $item->QueueObj->TicketCustomFields();
    $attachments->GotoFirstItem;
    my $message = $attachments->Next;
    $annotation .= $message->Content;
}
#
#    my $Attachs = $item->TransactionObj->Attachments->First;
#    my $content = $Attachs->Content;
# while (my $CustomField = $CustomFields->Next()) {
# my $CustomFieldValues=$Ticket->CustomFieldValues($CustomField->Id);
    $returnme .= "<annotation>\n";
#    $returnme .= " <url>" . $item->FirstCustomFieldValue('NoteUrl') . "</url>\n";
#    $returnme .= " <dompath>" . $item->FirstCustomFieldValue('NoteDomPath') . "</dompath>\n";
    $returnme .= " <n>$annotation</n>\n";
    $returnme .= " <e>" . $item->FirstCustomFieldValue('NoteEndNodeId') . "</e>\n";
    $returnme .= " <s>" . $item->FirstCustomFieldValue('NoteSelection') . "</s>\n"; 
    $returnme .= " <i>" . $item->FirstCustomFieldValue('NoteStartNodeId') . "</i>\n";

	  $returnme .= " <id>" . $item->id . "</id>\n";
    $returnme .= "</annotation>\n";

#    print Dumper($content);

    }

$returnme .= "</response>\n";
#    printf ("%s", $item->CustomField-3);

print $returnme;
#print Dumper($TicketObj);
