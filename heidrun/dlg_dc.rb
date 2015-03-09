def dlg_preview(identifier)
  id = identifier.rpartition(':').last.split('_', 3)
  return nil if id.count != 3
  "http://dlg.galileo.usg.edu/#{id[0]}/#{id[1]}/do-th:#{id[2]}"
end

Krikri::Mapper.define(:dlg_dc, :parser => Krikri::OaiDcParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/georgia'
    label 'Digital Library of Georgia'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('dc:contributor')
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('dc:identifier')
  end

  preview :class => DPLA::MAP::WebResource do
    uri header.field('xmlns:identifier').first_value.map { |i| dlg_preview(i.value) }
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    ##
    # TODO: Crosswalk says to take collection from OAI set name/description,
    # but we need to be able harvest set titles and populate them somewhere.
    # This will just pull back the setSpec code for now.
    collection :class => DPLA::MAP::Collection, :each => record.field('xmlns:header', 'xmlns:setSpec'), :as => :coll do
      title coll
    end

    creator :class => DPLA::MAP::Agent, :each => record.field('dc:creator'), :as => :creator do
      providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan, :each => record.field('dc:coverage'), :as => :coverage do
      providedLabel coverage
    end

    description record.fields('dc:description', 'dc:source')

    dcformat record.field('dc:format')

    # Selecting non-DCMIType values will be handled in enrichment
    genre record.field('dc:type')

    language :class => DPLA::MAP::Controlled::Language, :each => record.field('dc:language'), :as => :lang do
      prefLabel lang
    end

    spatial :class => DPLA::MAP::Place, :each => record.field('dc:coverage'), :as => :place do
      providedLabel place
    end

    relation record.field('dc:source')

    rights record.field('dc:rights')

    subject :class => DPLA::MAP::Concept, :each => record.field('dc:subject'), :as => :subject do
      providedLabel subject
    end

    title record.field('dc:title')

    # Selecting DCMIType-only values will be handled in enrichment
    dctype record.field('dc:type')
  end
end
