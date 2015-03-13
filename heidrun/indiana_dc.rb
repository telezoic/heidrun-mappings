Krikri::Mapper.define(:indiana_dc,
                      :parser => Krikri::OaiDcParser)
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/indiana'
    label 'Indiana Memory'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('dc:contributor')
    end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('dc:identifier')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('dc:source')
    

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
  
    collection :class => DPLA::MAP::Collection, :each => 
   	  header.field('xmlns:setSpec'), :as => :coll do
  	  title coll
  	end

    creator :class => DPLA::MAP::Agent, :each => 	
  	  record.field('dc:creator'), :as => :creator do
   	  providedLabel creator
	end

  	date :class => DPLA::MAP::TimeSpan, :each => 
  	  record.field('dc:date'), :as => :created do
  	  providedLabel created
  	end

  	description record.field('dc:description')

  	dcformat record.fields('dc:format', 'dc:type')
  	  
  	genre record.field('dc:type')

  	language :class => DPLA::MAP::Controlled::Language, :each => 
  	  record.field('dc:language'), :as => :lang do
  	  prefLabel lang
  	end

  	spatial :class => DPLA::MAP::Place, :each => 
  	  record.field('dc:coverage'), :as => :place do
  	  providedLabel place
  	end

  	rights record.field('dc:rights')

  	subject :class => DPLA::MAP::Concept, :each => 	
  	  record.field('dc:subject'), :as => :subject do
  	  providedLabel subject
  	end

  	title record.field('dc:title')

  	dctype record.field('dc:type')
  end
end