# Mapping for Wisconsin
Krikri::Mapper.define(:wi_qdc,
                      :parser => Krikri::QdcParser,
                      :parser_args => '//dc_qual:qualifieddc') do

  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/wisconsin'
    label 'Recollection Wisconsin'
  end

  originalRecord class: DPLA::MAP::WebResource do
    uri record_uri
  end

  dataProvider :class => DPLA::MAP::Agent do
      providedLabel record.field('edm:dataProvider')
    end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('edm:isShownAt')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('edm:preview')
  end

  sourceResource :class => DPLA::MAP::SourceResource do

    alternative record.field('dct:alternative')

    collection :class => DPLA::MAP::Collection,
      :each => record.field('dct:isPartOf'),
      :as => :coll do
        title coll
    end

    contributor :class => DPLA::MAP::Agent,
      :each => record.field('dc:contributor'),
      :as => :contrib do
        providedLabel contrib
    end

    creator :class => DPLA::MAP::Agent,
      :each => record.field('dc:creator'),
      :as => :creator do
        providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan,
      :each => record.field('dc:date'),
      :as => :created do
      providedLabel created
    end

    description record.field('dc:description')

    dcformat record.field('dc:format')

    genre record.field('dc:format')

    identifier record.field('dc:identifier')

    language :class => DPLA::MAP::Controlled::Language,
      :each => record.field('dc:language'),
      :as => :lang do
        prefLabel lang
    end

    spatial :class => DPLA::MAP::Place,
      :each => record.field('dct:spatial'),
      :as => :place do
        providedLabel place
    end

    publisher record.field('dc:publisher')

    relation record.field('dc:relation')

    rights record.fields('dc:rights', 'dct:accessRights')

    rightsHolder record.field('dct:rightsHolder')

    subject :class => DPLA::MAP::Concept,
      :each => record.field('dc:subject'),
      :as => :subject do
        providedLabel subject
    end

    temporal class: DPLA::MAP::TimeSpan,
             each: record.field('dct:temporal'),
             as: :date_string do
      providedLabel date_string
    end

    title record.field('dc:title')

    dctype record.field('dc:type')
  end
end
