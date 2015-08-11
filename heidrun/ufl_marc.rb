
def caribbean?(parser_value)
  parser_value.value.include?('Digital Library of the Caribbean')
end

def subfield_e(df)
  df['marc:subfield'].match_attribute(:code, 'e')
end

contributor_select = lambda { |df|
  (df.tag == '700' &&
    !['joint author', 'jt author'].include?(subfield_e(df))) ||
  (['710', '711', '720'].include?(df.tag) &&
    !['aut', 'cre'].include?(subfield_e(df)))
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

  intermediateProvider :class => DPLA::MAP::Agent,
                       :each => record.field('marc:datafield')
                                      .match_attribute(:tag, '830')
                                      .field('marc:subfield')
                                      .match_attribute(:code, 'a')
                                      .select { |a| caribbean?(a) },
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
                         .match_attribute(:tag, '992'),
          :as => :thumb do
    uri thumb.field('marc:subfield').match_attribute(:code, 'a')
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
    #   700 when the subfield e is not 'joint author' or 'jt author';
    #   710; 711; 720 when the relator term (subfield e) is not 'aut' or 'cre'
    contributor :class => DPLA::MAP::Agent,
                :each => record.field('marc:datafield')
                               .select(&contributor_select),
                :as => :contrib do
      providedLabel contrib.field('marc:subfield')
    end

    #creator 

    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('marc:datafield')
                        .match_attribute(:tag, '260'),
         :as => :date do
      providedLabel date.field('marc:subfield').match_attribute(:code, 'c')
    end

    #description 

    extent record.field('marc:datafield')
            .match_attribute(:tag) { |tag| tag == '300' || tag == '340' }
            .select { |df| (df.tag == '300' && 
                           (!df['marc:subfield'].match_attribute(:code, 'a').empty? || 
                            !df['marc:subfield'].match_attribute(:code, 'c').empty?)) ||
                      (df.tag == '340' && 
                       !df['marc:subfield'].match_attribute(:code, 'b').empty?) }
            .field('marc:subfield')
    
    #genre 

    #identifier 

    #language 

    #spatial 

    publisher :class => DPLA::MAP::Agent, 
              :each => record.field('marc:datafield')
                             .match_attribute(:tag, '260'),
              :as => :pub do
      providedLabel pub.field('marc:subfield').match_attribute(:code, 'b')
    end
    
    # for relation below the mapping is to both 780$t and 787$t, not sure how
    # to combine attribute mappings in an OR relationship
    relation record.field('marc:datafield').match_attribute(:tag, '780')
                   .field('marc:subfield').match_attribute(:code, 't')            
                 
    rights record.field('marc:datafield').match_attribute(:tag, '506')
                   .field('marc:subfield').match_attribute(:code, 'a')

    #subject 

    #title 

    #dctype
  end
end
