use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'stet',
    'PREREQ_PM' => {
        'Frontier::Client' => 0,
        'Lingua::EN::Sentence' => 0,
        'MIME::Entity' => 0,
        'RPC::XML::Client' => 0,
        'RPC::XML' => 0,
        'URI::Escape' => 0,
        'URI' => 0,
        'Text::Template' => 0,
        'XML::DOM' => 0,
    },
);
