build_url = lambda do |p|
  id = p.root[Krikri::PrimoParser.record('control', 'recordid').join('/')]
       .first.value
  "http://utah-primoprod.hosted.exlibrisgroup.com/primo_library/libweb/action/dlDisplay.do?vid=MWDL&afterPDS=true&docId=#{id}"
end

build_intermediate_provider = lambda do |p|
  srcid = p[Krikri::PrimoParser.record('control', 'sourceid').join('/')]
             .first.value
  lsr02 = p[Krikri::PrimoParser.search('lsr02').join('/')]
          .first.value

  if srcid == 'digcoll_msl_38' && lsr02 == '38'
    'Montana Memory Project'
  elsif srcid == 'digcoll_asl_31' && lsr02 == '31'
    'Arizona Memory Project'
  end
end

Krikri::Mapper.define(:mwdl, parser: Krikri::PrimoParser) do
  provider class: DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/mwdl'
    label 'Mountain West Digital Library'
  end

  dataProvider class: DPLA::MAP::Agent do
    label record.field(*Krikri::PrimoParser.display('lds03'))
  end

  intermediateProvider class: DPLA::MAP::Agent,
                       each: record.map(&build_intermediate_provider)
                         .first_value,
                       as: :provider do
    label provider
  end

  isShownAt class: DPLA::MAP::WebResource do
    uri build_url
  end

  preview class: DPLA::MAP::WebResource do
    uri record.field('sear:LINKS', 'sear:thumbnail')
  end

  sourceResource class: DPLA::MAP::SourceResource do
    collection class: DPLA::MAP::Collection,
               each: record.field(*Krikri::PrimoParser.search('lsr13')),
               as: :coll do
      title coll
    end

    creator class: DPLA::MAP::Agent,
            each: record.field(*Krikri::PrimoParser.display('creator')),
            as: :creator do
      providedLabel creator
    end

    ## TODO: Need an enrichment to turn these into:
    #
    #   "begin": "1930",
    #   "displayDate": "1930-1946"
    #   "end": "1946"
    #
    # Currently they are semicolon delimiter lists of years like:
    #  1930; 1931; 1932; 1933; 1934; 1935; 1936; 1937; 1938; 1939; 1940; 1941;
    #  1942; 1943; 1944; 1945; 1946"
    date class: DPLA::MAP::TimeSpan,
         each: record.field(*Krikri::PrimoParser.search('creationdate')),
         as: :created do
      providedLabel created
    end

    description record.field(*Krikri::PrimoParser.search('description'))

    extent record.field(*Krikri::PrimoParser.display('lds05'))

    identifier record.field(*Krikri::PrimoParser.record('control', 'recordid'))

    language class: DPLA::MAP::Controlled::Language do
      prefLabel record.field(*Krikri::PrimoParser.record('facets', 'language'))
    end

    spatial class: DPLA::MAP::Place,
            each: record.field(*Krikri::PrimoParser.display('lds08')),
            as: :place do
      providedLabel place
    end

    relation record.field(*Krikri::PrimoParser.display('relation'))

    rights record.field(*Krikri::PrimoParser.display('rights'))

    # TODO: Enrichment needed to split subject providedLabel on semicolons
    subject class: DPLA::MAP::Concept,
            each: record.field(*Krikri::PrimoParser.display('subject')),
            as: :subject do
      providedLabel subject
    end

    # TODO: Need an enrichment to parse these?  Currently may be semicolons, and
    # may appear as follows:
    #
    #  [{... "@type"=>"edm:TimeSpan", "providedLabel"=>"1930-1939"},
    #   {... "@type"=>"edm:TimeSpan", "providedLabel"=>"1940-1949"},
    #   {... "@type"=>"edm:TimeSpan", "providedLabel"=>"20th century"}]
    #
    # but should have begin and end dates?
    temporal class: DPLA::MAP::TimeSpan,
             each: record.field(*Krikri::PrimoParser.display('lds09')),
             as: :date_string do
      providedLabel date_string
    end

    # TODO: Enrichment needed to split title on semicolons
    title record.fields(Krikri::PrimoParser.display('title'),
                        Krikri::PrimoParser.display('lds10'))

    dctype record.field(*Krikri::PrimoParser.record('facets', 'rsrctype'))

    # TODO: Enrichment needed to split dcformat on semicolons
    dcformat record.field(*Krikri::PrimoParser.display('format'))
              .reject { |i| i.value.downcase == 'unknown' }
  end
end
