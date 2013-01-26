use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'stet',
    'PREREQ_PM' => {
        'Frontier::Client',
        'Lingua::EN::Sentence',
        'MIME::Entity',
        'RPC::XML::Client',
        'RPC::XML',
        'URI::Escape',
        'URI',
        'Text::Template',
        'XML::DOM',
    },
);
