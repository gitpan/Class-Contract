#! /usr/local/bin/perl -w

# NOTES:
#	Invariants and pre- and post-conditions are expected
#       to return undef if they fail.
#
#	Pre- and post-conditions receive the same argument list
#	as the implementation itself. Methods and constructors
#	may have as many pre- and post-conditions as they
#	require.
#
#	Pre- and post-conditions and invariants may be declared
#	optional. Optional conditions may be switched on and off
#	using the &check method (see examples below).
#
#	The subroutine &self always returns a reference to
#	the invoking object. However, that reference is still
#	also passed as the first argument.
#
#	The implementation's return value is available in the
#	method's post-condition(s) through the subroutine
#	&value, which returns a reference to a scalar or an array
#	(depending on the calling context).
#
#	&value also provides access to the value of an attribute within
#	that attribute's pre- and post-conditions.
#
#	The value of the object prior to a method is available in the
#	post-conditions via the &old subroutine, which returns a copy
#	of the object as it was prior to the method call.
#
#	Methods can be declared abstract. They croak if not redefined.
#	
#	Class methods and attributes can be declared.
#
#	The constructor implementation is invoked *after* the object
#	is created and blessed into the class. It only needs to
#	initialize the object returned by &self. Its return value is ignored.
#
#	The implementations of all base class constructors are called
#	automatically by the derived class constructor (and passed
#	the same argument list)
#
#	Attributes are private to the class in which they're declared.
#	Attributes cannot be accessed directly, only via their 
# 	accessor methods. This is true even within class methods.
#	All generated accessors return a reference to their attribute.
#
#	Accessors may only have preconditions.
#
#	Accessors and methods inherit (all) the preconditions of 
#	every ancestral accessor or method of the same name.
#

package QueueBase;
use Class::Contract;

contract
{
	abstract method 'append';

	abstract method 'next';

	ctor 'new';
		impl { print "QueueBase::new!\n" }
};


package ClientQueue;
use Class::Contract;


contract 
{
	inherits QueueBase;


	invar { print "appends: ", self->flags->{append}||0, "\n"; };
	invar { print "nexts:   ", self->flags->{next}||0, "\n"; };
	optional invar { @{self->queue}> 0 || undef };
		failmsg "Empty queue detected at %s after call";

	attr queue => ARRAY;
	attr flags => HASH;
	class attr 'first';

	method 'append';
		optional pre  { print "first append\n" if ${self->first};  1; };

		pre  { print "<<<0>>>\n";
		       return unless $_[1]->isa("Client");
		       print "<<<0.1>>>\n";
		       1;
		     };

		post { return unless @{self->queue} == @{old->queue} + 1;
		       return unless self->queue->[-1]{id} == $_[1]{id};
		       return 1;
		     };

		impl { print "<<<1>>>\n";
		       ${self->first} = 0;
		       print "<<<2>>>\n";
		       self->flags->{append}++;
		       print "<<<3>>>\n";
		       push @{self->queue}, $_[1];
		       print "<<<4>>>\n";
		     };

	method 'next';
		post { return unless @{self->queue} == @{old->queue} - 1;
		       return 1;
		     };
		     failmsg "Expected removal of a single Client object";

		impl {
			self->flags->{next}++;
			shift @{self->queue}
		     };


	ctor 'new';
		pre  { shift;
		       return unless @_>=1 && !grep {!$_->isa('Client')} @_;
		       return 1;
		     };
		     failmsg "constructor must be passed an initial Client obj";

		impl { @{self->queue} = ( $_[1] );
		       ${self->first} = 1;
		     };
};


package OrderedQueue;
use Class::Contract;

contract
{
	inherits 'ClientQueue';

	method 'append';
		post  { return unless $_[1]{id} > self->queue->[-2]{id} };
			failmsg "Client appended out of order";

	ctor 'new';
		impl { print "OrderedQueue::new!\n" };
};



package Client;

my $nextid = 1;
sub new
{
	bless { id => $nextid++ }, $_[0];
}


package Main;

use Class::Contract 'check';

check my %contract => 0 for (__ALL__);		# TURN OFF ALL OPTIONAL CHECKS

check %contract for ('ClientQueue');		# TURN ON OPTIONAL CHECKS 
						# FOR ClientQueue ONLY

print "[[[1]]]\n";
my $client = Client->new();

print "[[[2]]]\n";
my $q = OrderedQueue->new($client);

$client = Client->new();

print "[[[3]]]\n";
$q->append($client);

print "[[[4]]]\n";
$client = Client->new();
my $client2 = Client->new();

print "[[[5]]]\n";
# $q->append($client2);
$q->append($client);

print "[[[6]]]\n";
$client = "not a client";

# $q->append($client);

print $q->next(), "\n";
print $q->next(), "\n";
print $q->next(), "\n";
print $q->next(), "\n";
