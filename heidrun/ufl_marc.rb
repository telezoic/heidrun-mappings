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

  # Not sure how to limit this to only those fields with the value "Digital
  # Library of the Caribbean." (the period is included in the MARC record)
  # Guessing here based on something in the ESDN map.  --GG
  intermediateProvider :class => DPLA::MAP::Agent,
                       :each => record.field('marc:datafield')
                                      .match_attribute(:tag, '830'),
                       :as => interP do
    providedLabel interP.field('marc:subfield')
                        .match_attribute(:code, 'a')
                        .select do |i|
                          i.map(&:value)
                           .include?('Digital Library of the Caribbean.')
                        end
  end
  
  isShownAt :class => DPLA::MAP::WebResource,
            :each => record.field('marc:datafield')
                           .match_attribute(:tag, '856'),
            :as => :URI do
    uri URI.field('marc:subfield').match_attribute(:code, 'u')
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

    #don't know how to do these but am keeping placeholder
    #contributor 

    #creator 

    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('marc:datafield')
                        .match_attribute(:tag, '260'),
         :as => :date do
      providedLabel date.field('marc:subfield').match_attribute(:code, 'c')
    end

    #description 

    # FIXME:
    # extent record.fields([('marc:datafield')
    #               .match_attribute(:tag, '300')
    #               .field('marc:subfield').match_attribute(:code, 'a')],
    #               [('marc:datafield').match_attribute(:tag, '300')
    #               .field('marc:subfield').match_attribute(:code, 'c')],
    #               [('marc:datafield').match_attribute(:tag, '340')
    #               .field('marc:subfield').match_attribute(:code, 'b')])

    #dcformat 
    
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
