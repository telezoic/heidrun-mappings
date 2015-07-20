Krikri::Mapper.define(:ncdhc, :parser => Krikri::ModsParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/ncdhc'
    label 'North Carolina Digital Heritage Center'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('mods:note').match_attribute(:type, 'ownership')
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
    	 .match_attribute(:usage, 'primary display')
    	 .match_attribute(:access, 'object in context')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
    	 .match_attribute(:access, 'preview')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    
    collection :class => DPLA::MAP::Collection, 
    	       :each => header.field('xmlns:set_spec'), 
    	       :as => :coll do
      title coll
    end

    contributor :class => DPLA::MAP::Agent, 
    		:each => record.field('mods:name')
    		  	.select { |name| name['mods:role'].map(&:value).include?('contributor') }, 
    		:as => :contrib do
      providedLabel contrib.field('mods:namePart')
    end

    creator :class => DPLA::MAP::Agent, 
    	    :each => record.field('mods:name')
    		    .select { |name| name['mods:role'].map(&:value).include?('creator') }, 
    	    :as => :creator_role do
      providedLabel creator_role.field('mods:namePart')
    end

    date :class => DPLA::MAP::TimeSpan, 
    	 :each => record.field('mods:originInfo'), 
    	 :as => :created do
      providedLabel created.field('mods:dateCreated').match_attribute(:keyDate, 'yes')
      self.begin created.field('mods:dateCreated').match_attribute(:keyDate, 'yes').first_value
      self.end created.field('mods:dateCreated').match_attribute(:keyDate, 'yes').last_value
    end

    description record.field('mods:note').match_attribute(:type, 'content')

    dcformat record.field('mods:physicalDescription', 'mods:form')
    
    genre record.field('mods:physicalDescription', 'mods:form')

    identifier record.field('mods:identifier')

    language :class => DPLA::MAP::Controlled::Language, 
    	     :each => record.field('mods:language', 'mods:languageTerm'), 
    	     :as => :lang do
      providedLabel lang
    end

    spatial :class => DPLA::MAP::Place, 
    	    :each => record.field('mods:subject', 'mods:geographic'), 
    	    :as => :place do
      providedLabel place
    end

    publisher :class => DPLA::MAP::Agent, 
    	      :each => record.field('mods:originInfo'), 
    	      :as => :publisher do
      providedLabel publisher.field('mods:publisher')
    end
    
    relation record.field('mods:relatedItem')
    	      .fields(['mods:location', 'mods:url'], ['mods:titleInfo', 'mods:title'])
   
    rights record.field('mods:accessCondition')

    subject :class => DPLA::MAP::Concept, 
    	    :each => record.field('mods:subject'), 
    	    :as => :subject do
      providedLabel subject
    end

    title record.field('mods:titleInfo', 'mods:title')

    dctype record.field('mods:genre')
  end
end
