Krikri::Mapper.define(:lc_json, :parser => Krikri::JsonParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/lc'
    label 'Library of Congress'
  end

  dataProvider :class => DPLA::MAP::Agent,
               :each => record.field('item', 'repository'),
               :as => :agent do
    providedLabel agent
  end

  isShownAt :class => DPLA::MAP::WebResource do
   uri record.field('item', 'id')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('resources').first_value.field('image')
  end

  sourceResource :class => DPLA::MAP::SourceResource do

    # collection

    contributor :class => DPLA::MAP::Agent, :each => record.field('item', 'contributor_names'), :as => :contributor do
      providedLabel contributor
    end

    creator :class => DPLA::MAP::Agent, :each => record.field('item', 'creator'), :as => :creator do
      providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan, :each => record.field('item', 'created_published'), :as => :date do
      providedLabel date
    end

    description record.field('item', 'description')

    # Dropping non-DCMI types handled in KriKri::Enrichments::MoveNonDcmiType
    dcformat record.field('item', 'original_format')

    genre record.field('item', 'original_format') # or item.genre?

    language :class => DPLA::MAP::Controlled::Language, :each => record.field('item', 'language'), :as => :lang do
      prefLabel lang # need to get the key, which is lowercase
    end

    spatial :class => DPLA::MAP::Place, :each => record.field('locations'), :as => :place do
      providedLabel place.field('properties', 'name') # needs work
      uri place.field('uris').first_value
      lat place.field('geometry', 'coordinates') # needs parsing
    end

    # publisher

    # relation

    rights record.field('item', 'rights')

    subject :class => DPLA::MAP::Concept, :each => record.field('item', 'subject_headings'), :as => :subject do
      providedLabel subject
    end

    title record.field('item', 'title')

    # Dropping non-DCMI types handled in KriKri::Enrichments::MoveNonDcmiType
    dctype record.field('item', 'online_format')
  end
end 