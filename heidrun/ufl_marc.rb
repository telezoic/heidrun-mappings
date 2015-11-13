
def subfield_e(df)
  df['marc:subfield'].match_attribute(:code, 'e')
end

contributor_select = lambda { |df|
  ['700', '710', '711', '720'].include?(df.tag) &&
    !['joint author', 'jt author'].include?(subfield_e(df))
}

creator_select = lambda { |df|
  ['100', '110', '111'].include?(df.tag) ||
    (df.tag == '700' && ['joint author', 'jt author'].include?(subfield_e(df)))
}

genre_map = lambda { |r|
  leader = Heidrun::MappingTools::MARC.leader_value(r)
  cf_007 = Heidrun::MappingTools::MARC.controlfield_values(r, '007')
  cf_008 = Heidrun::MappingTools::MARC.controlfield_values(r, '008')
  Heidrun::MappingTools::MARC.genre leader: leader,
                           cf_007: cf_007,
                           cf_008: cf_008
}

dctype_map = lambda { |r|
  leader = Heidrun::MappingTools::MARC.leader_value(r)
  cf_007 = Heidrun::MappingTools::MARC.controlfield_values(r, '007')
  df_337 = Heidrun::MappingTools::MARC.datafield_els(r, '337')
  df_337a = Heidrun::MappingTools::MARC.subfield_values(df_337, 'a')
  Heidrun::MappingTools::MARC.dctype leader: leader,
                            cf_007: cf_007,
                            df_337a: df_337a
}

identifier_map = lambda { |r|
  cf_001 = Heidrun::MappingTools::MARC.controlfield_values(r, '001')
  df_35 = Heidrun::MappingTools::MARC.datafield_els(r, '035')
  df_35a = Heidrun::MappingTools::MARC.subfield_values(df_35, 'a')
  df_50 = Heidrun::MappingTools::MARC.datafield_els(r, '050')

  df_50ab = df_50.map do |el|
    el.children
      .select { |c| c.name == 'subfield' && %w(a b).include?(c[:code]) }
      .map { |sf| sf.children.first.to_s }
  end

  [cf_001, df_35a, df_50ab.join(' ')].reject { |e| e.empty? }
}

title_map = lambda { |r|
  nodes = []  # Elements
  # These appended elements will be nil if the datafields
  # do not exist.  The array will be compacted below.
  nodes += Heidrun::MappingTools::MARC.datafield_els(r, '240')
  nodes += Heidrun::MappingTools::MARC.datafield_els(r, '242')

  df_245 = Heidrun::MappingTools::MARC.datafield_els(r, '245')

  df_245.each do |el|
    if !el.children.empty?
      nodes += el.children
                 .select { |c| c.name == 'subfield' \
                               && !%w(c h).include?(c[:code]) }
    end
  end

  # Inside of a subfield element, you still have a
  # `children` property with a single XML text node, so
  # these have to be mapped to an array of strings:
  nodes.compact.map { |n| n.children.first.to_s }
}

language_map = lambda { |r|
  df_041 = Heidrun::MappingTools::MARC.datafield_els(r, '041')
  df_041a = Heidrun::MappingTools::MARC.subfield_values(df_041, 'a')

  return df_041a if !df_041a.empty?

  cf_008 = Heidrun::MappingTools::MARC.controlfield_values(r, '008')
  cf_008.map { |cf| cf[35,3] }.reject { |s| s.nil? || s.empty? }
}

spatial_map = lambda { |r|
  df_752 = Heidrun::MappingTools::MARC.datafield_els(r, '752')
  df_752_subs = Heidrun::MappingTools::MARC.all_subfield_values(df_752)
                                           .join('--')
  df_650 = Heidrun::MappingTools::MARC.datafield_els(r, '650')
  df_650z = Heidrun::MappingTools::MARC.subfield_values(df_650, 'z')
  df_651 = Heidrun::MappingTools::MARC.datafield_els(r, '651')
  df_651a = Heidrun::MappingTools::MARC.subfield_values(df_651, 'a')
  df_662 = Heidrun::MappingTools::MARC.datafield_values(r, '662')
  df_662_subs = Heidrun::MappingTools::MARC.all_subfield_values(df_662)
  [df_752_subs, df_650z, df_651a, df_662_subs]
    .flatten.reject { |e| e.empty? }.uniq
}

subject_tag_pat = /^6(?:00|1\d|5(?:[01]|[3-8])|9\d)$/
subject_map = lambda { |r|
  all_dfs = Heidrun::MappingTools::MARC.datafield_els(r, subject_tag_pat)
  subjects = []
  all_dfs.each do |df|
    sfs = Heidrun::MappingTools::MARC.all_subfield_values([df])
    subjects << sfs.map { |f| f.strip }.join('--')
  end
  subjects.reject { |s| s.empty? }
}

relation_map = lambda { |r|
  dfs = Heidrun::MappingTools::MARC.datafield_els(r, /^78[07]$/)
  Heidrun::MappingTools::MARC.subfield_values(dfs, 't')
}

dcformat_map = lambda { |r|
  cf_007 = Heidrun::MappingTools::MARC.controlfield_values(r, '007')
  leader = Heidrun::MappingTools::MARC.leader_value(r)
  dfs = Heidrun::MappingTools::MARC.datafield_els(r, /^3(?:3[78]|40)$/)
  a_vals = Heidrun::MappingTools::MARC.subfield_values(dfs, 'a')
  formats = Heidrun::MappingTools::MARC.dcformat leader: leader,
                                        cf_007: cf_007
  (formats + a_vals).uniq
}

extent_map = lambda { |r|
  df_300 = Heidrun::MappingTools::MARC.datafield_els(r, '300')
  df_340 = Heidrun::MappingTools::MARC.datafield_els(r, '340')
  df_300a = Heidrun::MappingTools::MARC.subfield_values(df_300, 'a')
  df_300c = Heidrun::MappingTools::MARC.subfield_values(df_300, 'c')
  df_340b = Heidrun::MappingTools::MARC.subfield_values(df_340, 'b')
  [df_300a, df_300c, df_340b].flatten.reject { |e| e.empty? }
}

int_provider_map = lambda { |r|
  df_830 = Heidrun::MappingTools::MARC.datafield_els(r, '830')
  df_830a = Heidrun::MappingTools::MARC.subfield_values(df_830, 'a')
  df_997 = Heidrun::MappingTools::MARC.datafield_els(r, '997')
  df_997a = Heidrun::MappingTools::MARC.subfield_values(df_997, 'a')

  [df_830a, df_997a].each do |df|
    if df.include?('Digital Library of the Caribbean')
      return ['Digital Library of the Caribbean']
    end
  end
  []
}


Krikri::Mapper.define(:ufl_marc, :parser => Krikri::MARCXMLParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/ufl'
    label 'University of Florida Libraries'
  end

  dataProvider :class => DPLA::MAP::Agent,
               :each => record.field('marc:datafield')
                              .match_attribute(:tag, '535'),
               :as => :dataP do
    providedLabel dataP.field('marc:subfield').match_attribute(:code, 'a')
  end

  # intermediateProvider
  #   "Digital Library of the Caribbean" if either 830$a or 997$a match that
  #   string.
  intermediateProvider :class => DPLA::MAP::Agent,
                       :each => record.map(&int_provider_map).flatten,
                       :as => :ip do
    providedLabel ip
  end

  isShownAt :class => DPLA::MAP::WebResource,
            :each => record.field('marc:datafield')
                           .match_attribute(:tag, '856'),
            :as => :the_uri do
    uri the_uri.field('marc:subfield').match_attribute(:code, 'u')
  end

  preview :class => DPLA::MAP::WebResource,
          :each => record.field('marc:datafield')
                         .match_attribute(:tag, '992')
                         .field('marc:subfield')
                         .match_attribute(:code, 'a'),
          :as => :thumb do
    # There are URIs with space characters that produce errors without the
    # following substitution.  I'm restricting my processing to this because
    # anything else is beyond the scope of a mapping; this may be already. -MB
    uri thumb.map { |t| t.value.gsub(/ /) { '%20' } }
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do

    collection :class => DPLA::MAP::Collection, 
               :each => record.field('marc:datafield')
                              .match_attribute(:tag, '830'),
               :as => :coll do
      title coll.field('marc:subfield').match_attribute(:code, 'a')
    end

    # contributor:
    #   700$a, 710$a, 711$a, or 720$a when there is not a $e that says
    #   "joint author" or "jt author" – i.e. sometimes there will only be $a
    contributor :class => DPLA::MAP::Agent,
                :each => record.field('marc:datafield')
                               .select(&contributor_select),
                :as => :contrib do
      providedLabel contrib.field('marc:subfield').match_attribute(:code, 'a')
    end

    # creator:
    #   Take the value of $a for 100, 110, 111 and the value of $a for 700 if
    #   the value of $e is "joint author" or "jt author" ... so $a only is
    #   actually mapped.
    creator :class => DPLA::MAP::Agent,
            :each => record.field('marc:datafield')
                           .select(&creator_select),
            :as => :cre do
      providedLabel cre.field('marc:subfield').match_attribute(:code, 'a')
    end

    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('marc:datafield')
                        .match_attribute(:tag, '260'),
         :as => :date do
      providedLabel date.field('marc:subfield').match_attribute(:code, 'c')
    end

    # description
    #   5XX; not 538, 535, 536, 533, 510
    description record.field('marc:datafield')
                      .select { |df| df.tag[/^5(?!10|33|35|36|38)[0-9]{2}/] }
                      .field('marc:subfield')

    # extent
    #   300a; 300c; 340b
    extent record.map(&extent_map).flatten

    # genre
    #   See chart here [minus step two]:
    #   https://docs.google.com/spreadsheet/ccc?key=0ApDps8nOS9g5dHBOS0ZLRVJyZ1ZsR3RNZDhXTGV4SVE#gid=0
    genre record.map(&genre_map).flatten

    # dctype
    #   337$a
    #   See spreadsheet referenced above for genre.
    dctype record.map(&dctype_map).flatten

    # dcformat
    #   007 position 00 [see http://www.loc.gov/marc/bibliographic/bd007.html];
    #   position 06 in Leader [see “06 - Type of record“ here: http://www.loc.gov/marc/bibliographic/bdleader.html];
    #   337$a; 338$a; 340$a
    dcformat record.map(&dcformat_map).flatten

    # identifier
    #   001; 035$a;
    #   050$a$b (join strings with a space character)
    identifier record.map(&identifier_map).flatten

    # language
    #   041$a, or, failing that, 008 (positions 35-37)
    language :class => DPLA::MAP::Controlled::Language,
             :each => record.map(&language_map).flatten,
             :as => :lang do
      prefLabel lang
    end

    # spatial
    #   752 (join subfields with double hyphen);
    #   plus any of these: (650$z; 651$a; 662$[all subfields])
    #   [see defs of subfield codes at http://www.loc.gov/marc/bibliographic/bd662.html]
    spatial :class => DPLA::MAP::Place,
            :each => record.map(&spatial_map).flatten,
            :as => :place do
      providedLabel place
    end

    # publisher
    #   260$b  (http://www.loc.gov/marc/bibliographic/bd260.html)
    publisher :class => DPLA::MAP::Agent, 
              :each => record.field('marc:datafield')
                             .match_attribute(:tag, '260')
                             .field('marc:subfield')
                             .match_attribute(:code, 'b'),
              :as => :pub do
      providedLabel pub
    end

    # relation
    #   both 780$t and 787$t
    relation record.map(&relation_map).flatten

    rights record.field('marc:datafield').match_attribute(:tag, '506')
                   .field('marc:subfield').match_attribute(:code, 'a')

    # subject
    #   600; 61X; 650; 651; 653; 654; 655; 656; 657; 658; 69X
    #   (concatenate all alphabetic subfields within each datafield with double
    #   hyphens)
    subject :class => DPLA::MAP::Concept,
            :each => record.map(&subject_map).flatten,
            :as => :s do
      providedLabel s
    end

    # title
    #   245 (all subfields except $c and $h); 242; 240
    title record.map(&title_map).flatten

    # temporal
    #  648
    temporal :class => DPLA::MAP::TimeSpan,
             :each => record.field('marc:datafield')
                            .match_attribute(:tag, '648'),
             :as => :t do
      providedLabel t
    end
  end
end
