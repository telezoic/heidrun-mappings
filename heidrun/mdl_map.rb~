Krikri::Mapper.define(:mdl_map,
  :parser => Krikri::JsonParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/mdl'
    label record.field('record', 'provider', 'name')
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('record', 'dataProvider')
    end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('record', 'isShownAt')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('record' 'object')
    

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
  
    collection :class => DPLA::MAP::Collection, :each => 
   	  header.field('record', 'sourceResource', 'collection', 'name'), :as => :coll do
  	  title coll
  	  self.description coll.field('record', 'sourceResource', 'collection', 'description', 'dc', 'description')
  	end

    contributor :class => DPLA::MAP::Agent, :each=>
    	record.field('record', 'sourceResource', 'contributor'), :as => :contributor
    	do
    	providedLabel contributor
    end
    
  	creator :class => DPLA::MAP::Agent, :each => 	
  	  record.field('record', 'sourceResource', 'creator'), :as => :creator do
   	  providedLabel creator
	end

  	date :class => DPLA::MAP::TimeSpan, :each => 
  	  record.field('record', 'sourceResource', 'date', 'displayDate'), :as => :created do
  	  providedLabel created
  	  self.begin created.field('record', 'sourceResource', 'date', 'begin')
  	  self.end created.field('record', 'sourceResource', 'date', 'end')
  	end

  	description record.field('record', 'sourceResource', 'description')

  	dcformat record.field('record', 'sourceResource', 'format')

  	genre record.field('record', 'sourceResource', 'type')
  	
  	language :class => DPLA::MAP::Controlled::Language, :each => 
  	  record.field('record', 'sourceResource', 'language', 'iso639_3'), :as => :lang do
  	  prefLabel lang
  	end
  	#also needs ('record', 'sourceResource', 'language', 'name')
  	
   	publisher :class => DPLA::MAP::Agent, :each => 	
  	  record.field('record', 'sourceResource', 'publisher'), :as => :publisher 
  	  do
   	  providedLabel publisher
	end
	
  	spatial :class => DPLA::MAP::Place, :each => 
  	  record.field('record', 'sourceResource', 'spatial', 'name'), :as => :place do
  	  providedLabel place
  	  self.lat ('record', 'sourceResource', 'spatial', 'coordinates')
  	  self.long('record', 'sourceResource', 'spatial', 'coordinates')
  	end

  	rights record.field('record', 'sourceResource', 'rights')

  	subject :class => DPLA::MAP::Concept, :each => 	
  	  record.field('record', 'sourceResource', 'subject', 'name'), :as => :subject do
  	  providedLabel subject
  	end

  	title record.field('record', 'sourceResource', 'title')

  	dctype record.field('record', 'sourceResource', 'type')
  end
end