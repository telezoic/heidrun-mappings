Krikri::Mapper.define(:mdl_map, :parser => Krikri::JsonParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/mdl'
    label record.field('record', 'provider')
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('record', 'dataProvider')
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('record', 'isShownAt')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('record' 'object')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
  
    collection :class => DPLA::MAP::Collection, :each => record.field('record', 'sourceResource', 'collection'), :as => :coll do
      title coll.field('title')
      description coll.field('description', 'dc', 'description')
    end
    #need to verify this mapping with MDL

    contributor :class => DPLA::MAP::Agent, :each=> record.field('record', 'sourceResource', 'contributor'), :as => :contributor do
      providedLabel contributor
    end
    
    creator :class => DPLA::MAP::Agent, :each => record.field('record', 'sourceResource', 'creator'), :as => :creator do
      providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan, :each => record.field('record', 'sourceResource', 'date', 'displayDate'), :as => :created do
      providedLabel created
      self.begin created.field('record', 'sourceResource', 'date', 'begin')
      self.end created.field('record', 'sourceResource', 'date', 'end')
    end

    description record.field('record', 'sourceResource', 'description')

    dcformat record.field('record', 'sourceResource', 'format')

    genre record.field('record', 'sourceResource', 'type')
    
    language :class => DPLA::MAP::Controlled::Language, :each => record.field('record', 'sourceResource', 'language'), :as => :lang do
      prefLabel lang.field('iso639_3')
      providedLabel lang.field('name')
    end
    #made a guess here, but probably wrong; will need to discuss at checkin
    
    publisher :class => DPLA::MAP::Agent, :each => record.field('record', 'sourceResource', 'publisher'), :as => :publisher do
      providedLabel publisher
    end
  
    spatial :class => DPLA::MAP::Place, :each => record.field('record', 'sourceResource', 'spatial'), :as => :place do
      providedLabel place.field('name')
      lat place.field('coordinates')
    end
#need to figure out how to map. their records have name, county, state, coordinates, and country sub-fields under spatial
    
    rights record.field('record', 'sourceResource', 'rights')

    subject :class => DPLA::MAP::Concept, :each => record.field('record', 'sourceResource', 'subject', 'name'), :as => :subject do
      providedLabel subject
    end

    title record.field('record', 'sourceResource', 'title')

    dctype record.field('record', 'sourceResource', 'type')
  end
end