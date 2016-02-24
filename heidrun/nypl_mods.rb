# FIXME: Why does 'photographer' get excluded here?  Is that deliberate?
#
# EDIT: Python code seemed to have it, so I'm adding it in.
CREATOR_ROLES = [
  'architect',
  'artist',
  'author',
  'cartographer',
  'composer',
  'creator',
  'designer',
  'director',
  'engraver',
  'interviewer',
  'landscape architect',
  'lithographer',
  'lyricist',
  'musical director',
  'performer',
  'photographer',
  'project director',
  'singer',
  'storyteller',
  'surveyor',
  'technical director',
  'woodcutter'
]

NON_CONTRIBUTOR_ROLES = [*CREATOR_ROLES, 'publisher', 'photographer']

# Sayeth the Crosswalk:
#
#   Generally speaking date will be structured <originInfo><dateNN
#   ...>[value]</dateNN></originInfo>, where NN could be any suffix from a
#   controlled list, e.g., dateIssued or dateCreated. Date may or may not have
#   an encoding, keyDate, or point attribute that may or may not be populated.
#
#   Date spans are represented as <dateNN ... point="start"> and <dateNN
#   ... point=end">
#
#   Repeated values may appear in the data; only print one (e.g.,
#   510d47dd-eac1-a3d9-e040-e00a18064a99).
#
#   <dateNN> can equal any of the following tags:
#   <dateIssued>
#   <dateCreated>
#   <dateCaptured>
#   <dateValid>
#   <dateModified>
#   <copyrightDate>
#   <dateOther>
#
#   Sometimes creation dates and collection span dates appear in record without
#   differentiation. E.g., df3d8d50-0ce5-0131-0284-58d385a7bbd0. It appears that
#   the second <originInfo><dateNN> tag is the item date.
#
build_dates = lambda do |record|
  result = DPLA::MAP::TimeSpan.new
  datefields = %w(dateIssued dateCreated dateCaptured dateValid
                  dateModified copyrightDate dateOther)

  last_origin_info = record['originInfo'].last_value

  key_date = last_origin_info.field(datefields.join('|'))
             .match_attribute(:keyDate, 'yes')
             .first_value.values[0]

  begin_date = last_origin_info.field(datefields.join('|'))
               .match_attribute(:point, 'start')
               .first_value.values[0]

  end_date = last_origin_info.field(datefields.join('|'))
             .match_attribute(:point, 'end')
             .first_value.values[0]

  result.providedLabel = key_date if key_date
  result.begin = begin_date if begin_date
  result.end = end_date if end_date

  if key_date || begin_date || end_date
    result
  else
    []
  end
end

# From the crosswalk document:
#
#   Grab all <relatedItem> values (including the collection name, which is the
#   last <relatedItem>) and create separate values as in option one. Work from
#   last to first tags. But first, strip all periods from the ends of all values
#   and then put them together again with ". " space between the values to
#   ensure we aren't doubling up on periods at the end of each value.
#
build_relation = lambda do |record|
  titles = record['relatedItem'].field('titleInfo', 'title').values
  if titles.empty?
    []
  else
    titles.reverse.join('. ').gsub(/\.+/, '.')
  end
end

# From the crosswalk document:
#
#   the last <titleInfo ... usage="primary"> <title>[value]</title> </titleInfo>
#   (If <nonSort> appears nested within <titleInfo> grab that value and prepend
#   it to <title>.)  OR (if there is no "primary" attribute) the first
#   <titleInfo><title>
#
build_title = lambda do |record|
  result = []

  primary_title = record['titleInfo'].match_attribute(:usage, 'primary')
                  .last_value

  if primary_title.values.empty?
    # If there's no primary title, just take what we can get.
    title = record['titleInfo'].field('title')
    result = title.values[0] unless title.values.empty?
  else
    # If there's a primary title, look for a nonSort and prepend it as needed.
    result = primary_title.field('title').values[0]
    non_sort = primary_title.field('nonSort')

    result = non_sort.values[0] + result unless non_sort.values.empty?
  end

  result
end

Krikri::Mapper.define(:nypl_mods,
                      parser: Krikri::ModsParser,
                      parser_args: '//mods') do
  provider class: DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/nypl'
    label 'The New York Public Library'
  end

  dataProvider class: DPLA::MAP::Agent do
    providedLabel record.field('location', 'physicalLocation')
                   .match_attribute(:type, 'division')
                   .reject_attribute(:authority, 'marcorg')
                   .map { |i|
                     i.value.strip.gsub(/\.+$/, '') +
                                         '. The New York Public Library'
                   }
  end

  isShownAt class: DPLA::MAP::WebResource do
    uri record.field('extension', 'capture', 'itemLink')
  end

  # Crosswalk spreadsheet said:
  #
  #   http://images.nypl.org/index.php?id=[<identifier type="local_bnumber">]&t=b
  #
  # But original ingest mapping
  # (https://github.com/dpla/ingestion/blob/develop/lib/akamod/nypl_identify_object.py)
  # would pull ImageID from the capture record and use that.  We'll do that too.
  #
  preview class: DPLA::MAP::WebResource do
    uri record.field('extension', 'capture', 'imageID')
                    .map { |i|
                      'http://images.nypl.org/index.php' \
                      "?id=#{i.value}&t=t"
                    }
  end

  originalRecord class: DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource class: DPLA::MAP::SourceResource do
    # Look for the last <relatedItem type="host"> and grab value nested in
    # <title<relatedItem
    # type="host"><titleInfo><title>[Value]</title></titleInfo</relatedItem>
    collection class: DPLA::MAP::Collection,
               each: record.field('relatedItem')
                       .match_attribute(:type, 'host')
                       .last_value,
               as: :coll do
      title coll.field('titleInfo', 'title')
    end

    # <name ...> <namePart>[value]</namePart> (When roleTerm is anything other
    # than "publisher" that is not one of these: Architect; Artist; Author;
    # Cartographer; Composer; Creator; Designer; Director; Engraver;
    # Interviewer; Landscape architect; Lithographer; Lyricist; Musical
    # director; Performer; Photographer; Project director; Singer; Storyteller;
    # Surveyor; Technical director; Woodcutter); Include here anything not
    # specifically listed in Contributor.
    contributor class: DPLA::MAP::Agent,
                each: record.field('name')
                        .select { |name|
                          name['role']
                                    .field('roleTerm')
                                    .match_attribute(:type, 'text')
                                    .map { |v| v.value.downcase }
                                    .none? { |role_term|
                                      NON_CONTRIBUTOR_ROLES.include?(role_term)
                                    }
                        },
                as: :contrib do
      providedLabel contrib.field('namePart')
    end

    # <name ...> <namePart>[value]</namePart> (When roleTerm is any of these:
    # Architect; Artist; Author; Cartographer; Composer; Creator; Designer;
    # Director; Engraver; Interviewer; Landscape architect; Lithographer;
    # Lyricist; Musical director; Performer; Project director; Singer;
    # Storyteller; Surveyor; Technical director; Woodcutter) See entire list
    # here: http://www.loc.gov/marc/relators/relaterm.html
    creator class: DPLA::MAP::Agent,
            each: record.field('name')
                    .select { |name|
                      name['role']
                                .field('roleTerm')
                                .match_attribute(:type, 'text')
                                .map { |v| v.value.downcase }
                                .all? { |role_term|
                                  CREATOR_ROLES.include?(role_term)
                                }
                    },
            as: :contrib do
      providedLabel contrib.field('namePart')
    end

    date record.map(&build_dates).flatten

    description record.fields(['note'], %w(physicalDescription note))

    extent record.field('physicalDescription', 'extent')

    dcformat record.field('physicalDescription', 'form')

    genre record.field('genre').select { |genre|
      genre.value.downcase =~ /book|periodical|magazine/
    }

    # Top-level <identifier> when displayLabel OR type attribute contain the
    #   following values: local_imageid isbn isrc isan ismn iswc issn uri urn
    identifier record.field('identifier')
                .select { |val|
                  pattern = Regexp.union('local_imageid', 'isbn', 'isrc',
                                         'isan', 'ismn', 'iswc', 'issn',
                                         'uri', 'urn')
                  val.node['displayLabel'] =~ pattern ||
                    val.node['type'] =~ pattern
                }

    language class: DPLA::MAP::Controlled::Language,
             each: record.field('language', 'languageTerm')
                     .match_attribute(:type, 'code')
                     .match_attribute(:authority, 'iso639-2b'),
             as: :lang do
      providedLabel lang
    end

    spatial class: DPLA::MAP::Place,
            each: record.field('place', 'placeTerm'),
            as: :place do
      providedLabel place.field('geographic')
    end

    # TODO: Might need a deduping enrichment here, as providedLabel might be
    # duplicated in some cases (as it is for
    # http://dp.la/item/16ed9c7ba1efb5f5311cb188e09be881)
    #
    # https://github.com/dpla/KriKri/blob/develop/lib/krikri/enrichments/dedup_nodes.rb
    publisher class: DPLA::MAP::Agent,
              each: record.field('originInfo', 'publisher'),
              as: :origin_publisher do
      providedLabel origin_publisher
    end

    relation record.map(&build_relation).flatten

    rights record.field('extension', 'capture', 'rightsStatement')

    subject class: DPLA::MAP::Concept,
            each: record.fields(['subject'], ['genre']),
            as: :subject do
      providedLabel subject.map { |i| i.value.strip }
    end

    temporal class: DPLA::MAP::TimeSpan,
             each: record.field('subject', 'temporal'),
             as: :date_string do
      providedLabel date_string
    end

    title record.map(&build_title).flatten

    # TODO: Enrichment needed for DCMI
    # https://github.com/dpla/KriKri/blob/develop/lib/krikri/enrichments/dcmi_type_map.rb
    dctype record.field('typeOfResource')
  end
end
