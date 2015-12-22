contributor_map = lambda do |r|
  df_700 = Heidrun::MappingTools::MARC.datafield_els(r, '700')
  df_710 = Heidrun::MappingTools::MARC.datafield_els(r, '710')
  df_711 = Heidrun::MappingTools::MARC.datafield_els(r, '711')
  df_720 = Heidrun::MappingTools::MARC.datafield_els(r, '720')

  datafields = []
  datafields << df_700
  datafields << df_710
  datafields << df_711

  if (Heidrun::MappingTools::MARC.subfield_values(df_720, 'e') &
        ['joint author', 'jt author']).empty?
    datafields << df_720
  end

  datafields.flatten.compact.map do |df|
    Heidrun::MappingTools::MARC.all_subfield_values([df]).join(' ')
  end
end

creator_map = lambda do |r|
  (Heidrun::MappingTools::MARC.datafield_els(r, '100') +
  Heidrun::MappingTools::MARC.datafield_els(r, '110') +
  Heidrun::MappingTools::MARC.datafield_els(r, '111'))
  .flatten.compact.map do |df|
    Heidrun::MappingTools::MARC.all_subfield_values([df]).join(' ')
  end
end

extent_map = lambda do |r|
  df_300 = Heidrun::MappingTools::MARC.datafield_els(r, '300')
  df_340 = Heidrun::MappingTools::MARC.datafield_els(r, '340')
  df_300a = Heidrun::MappingTools::MARC.subfield_values(df_300, 'a')
  df_300c = Heidrun::MappingTools::MARC.subfield_values(df_300, 'c')
  df_340b = Heidrun::MappingTools::MARC.subfield_values(df_340, 'b')
  [df_300a, df_300c, df_340b].flatten.reject(&:empty?)
end

dcformat_map = lambda do |r|
  cf_007 = Heidrun::MappingTools::MARC.controlfield_values(r, '007')
  leader = Heidrun::MappingTools::MARC.leader_value(r)

  dfs = Heidrun::MappingTools::MARC.datafield_els(r, /^3(?:3[78]|40)$/)
  a_vals = Heidrun::MappingTools::MARC.subfield_values(dfs, 'a')
  formats = Heidrun::MappingTools::MARC.dcformat(leader: leader,
                                                 cf_007: cf_007)
  (formats + a_vals).compact.uniq
end

genre_map = lambda do |r|
  leader = Heidrun::MappingTools::MARC.leader_value(r)
  cf_007 = Heidrun::MappingTools::MARC.controlfield_values(r, '007')
  cf_008 = Heidrun::MappingTools::MARC.controlfield_values(r, '008')

  Heidrun::MappingTools::MARC.genre(leader: leader,
                                    cf_007: cf_007,
                                    cf_008: cf_008)
end

identifier_map = lambda do |r|
  cf_001 = Heidrun::MappingTools::MARC.controlfield_values(r, '001')
  cf_001_vals = cf_001.map { |v| "Hathi: #{v}" }

  df_020 = Heidrun::MappingTools::MARC.datafield_els(r, '020')
  df_020_vals = df_020.map do|df|
    sf_vals = Heidrun::MappingTools::MARC.all_subfield_values([df])
              .reject(&:empty?)
    sf_vals.empty? ? nil : 'ISBN: ' + sf_vals.join(' ')
  end.compact

  df_022 = Heidrun::MappingTools::MARC.datafield_els(r, '022')
  df_022_vals = df_022.map do |df|
    sf_vals = Heidrun::MappingTools::MARC.subfield_values([df], 'a')
              .reject(&:empty?)
    sf_vals.empty? ? nil : 'ISSN: ' + sf_vals.join(' ')
  end.compact

  df_035 = Heidrun::MappingTools::MARC.datafield_els(r, '035')
  df_035_vals = df_035.map do |df|
    Heidrun::MappingTools::MARC.subfield_values([df], 'a')
  end.reject(&:empty?)

  df_050 = Heidrun::MappingTools::MARC.datafield_els(r, '050')
  df_050_vals = df_050.map do |df|
    sf_a = Heidrun::MappingTools::MARC.subfield_values([df], 'a')
           .reject(&:empty?)
    sf_b = Heidrun::MappingTools::MARC.subfield_values([df], 'b')
           .reject(&:empty?)

    sf_ab = (sf_a + sf_b).flatten.join
    sf_ab.empty? ? nil : "LC call number: #{sf_ab}"
  end.compact

  [cf_001_vals + df_020_vals + df_022_vals + df_035_vals + df_050_vals]
  .flatten
  .uniq
end

language_map = lambda do |r|
  df_041 = Heidrun::MappingTools::MARC.datafield_els(r, '041')
  df_041a = Heidrun::MappingTools::MARC.subfield_values(df_041, 'a')

  return df_041a unless df_041a.empty?

  cf_008 = Heidrun::MappingTools::MARC.controlfield_values(r, '008')
  cf_008.map { |cf| cf[35, 3] }.reject { |s| s.nil? || s.empty? }
end

spatial_map = lambda do |r|
  df_650 = Heidrun::MappingTools::MARC.datafield_els(r, '650')
  df_650z = Heidrun::MappingTools::MARC.subfield_values(df_650, 'z')
  df_651 = Heidrun::MappingTools::MARC.datafield_els(r, '651')
  df_651a = Heidrun::MappingTools::MARC.subfield_values(df_651, 'a')
  df_662 = Heidrun::MappingTools::MARC.datafield_values(r, '662')
  df_662_subs = Heidrun::MappingTools::MARC.all_subfield_values(df_662)

  [df_650z, df_651a, df_662_subs].flatten.reject(&:empty?).uniq
end

publisher_map = lambda do |r|
  df_260 = Heidrun::MappingTools::MARC.datafield_els(r, '260')
  df_260a = Heidrun::MappingTools::MARC.subfield_values(df_260, 'a')
  df_260b = Heidrun::MappingTools::MARC.subfield_values(df_260, 'b')

  [df_260a, df_260b].compact.join(' ')
end

relation_map = lambda do |r|
  df_regex = /^7(?:[67][0-9]|8[0-7])$/
  datafields = Heidrun::MappingTools::MARC.datafield_els(r, df_regex)
  Heidrun::MappingTools::MARC.all_subfield_values(datafields)
end

HATHI_RIGHTS = {
  'pd' => 'public domain',
  'ic-world' => 'in-copyright and permitted as world viewable by the copyright'\
                ' holder',
  'pdus' => 'public domain only when viewed in the US',
  'cc-by' => 'Creative Commons Attribution license',
  'cc-by-nd' => 'Creative Commons Attribution-NoDerivatives license',
  'cc-by-nc-nd' => 'Creative Commons Attribution-NonCommercial-NoDerivatives'\
                   ' license',
  'cc-by-nc' => 'Creative Commons Attribution-NonCommercial license',
  'cc-by-nc-sa' => 'Creative Commons Attribution-NonCommercial-ShareAlike'\
                   ' license',
  'cc-by-sa' => 'Creative Commons Attribution-ShareAlike license',
  'cc-zero' => 'Creative Commons Zero license (implies pd)',
  'und-world' => 'undetermined copyright status and permitted as world'\
                 'viewable by the depositor'
}

HATHI_RIGHTS_STRING = '%s. Learn more at http://www.hathitrust.org/access_use'

rights_map = lambda do |r|
  df_974 = Heidrun::MappingTools::MARC.datafield_els(r, '974')
  df_974_r = Heidrun::MappingTools::MARC.subfield_values(df_974, 'r')

  df_974_r.map { |rights_name| HATHI_RIGHTS.fetch(rights_name, nil) }.compact
          .map { |desc| sprintf(HATHI_RIGHTS_STRING, desc.capitalize) }
end

subject_map = lambda do |r|
  df_regex = /^6(?:00|[19][0-9]|5[^29])$/
  datafields = Heidrun::MappingTools::MARC.datafield_els(r, df_regex)

  subjects = []
  datafields.each do |df|
    sfs = Heidrun::MappingTools::MARC.all_subfield_values([df])
    subjects << sfs.map(&:strip).join('--')
  end

  subjects.reject(&:empty?)
end

title_map = lambda do |r|
  df_240 = Heidrun::MappingTools::MARC.datafield_els(r, '240')
  df_240_subs = Heidrun::MappingTools::MARC.all_subfield_values(df_240)
  df_242 = Heidrun::MappingTools::MARC.datafield_els(r, '242')
  df_242_subs = Heidrun::MappingTools::MARC.all_subfield_values(df_242)
  df_245 = Heidrun::MappingTools::MARC.datafield_els(r, '245')

  df_245_subs = df_245.map do |df|
    df.children.select do |sf|
      sf.name == 'subfield' && sf[:code] != 'c'
    end
  end

  dfs = [df_240_subs, df_242_subs, df_245_subs]

  dfs.map { |sfs| sfs.join(' ') }
     .reject(&:empty?)
end

dctype_map = lambda do |r|
  leader = Heidrun::MappingTools::MARC.leader_value(r)
  df_337 = Heidrun::MappingTools::MARC.datafield_els(r, '337')
  df_337a = Heidrun::MappingTools::MARC.subfield_values(df_337, 'a')

  Heidrun::MappingTools::MARC.dctype(leader: leader,
                                     df_337a: df_337a)
end

# fixed_control_fields_map = lambda do |r|
#  Heidrun::MappingTools::MARC.controlfield_values(r, '008')
# end

# from http://mirlyn-aleph.lib.umich.edu/mdp/dpla_metadata/ht_collections.json
COLLECTION_CODES = {
  'aeu' => 'University of Alberta',
  'chi' => 'University of Chicago',
  'coo' => 'Cornell University',
  'ctu' => 'University of Connecticut',
  'deu' => 'University of Delaware',
  'geu' => 'Emory University',
  'gri' => 'The Getty Research Institute',
  'gwla' => 'Technical Report Archive & Image Library',
  'hvd' => 'Harvard University',
  'iau' => 'University of Iowa',
  'ibc' => 'Boston College',
  'iduke' => 'Duke University',
  'iloc' => 'Library of Congress',
  'incsu' => 'North Carolina State University',
  'innc' => 'Columbia University',
  'inrlf' => 'University of California',
  'inu' => 'Indiana University',
  'ipst' => 'Pennsylvania State University',
  'isrlf' => 'University of California',
  'iucd' => 'University of California',
  'iucla' => 'University of California',
  'iufl' => 'State University System of Florida',
  'iuiuc' => 'University of Illinois at Urbana-Champaign',
  'iunc' => 'University of North Carolina at Chapel Hill',
  'keio' => 'Keio University',
  'mdl' => 'Minnesota Digital Library',
  'mdu' => 'University of Maryland, College Park',
  'miem' => 'Michigan State University',
  'miu' => 'University of Michigan',
  'mmet' => 'Tufts University',
  'mou' => 'University of Missouri - Columbia',
  'mu' => 'University of Massachusetts Amherst',
  'mwica' => 'Clark Art Institute Library',
  'nbb' => 'Brooklyn Museum',
  'njp' => 'Princeton University',
  'nnc' => 'Columbia University',
  'nnfr' => 'The Frick Collection',
  'nrlf' => 'University of California',
  'nwu' => 'Northwestern University',
  'nyp' => 'New York Public Library',
  'osu' => 'The Ohio State University',
  'pst' => 'Pennsylvania State University',
  'pur' => 'Purdue University',
  'qmm' => 'McGill University',
  'srlf' => 'University of California',
  'txcm' => 'Texas A&M University',
  'ucbk' => 'University of California',
  'ucd' => 'University of California',
  'ucla' => 'University of California',
  'ucm' => 'Universidad Complutense de Madrid',
  'ucsc' => 'University of California',
  'ucsd' => 'University of California',
  'ucsf' => 'University of California',
  'ufdc' => 'State University System of Florida',
  'uiuc' => 'University of Illinois at Urbana-Champaign',
  'uiucl' => 'University of Illinois at Urbana-Champaign',
  'ukloku' => 'Knowledge Unlatched',
  'umbus' => 'University of Michigan',
  'umdb' => 'University of Michigan',
  'umdcmp' => 'Millennium Project',
  'umlaw' => 'University of Michigan',
  'umn' => 'University of Minnesota',
  'umprivate' => 'Private Donor',
  'usu' => 'Utah State University Press',
  'uuhhs' => 'Unitarian Universalist History and Heritage Society',
  'uva' => 'University of Virginia',
  'wau' => 'University of Washington',
  'wu' => 'University of Wisconsin - Madison',
  'yale' => 'Yale University'
}

data_provider_map = lambda do |r|
  df_974 = Heidrun::MappingTools::MARC.datafield_els(r, '974')
  df_974c = Heidrun::MappingTools::MARC.subfield_values(df_974, 'c')

  df_974c.map do |raw_data_provider|
    COLLECTION_CODES.fetch(raw_data_provider.downcase, nil)
  end.compact
end

date_map = lambda do |r|
  cf_008 = Heidrun::MappingTools::MARC.controlfield_values(r, '008').first

  type_of_date = cf_008[6]

  (year_begin, year_end) =
    case type_of_date
    when 'm', 'q', 'd'
      # multiple dates (m, q) or serial item ceased date (d)
      [cf_008[7...11], cf_008[11...15]]
    when 's', 'r', 't'
      # single date, reissue date or pub copy date
      [cf_008[7...11], cf_008[7...11]]
    when 'e'
      # detailed date
      year  = cf_008[7...11]
      month = cf_008[11...13]
      day   = cf_008[13...15]
      date  = [year, month, day].join('-')
      [date, date]
    when 'c'
      # serial item current
      #
      # From Python version:
      #
      #   The MARC spec says the end year is supposed to be "9999", but I've
      #   seen otherwise, and the current year looks better.  Since "9999" is
      #   a bogus value, anyway, I'm using the current year.
      #
      [cf_008[7...11], Time.now.year.to_s]
    end

  df_260 = Heidrun::MappingTools::MARC.datafield_els(r, '260')
  df_260c = Heidrun::MappingTools::MARC.subfield_values(df_260, 'c')

  result = DPLA::MAP::TimeSpan.new
  result.begin = year_begin
  result.end = year_end
  result.providedLabel = df_260c

  result
end

Krikri::Mapper.define(:hathi_marcxml,
                      parser: Krikri::MARCXMLParser) do
  # edm:provider
  #   "HathiTrust Digital Library" (hard coded)
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/hathitrust'
    label 'HathiTrust Digital Library'
  end

  # edm:dataProvider
  #   974$c Map collection code to JSON data available from
  #   http://mirlyn-aleph.lib.umich.edu/mdp/dpla_metadata/ht_collections.json
  dataProvider class: DPLA::MAP::Agent,
               each: record.map(&data_provider_map).flatten,
               as: :data_provider do
    providedLabel data_provider
  end

  originalRecord class: DPLA::MAP::WebResource do
    uri record_uri
  end

  # edm:isShownAt
  #   856$u
  isShownAt class: DPLA::MAP::WebResource,
            each: record.field('marc:datafield')
                        .match_attribute(:tag, '856'),
            as: :the_uri do
    uri the_uri.field('marc:subfield').match_attribute(:code, 'u')
  end

  # dpla:SourceResource
  sourceResource class: DPLA::MAP::SourceResource do
    # dcterms:contributor
    #   700; 710; 711;
    #   720 when the relator term (subfield e) is not 'aut' or 'cre'
    contributor class: DPLA::MAP::Agent,
                each: record.map(&contributor_map).flatten,
                as: :contributor do
      providedLabel contributor
    end

    # dcterms:creator
    #   100, 110, 111
    creator class: DPLA::MAP::Agent,
            each: record.map(&creator_map).flatten,
            as: :creator do
      providedLabel creator
    end

    # dc:date
    #   260$c
    date class: DPLA::MAP::TimeSpan,
         each: record.field('marc:datafield')
                     .match_attribute(:tag, '260'),
         as: :date do
      providedLabel date.field('marc:subfield').match_attribute(:code, 'c')
    end

    # dcterms:description
    #   5XX; not 538
    description record.field('marc:datafield')
                      .select { |df| df.tag.starts_with?('5') && df.tag != '538' }
                      .field('marc:subfield')

    # dcterms:extent
    #   300a; 300c; 340b
    extent record.map(&extent_map).flatten

    # dc:format
    #   007 position 00 [see http://www.loc.gov/marc/bibliographic/bd007.html];
    #   position 06 in Leader [see “06 - Type of record“ here: http://www.loc.gov/marc/bibliographic/bdleader.html];
    #   337$a; 338$a; 340$a
    dcformat record.map(&dcformat_map).flatten

    # edm:hasType
    #   See chart here: https://docs.google.com/spreadsheet/ccc?key=0ApDps8nOS9g5dHBOS0ZLRVJyZ1ZsR3RNZDhXTGV4SVE#gid=0
    genre record.map(&genre_map).flatten

    # dcterms:identifier
    #   001 [prefix ="Hathi: "]; 020 [prefix ="ISBN: "];
    #   022$a [prefix ="ISSN: "]; 035$a;
    #   050$a$b [prefix ="LC call number: "]
    identifier record.map(&identifier_map).flatten

    # dcterms:language
    #   041$a [$2 ids source, i.e. iso689-1]; OR 008 (positions 35-37)
    language class: DPLA::MAP::Controlled::Language,
             each: record.map(&language_map).flatten,
             as: :lang do
      prefLabel lang
    end

    # dcterms:spatial
    #   650$z; 651$a; 662 [see defs of subfield codes at http://www.loc.gov/marc/bibliographic/bd662.html]
    spatial class: DPLA::MAP::Place,
            each: record.map(&spatial_map).flatten,
            as: :place do
      providedLabel place
    end

    # dcterms:publisher
    #   260$a$b
    publisher class: DPLA::MAP::Agent,
              each: record.map(&publisher_map).flatten,
              as: :publisher do
      providedLabel publisher
    end

    # dc:relation
    #   760-787 (all tags)
    relation record.map(&relation_map).flatten

    # dc:rights
    #   https://issues.dp.la/issues/7517
    rights record.map(&rights_map).flatten

    # dcterms:subject
    #   600; 61X; 650; 651; 653; 654; 655; 656; 657; 658; 69X
    subject class: DPLA::MAP::Concept,
            each: record.map(&subject_map).flatten,
            as: :subject do
      providedLabel subject
    end

    # dcterms:temporal
    #   648
    temporal class: DPLA::MAP::TimeSpan,
             each: record.field('marc:datafield')
                         .match_attribute(:tag, '648')
                         .field('marc:subfield')
                         .match_attribute(:code, 'a'),
             as: :time do
      providedLabel time
    end

    # dcterms:title
    #   245 (all subfields except $c); 242; 240
    title record.map(&title_map).flatten

    # dcterms:type
    #   337$a; If leader position equals...
    #   see step one here: https://docs.google.com/spreadsheet/ccc?key=0ApDps8nOS9g5dHBOS0ZLRVJyZ1ZsR3RNZDhXTGV4SVE#gid=0
    #   when the value matches DCMIType
    dctype record.map(&dctype_map).flatten

    # dc:date
    #   260$c plus dates from the 008
    date record.map(&date_map).flatten
  end
end
