DATA_PROVIDER_MAP = {
  'GETTY_ROSETTA' => 'Getty Research Institute',
  'GETTY_OCP' => 'Getty Research Institute'
}

build_url = lambda do |p|
  source = p.root[Krikri::PrimoParser.record('control', 'sourceid').join('/')]
           .first.value
  id = p.root[Krikri::PrimoParser.record('control', 'recordid').join('/')]
       .first.value

  base_url = 'http://primo.getty.edu/primo_library/libweb/action/dlDisplay.do'

  case source
  when 'GETTY_ROSETTA'
    "#{base_url}?vid=GRI&afterPDS=true&institution=01GRI&docId=#{id}"
  when 'GETTY_OCP'
    "#{base_url}?vid=GRI-OCP&afterPDS=true&institution=01GRI&docId=#{id}"
  end
end

Krikri::Mapper.define(:getty,
                      parser: Krikri::PrimoParser) do
  provider class: DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/getty'
    label 'J. Paul Getty Trust'
  end

  dataProvider class: DPLA::MAP::Agent,
               each: record.field(*Krikri::PrimoParser.record('control',
                                                              'sourceid'))
                      .map { |i| DATA_PROVIDER_MAP.fetch(i.value, i.value) }
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

  originalRecord class: DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource class: DPLA::MAP::SourceResource do
    # TODO: Enrichment needed to split title fields on semicolons
    title record.fields(Krikri::PrimoParser.display('title'),
                        Krikri::PrimoParser.display('lds03'))

    collection class: DPLA::MAP::Collection,
               each: record.fields(Krikri::PrimoParser.display('lds34'),
                                   Krikri::PrimoParser.display('lds43')),
               as: :coll do
      title coll
    end

    # TODO: Enrichment needed to split contributor providedLabel on semicolons
    contributor class: DPLA::MAP::Agent,
                each: record.field(*Krikri::PrimoParser.display('contributor')),
                as: :contrib do
      providedLabel contrib
    end

    creator class: DPLA::MAP::Agent,
            each: record.field(*Krikri::PrimoParser.display('creator')),
            as: :creator do
      providedLabel creator
    end

    date class: DPLA::MAP::TimeSpan,
         each: record.field(*Krikri::PrimoParser.display('creationdate'))
           .first_value,
         as: :created do
      providedLabel created
    end

    description record.fields(Krikri::PrimoParser.display('lds04'),
                              Krikri::PrimoParser.display('lds28'),
                              Krikri::PrimoParser.display('rights'))

    extent record.field(*Krikri::PrimoParser.display('format'))

    dcformat record.field(*Krikri::PrimoParser.display('lds09'))

    # TODO: Enrichment needed here to map (e.g.) 'Still image' to 'image'
    genre record.field(*Krikri::PrimoParser.display('lds26'))
    dctype record.field(*Krikri::PrimoParser.display('lds26'))

    # TODO: Enrichment needed to split identifier on semicolons
    identifier record.field(*Krikri::PrimoParser.display('lds14'))

    language class: DPLA::MAP::Controlled::Language,
             each: record.field(*Krikri::PrimoParser.display('language')),
             as: :lang do
      providedLabel lang
    end

    # TODO: Enrichment needed to split publisher providedLabel on semicolons
    publisher class: DPLA::MAP::Agent,
              each: record.field(*Krikri::PrimoParser.display('publisher')),
              as: :publisher do
      providedLabel publisher
    end

    # TODO: Enrichment needed to split relation on semicolons
    relation record.fields(['sear:LINKS', 'sear:lln04'],
                           Krikri::PrimoParser.display('ispartof'))

    rights record.field(*Krikri::PrimoParser.display('lds27'))

    # TODO: Enrichment needed to split subject providedLabel on semicolons
    subject class: DPLA::MAP::Concept,
            each: record.field(*Krikri::PrimoParser.display('subject')),
            as: :subject do
      providedLabel subject
    end
  end
end
