# coding: utf-8

collections = {
  'blc' => 'Boston Library Consortium',
  'cambridgepubliclibrary' => 'Cambridge Public Library',
  'clemson' => 'LYRASIS members and Sloan Foundation',
  'bostonpubliclibrary' => 'Boston Public Library',
  'regionaldigitizationmass' => 'Regional Digitization in Massachusetts',
  'getty' => 'Getty Research Institute',
  'medicalheritagelibrary' => 'Medical Heritage Library',
  'MontanaStateLibrary' => 'Montana State Library',
  'yivoinstitutelibrary' => 'YIVO Institute Library',
  'guggenheimlibrary' => 'Guggenheim Library',
  'lbiperiodicals' => 'Leo Baeck Institute Library at the Center for Jewish History',
  'frickartreferencelibrary' => 'Frick Art Reference Library'
}

# edm:dataProvider
#   Meta.xml
#     <contributor>;
#     <collection>[code name that must be mapped to the full official name]</collection>
#     NOTE: <collection> should appear first in the list of dataProviders
data_provider_map = lambda do |record|
  data_provider = record['metadata'].field('collection').map { |c| collections[c] }

  data_provider.concat(record['metadata'].field('contributor'))
end

# dcterms:identifier
#   META.XML
#     <identifier> may be the same thing;
#     <call_number>Call number: "[value]"</call_number>;
#     <datafield tag="035" ind1=" " ind2=" "><subfield code="a">[value]</subfield>
identifier_map = lambda do |record|
  identifier = record['metadata'].field('identifier')

  identifier.concat(record['metadata'].field('call_number'))

  identifier.concat(record['metadata']
                      .field('marc', 'record', 'datafield')
                      .match_attribute(:tag, '035')
                      .match_attribute(:ind1, ' ')
                      .match_attribute(:ind2, ' ')
                      .field('subfield')
                      .match_attribute(:code, 'a'))
end

# dc:relation
#   MARC.XML
#     <datafield tag="440"> or
#     <datafield tag="490"> or
#     <datafield tag="800"> or
#     <datafield tag="810"> or
#     <datafield tag="830">;
#     <datafield tag="785"> [Add ". " between subfields; Do not include subfield w];
#     <datafield tag="780"> [Add ". " between subfields; Do not include subfield w]
relation_map = lambda do |record|
  relation = record['metadata'].field('marc', 'record', 'datafield')
    .match_attribute(:tag) { |tag| %w(440 490 800 810 830).include?(tag) }

  relation.concat(record['metadata'].field('marc', 'record', 'datafield')
                    .match_attribute(:tag, '785')
                    .field('subfield')
                    .match_attribute(:code) { |code| code != 'w' }
                    .join('. '))

  relation.concat(record['metadata'].field('marc', 'record', 'datafield')
                    .match_attribute(:tag, '780')
                    .field('subfield')
                    .match_attribute(:code) { |code| code != 'w' }
                    .join('. '))
end

Krikri::Mapper.define(:ia, :parser => Krikri::XmlParser) do
  # edm:dataProvider
  #   Meta.xml
  #     <contributor>;
  #     <collection>[code name that must be mapped to the full official name]</collection>
  #     NOTE: <collection> should appear first in the list of dataProviders
  dataProvider class: DPLA::MAP::Agent do
    label record.map(&data_provider_map).flatten
  end

  # edm:isShownAt
  #   META.XML <identifier-access>
  isShownAt class: DPLA::MAP::WebResource do
    uri record.field('metadata', 'identifier-access')
  end

  # edm:preview
  #   We should pull these from Google Books API if we can't unblink the gifs in IA
  #preview class: DPLA::MAP::WebResource do
  #  uri ???
  #end
  # TODO: what to do here? - JB

  # edm:provider
  #   "Internet Archive" (hard coded)
  provider class: DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/ia'
    label 'Internet Archive'
  end

  # edm:hasView
  #   "application/pdf"
  hasView class: DPLA::MAP::WebResource do
    dcformat 'application/pdf'
  end

  # dpla:SourceResource
  sourceResource class: DPLA::MAP::SourceResource do
    # dcterms:isPartOf
    #   meta.xml <sponsor>
    collection class: DPLA::MAP::Collection,
               each: record.field('metadata', 'sponsor'),
               as: :collection do
      title collection
    end

    # dcterms:creator
    #   META.xml <creator>
    creator class: DPLA::MAP::Agent,
            each: record.field('metadata', 'creator'),
            as: :creator do
      providedLabel creator
    end

    # dc:date
    #   META.xml <date>
    date class: DPLA::MAP::TimeSpan,
         each: record.field('metadata', 'date'),
         as: :date do
      providedLabel date
    end

    # dcterms:description
    #   meta.xml <description>
    description record.field('metadata', 'description')

    # dcterms:extent
    #   MARC.XML <datafield tag="300">[any subfields]
    extent record.field('metadata', 'marc', 'record', 'datafield')
      .match_attribute(:tag, '300')

    # dcterms:identifier
    #   META.XML
    #     <identifier> may be the same thing;
    #     <call_number>Call number: "[value]"</call_number>;
    #     <datafield tag="035" ind1=" " ind2=" "><subfield code="a">[value]</subfield>
    identifier record.map(&identifier_map).flatten

    # dcterms:language
    #   META.XML <language>
    language record.field('metadata', 'language')

    # dcterms:spatial
    #   MARC.xml
    #     <datafield tag="6##"><subfield code="z">
    #     [ANY 600-699 data field but only subfield "z" which is a geographic indicator]
    spatial class: DPLA::MAP::Place,
            each: record.field('metadata', 'marc', 'record', 'datafield')
                .match_attribute(:tag) { |tag| tag.start_with?('6') }
                .field('subfield')
                .match_attibute(:code, 'z'),
            as: :place do
      providedLabel place
    end

    # dcterms:publisher
    #   meta.xml <publisher>
    publisher class: DPLA::MAP::Agent,
              each: record.field('metadata', 'publisher'),
              as: :publisher do
      providedLabel publisher
    end

    # dc:relation
    #   MARC.XML
    #     <datafield tag="440"> or
    #     <datafield tag="490"> or
    #     <datafield tag="800"> or
    #     <datafield tag="810"> or
    #     <datafield tag="830">;
    #     <datafield tag="785"> [Add ". " between subfields; Do not include subfield w];
    #     <datafield tag="780"> [Add ". " between subfields; Do not include subfield w]
    relation record.map(&relation_map).flatten

    # dc:rights
    #   "Access to the Internet Archive’s Collections is granted
    #    for scholarship and research purposes only. Some of the
    #    content available through the Archive may be governed by
    #    local, national, and/or international laws and regulations,
    #    and your use of such content is solely at your own risk."
    rights <<-EOS
      Access to the Internet Archive’s Collections is granted
      for scholarship and research purposes only. Some of the
      content available through the Archive may be governed by
      local, national, and/or international laws and regulations,
      and your use of such content is solely at your own risk.
    EOS

    # dcterms:subject
    #   meta.xml <subject>
    subject class: DPLA::MAP::Concept,
            each: record.field('metadata', 'subject'),
            as: :subject do
      providedLabel subject
    end

    # dcterms:title
    #   META.xml <title></title>", "<volume></volume> [if "volume exists"]
    title record.fields(['metadata', 'title'], ['metadata', 'volume'])

    # dcterms:type
    #   META.xml <mediatype> when the value matches DCMIType
    dctype record.field('metadata', 'mediatype')
    # TODO: enhancement to match on DCMIType? - JB
  end
end
