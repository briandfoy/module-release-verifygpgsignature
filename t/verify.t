use Test::More;

my $class = 'Module::Release::VerifyGPGSignature';
subtest 'sanity' => sub {
	use_ok $class;
	};


TODO: {
local $TODO = 'need to do more work';
subtest 'fill in' => sub {
	fail("need to implement")
	}

}

done_testing();
