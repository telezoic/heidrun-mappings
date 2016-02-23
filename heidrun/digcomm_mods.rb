# Combine all sub-fields in the <name> section EXCEPT <affiliation>,
# <displayForm>, <description>, and <role>. If there is no <name> with a
# <roleTerm>creator</roleTerm>, then the first name is the creator no matter
# the <roleTerm>. Any other secondary <roleTerm> values are contributors.

extract_names = lambda do |r|
  excluded_subfields = ['mods:affiliation', 'mods:displayForm',
                        'mods:description', 'mods:role']

  r['mods:name'].map do |name|
    subfields = (name.children - excluded_subfields).uniq

    {
      role: name['mods:role'].field('mods:roleTerm')
        .map(&:value).first.downcase,
      label: subfields.map do |subfield|
        name[subfield].map(&:value).values.join(', ')
      end.first
    }
  end.values.flatten
end

extract_creator = lambda do |r|
  # The creator is either a name with roleTerm=creator, or the first name
  # otherwise.
  all_names = extract_names.call(r)

  creator = all_names.find { |name| name[:role] == 'creator' }
  creator ||= all_names.first

  creator[:label]
end

extract_contributors = lambda do |r|
  all_names = extract_names.call(r)
  creator = extract_creator.call(r)

  # Contributors are whoever is left
  all_names
    .reject { |name| name[:label] == creator }
    .map { |name| name[:label] }
end

# <mods:identifier type="local-accession">;
# <mods:identifier type="local-other">;
# <mods:identifier type="local-other" invalid="yes">;
# <mods:identifier type="local-call">;
# <mods:identifier type="local-call" invalid="yes">;
# <mods:identifier type="local-barcode">;
# <mods:identifier type="local-barcode" invalid="yes">;
# <mods:identifier type="isbn">;
# <mods:identifier type="ismn">;
# <mods:identifier type="isrc">;
# <mods:identifier type="issn">;
# <mods:identifier type="issue-number">;
# <mods:identifier type="lccn">;
# <mods:identifier type="matrix-number">;
# <mods:identifier type="music-plate">;
# <mods:identifier type="music-publisher">;
# <mods:identifier type="sici">;
# <mods:identifier type="videorecording-identifier">
#
# [The value should be a concatenation of the type qualifier value (and the
# property value, e.g., "Local accession: ####")].
build_identifier = lambda do |r|
  types = [
    'isbn', 'ismn', 'isrc', 'issn', 'issue-number', 'lccn',
    'local-accession', 'local-barcode', 'local-call', 'local-other',
    'matrix-number', 'music-plate', 'music-publisher',
    'sici', 'videorecording-identifier'
  ]

  types.map do |identifier_type|
    r['mods:identifier']
      .match_attribute(:type, identifier_type)
      .map do |i|
        format('%s: %s',
               identifier_type.tr('-', ' ').capitalize,
               i.value)
      end
  end
end

# <mods:location><mods:physicalLocation>
# CONCATENATED with ". "
# <mods:location><mods:holdingSimple><mods:copyInformation><mods:subLocation>
# CONCATENATED with ". "
# <mods:relatedItem type="host"><mods:titleInfo><mods:title>
# CONCATENATED with ". "
# <mods:relatedItem type="series"><mods:titleInfo><mods:title>
#
# (e.g., Boston Public Library. Leslie Jones photograph collection)
build_relation = lambda do |r|
  field_values = []

  field_values << r['mods:location']
                 .fields(['mods:physicalLocation'],
                         ['mods:holdingSimple',
                          'mods:copyInformation',
                          'mods:subLocation'])

  field_values << r['mods:relatedItem'].match_attribute(:type, 'host')
                 .field('mods:titleInfo', 'mods:title')

  field_values << r['mods:relatedItem'].match_attribute(:type, 'series')
                 .field('mods:titleInfo', 'mods:title')

  field_values.map(&:values).flatten.join('. ')
end

Krikri::Mapper.define(:digcomm_mods, :parser => Krikri::ModsParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/digital-commonwealth'
    label 'Digital Commonwealth'
  end

  # <mods:location><mods:url access="preview">
  preview :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
         .match_attribute(:access, 'preview')
    dcformat record.field('mods:physicalDescription', 'mods:internetMediaType')
  end

  # <mods:location><mods:physicalLocation>
  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('mods:location', 'mods:physicalLocation')
  end

  # <mods:location><mods:url usage="primary" access="object in context">
  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
         .match_attribute(:usage, 'primary')
         .match_attribute(:access, 'object in context')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    alternative record.field('mods:titleInfo')
                      .match_attribute(:type, 'alternative')
                      .field('mods:title')

    ##
    # FIXME: The comment below was taken from the ESDN mapping.  Need to review
    # the situation here.
    #
    # TODO: implement collection/set harvester and enrichment to complete
    # the metadata required for collections. This just grabs the set's
    # identifier from the OAI-PMH setSpec in the record header.
    collection :class => DPLA::MAP::Collection,
               :each => header.field('xmlns:setSpec'),
               :as => :coll do
      title coll
    end

    ##
    # If there is no <name> with a <roleTerm>creator</roleTerm>, then the first
    # name is the creator no matter the <roleTerm>. Any other secondary
    # <roleTerm> values are contributors. See creator for full instructions for
    # implementation.
    #
    contributor :class => DPLA::MAP::Agent,
                :each => record.map(&extract_contributors).flatten,
                :as => :contrib do
      providedLabel contrib
    end

    # Combine all sub-fields in the <name> section EXCEPT <affiliation>,
    # <displayForm>, <description>, and <role>. If there is no <name> with a
    # <roleTerm>creator</roleTerm>, then the first name is the creator no matter
    # the <roleTerm>. Any other secondary <roleTerm> values are contributors.
    creator :class => DPLA::MAP::Agent,
            :each => record.map(&extract_creator).flatten,
            :as => :creator do
      providedLabel creator
    end

    # <mods:originInfo><mods:dateCreated encoding="w3cdtf" keyDate="yes">
    # <mods:originInfo><mods:dateIssued encoding="w3cdtf" keyDate="yes">
    # <mods:originInfo><mods:dateOther encoding="w3cdtf" keyDate="yes">
    # <mods:originInfo><mods:copyrightDate encoding="w3cdtf" keyDate="yes">
    date :class => DPLA::MAP::TimeSpan,
         :each => record.fields(['mods:originInfo', 'mods:dateCreated'],
                                ['mods:originInfo', 'mods:dateIssued'],
                                ['mods:originInfo', 'mods:dateOther'],
                                ['mods:originInfo', 'mods:copyrightDate'])
                 .match_attribute(:encoding, 'w3cdtf')
                 .match_attribute(:keyDate, 'yes'),
         :as => :created do
      providedLabel created
      self.begin created.match_attribute(:point, 'start')
      self.end created.match_attribute(:point, 'end')
    end

    # <mods:abstract>; <mods:note...>
    description record.fields('mods:abstract', 'mods:note')

    # <mods:physicalDescription><mods:extent>
    extent record.field('mods:physicalDescription', 'mods:extent')

    # <mods:genre...>
    # FIXME: non-DCMIType values from type will be handled in enrichment
    dcformat record.field('mods:genre')

    identifier record.map(&build_identifier).flatten

    # FIXME: Language code enrichment needed here (language_to_lexvo.rb)
    #
    # <mods:language><mods:languageTerm type="text" authority="iso639-2b"
    # authorityURI="http://id.loc.gov/vocabulary/iso639-2"
    # valueURI="http://id.loc.gov/vocabulary/iso639-2/code [value]">[text value]
    language record.field('mods:language', 'mods:languageTerm')
              .match_attribute(:type, 'text')
              .match_attribute(:authority, 'iso639-2b')
              .match_attribute(:authorityURI, 'http://id.loc.gov/vocabulary/iso639-2')

    # FIXME: hierarchicalGeographic is currently coming out as a string like:
    #
    #  "\n      North and Central America\n      United States\n      Massachusetts\n      Essex\n      Marblehead\n    "
    #
    # Do we want to turn this into a comma-separated string instead?  The
    # original ingest broke the hierarchicalGeographic into its component fields
    # (city, county, state, ...) but MAPV4 doesn't have these fields anymore.
    #
    # The `split_coordinates.rb` enrichment will also be needed to process the
    # `lat` field
    #
    # <mods:subject><mods:hierarchicalGeographic>
    # <mods:subject><mods:geographic>
    # <mods:subject><mods:cartographics><mods:coordinates>
    spatial :class => DPLA::MAP::Place,
            :each => record.field('mods:subject')
                           .select { |sub|
                             sub.child?('mods:hierarchicalGeographic') ||
                               sub.child?('mods:geographic') ||
                               sub.child?('mods:cartographics')
                           },
            :as => :place do
      exactMatch place
                  .match_attribute(:valueURI)
                  .first_value
                  .map { |v| v.node.attr('valueURI') }
      providedLabel place.fields('mods:hierarchicalGeographic',
                                 'mods:geographic')
      lat place.field('mods:cartographics', 'mods:coordinates')
    end

    # <mods:originInfo><mods:place><mods:placeTerm type="text">
    # <mods:originInfo><mods:publisher>
    publisher :class => DPLA::MAP::Agent,
              :each => record.fields(['mods:originInfo', 'mods:placeTerm'],
                                     ['mods:originInfo', 'mods:publisher']),
              :as => :publisher do
      providedLabel publisher
    end

    relation record.map(&build_relation).flatten

    # <mods:accessCondition...>
    rights record.field('mods:accessCondition')

    # Any <mods:subject> field, except <mods:hierarchicalGeographic>,
    # <mods:geographic>, and <mods:cartographics><mods:coordinates>. [LCSH
    # subfield values are separated with hyphenation "--"] Some will be repeats
    # of place, but that's OK.
    subject :class => DPLA::MAP::Concept,
            :each => record.field('mods:subject')
                    .reject { |v| v.child?('mods:hierarchicalGeographic') }
                    .reject { |v| v.child?('mods:geographic') }
                    .reject { |v| v.child?('mods:cartographics') },
            :as => :subject do
      providedLabel subject
    end

    # <mods:subject><mods:temporal>
    temporal :class => DPLA::MAP::TimeSpan,
             :each => record.field('mods:subject', 'mods:temporal'),
             :as => :date_string do
      providedLabel date_string
    end

    # <titleInfo> has two subelements: <title> <nonSort> AND
    # <subTitle> (<partNumber> and <partName> are not
    # currently supported). Supported title types are:
    #
    # <mods:titleInfo usage="primary">,
    # <mods:titleInfo type="translated">, AND <mods:titleInfo type="uniform">
    #
    title record.field('mods:titleInfo')
           .match_attribute(:usage) { |attr| %w(primary translated uniform).include?(attr) }
           .fields('mods:title', 'mods:nonSort', 'mods:subTitle')

    # Selecting DCMIType-only values will be handled in enrichment
    dctype record.field('mods:typeOfResource')
  end
end
