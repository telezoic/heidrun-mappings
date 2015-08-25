Krikri::Mapper.define(:ct_dc, :parser => Krikri::OaiDcParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/georgia'
    label 'Connecticut Digital Library'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('dc:contributor').last_value
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('dc:identifier')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('dc:source')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    collection :class => DPLA::MAP::Collection, :each => record.field('xmlns:header', 'xmlns:setSpec'), :as => :coll do
      title coll
    end
    
    #the data provider appears as the last value in this field. Can we reject the ".last_value"?
    contributor :class => DPLA::MAP::Agent, 
    						:each => record.field('dc:contributor'), 
    						:as => :creator do
      providedLabel creator
    end
    
    creator :class => DPLA::MAP::Agent, :each => record.field('dc:creator'), :as => :creator do
      providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan, :each => record.field('dc:date'), :as => :date do
      providedLabel date
    end

    description record.field('dc:description')

    dcformat record.fields('dc:type', 'dc:format')

    language :class => DPLA::MAP::Controlled::Language, :each => record.field('dc:language'), :as => :lang do
      prefLabel lang
    end

    publisher :class => DPLA::MAP::Agent,
    					:each => record.field('dc:publisher'),
    					:as => :publisher do
    						providedLabel publisher
    end
    
    spatial :class => DPLA::MAP::Place, :each => record.field('dc:coverage'), :as => :place do
      providedLabel place
    end

    relation record.field('dc:relation')

    rights record.field('dc:rights')

    subject :class => DPLA::MAP::Concept, :each => record.field('dc:subject'), :as => :subject do
      providedLabel subject
    end

    title record.field('dc:title')

    dctype record.fields('dc:type', 'dc:format')
  end
end