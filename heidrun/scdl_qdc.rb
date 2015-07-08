Krikri::Mapper.define(:scdl_qdc,
                      :parser => Krikri::QdcParser,
                      :parser_args => '//qdc:qualifieddc') do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/scdl'
    label 'South Carolina Digital Library'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('dc:publisher').first_value
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('dc:identifier')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('dcterms:hasFormat')
    dcformat record.field('dc:format')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    collection :class => DPLA::MAP::Collection, :each => record.field('dcterms:isPartOf'), :as => :coll do
      title coll
    end

    contributor :class => DPLA::MAP::Agent, :each => record.field('dc:contributor'), :as => :contrib do
      providedLabel contrib
    end

    creator :class => DPLA::MAP::Agent, :each => record.field('dc:creator'), :as => :creator do
      providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan, :each => record.field('dc:date'), :as => :created do
      providedLabel created
    end

    description record.field('dc:description')

    extent record.field('dcterms:extent')

    dcformat record.field('dcterms:medium')
    
    genre record.field('dcterms:medium')

    language :class => DPLA::MAP::Controlled::Language, :each => record.field('dc:language'), :as => :lang do
      prefLabel lang
    end

    spatial :class => DPLA::MAP::Place, :each => record.field('dcterms:spatial'), :as => :place do
      providedLabel place
    end

    relation record.field('dc:source')

    rights record.fields('dc:rights', 'dcterms:accessRights')
    
    rightsHolder record.field('dcterms:rightsholder')

    subject :class => DPLA::MAP::Concept, :each => record.field('dc:subject'), :as => :subject do
      providedLabel subject
    end

    title record.field('dc:title')

    dctype record.field('dc:type')
  end
end
