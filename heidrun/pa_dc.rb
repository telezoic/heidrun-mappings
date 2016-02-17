# If more than one dc:contributor property exists then it drops the last one
# If one or zero exist return nil
#
# @todo
# This should be rewriten once ValueArray supports array sliceing
# See ticket https://issues.dp.la/issues/8287
contributor_top = lambda do |r|
  contrib = r['dc:contributor']
  count = r['dc:contributor'].count
  (count > 1) ? contrib.first_value(count - 1) : contrib.last_value(0)
end

# If there is more than one dc:relation property than return all but the first
# instance of the property. If one or none then return an empty set
secondary_relations = lambda do |r|
  relation = r['dc:relation']
  count = r['dc:relation'].count
  (count > 1) ? relation.last_value( count-1 ) : relation.last_value(0)
end

# Extracts the second occurance of the dc:identifier property
second_identifier = lambda do |r|
  identifiers = r['dc:identifier']
  count = r['dc:identifier'].count
  (count > 1) ? identifiers.first_value(2).last_value : relation.last_value(0)
end

Krikri::Mapper.define(:pa_dc, :parser => Krikri::OaiDcParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/pennsylvania'
    label 'PA Digital'
  end

  originalRecord class: DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do

    collection record.field('dc:relation').first_value

    contributor :class => DPLA::MAP::Agent, :each => record.map( &contributor_top ).flatten, :as => :contributor_name do
      providedLabel contributor_name
    end

    creator :class => DPLA::MAP::Agent, :each => record.field('dc:creator'), :as => :creator do
      providedLabel creator
    end

    date :class =>DPLA::MAP::TimeSpan, :each => record.field('dc:date'), :as => :date do
      providedLabel date
    end

    description record.field('dc:description')

    # Dropping non-DCMI types handled in KriKri::Enrichments::MoveNonDcmiType
    dcformat record.field('dc:type')

    genre record.field('dc:type')

    language :class => DPLA::MAP::Controlled::Language, :each => record.field('dc:language'), :as => :lang do
      prefLabel lang
    end

    spatial :class => DPLA::MAP::Place, :each => record.field('dc:coverage'), :as => :place do
      providedLabel place
    end

    publisher record.field('dc:publisher')

    relation record.map( &secondary_relations ).flatten

    rights record.field('dc:rights')

    subject :class => DPLA::MAP::Concept, :each => record.field('dc:subject'), :as => :subject do
      providedLabel subject
    end

    title record.field('dc:title')

    # Dropping non-DCMI types handled in KriKri::Enrichments::MoveNonDcmiType
    dctype record.field('dc:type')
  end

  preview :class => DPLA::MAP::WebResource do
    fileFormat record.field('dc:format')
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('dc:contributor').last_value
  end

  isShownAt :class => DPLA::MAP::WebResource do
   uri record.map( &second_identifier ).flatten
  end

  intermediateProvider record.field('dc:source')

  preview :class => DPLA::MAP::WebResource do
    uri record.field('dc:identifier').last_value
  end
end
