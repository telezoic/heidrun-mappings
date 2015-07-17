
def caribbean?(parser_value)
  parser_value.value.include?('Digital Library of the Caribbean')
end

# FIXME:  This is the original mapping that Gretchen was trying to express:
# It's clear what needs to be mapped, but I can not figure out how to go about
# it given the restraints of the DSL and my inability to debug the code below
# and on line 106. --MB
#
# extent record.fields(
#             [('marc:datafield').match_attribute(:tag, '300')
#                                .field('marc:subfield')
#                                .match_attribute(:code, 'a')],
#             [('marc:datafield').match_attribute(:tag, '300')
#                                .field('marc:subfield')
#                                .match_attribute(:code, 'c')],
#             [('marc:datafield').match_attribute(:tag, '340')
#                                .field('marc:subfield')
#                                .match_attribute(:code, 'b')]
# )
def extent_val(parser_value)
  return nil unless parser_value.node.attributes.include?('tag')
  if parser_value.node.attributes['tag'].value == '300'
    parser_value.node.children.each do |c|
      next unless c.attributes.include?('code')
      if ['a', 'c'].include?(c.attributes['code'].value)
        return c.text
      end
    end
  elsif parser_value.node.attributes['tag'].value == '340'
    parser_value.node.children.each do |c|
      next unless c.attributes.include?('code')
      return c.text if c.attributes['code'].value == 'b'
    end
  end
end


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

    # FIXME:  does not work.
    extent record.field('marc:datafield').map { |df| extent_val(df) }

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
