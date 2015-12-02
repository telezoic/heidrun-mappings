def kdl_preview(identifier)
  return nil unless identifier.start_with?('http://nyx.uky.edu/dips') &&
                    identifier.end_with?('.jpg')
  identifier.gsub(/\.jpg$/, '_tb.jpg')
end

Krikri::Mapper.define(:kdl_dc, parser: Krikri::OaiDcParser) do
  provider class: DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/kdl'
    label 'Kentucky Digital Library'
  end

  dataProvider class: DPLA::MAP::Agent do
    providedLabel record.field('dc:publisher')
  end

  isShownAt class: DPLA::MAP::WebResource do
    uri record.field('dc:identifier').last_value
  end

  object class: DPLA::MAP::WebResource do
    uri record.field('dc:relation').first_value
    dcformat record.field('dc:relation')
              .first_value
              .map { |fmt| Heidrun::MappingTools::File.extension_to_mimetype(fmt.value) }
  end

  preview class: DPLA::MAP::WebResource do
    uri record.field('dc:relation').first_value.map { |i| kdl_preview(i.value) }
    dcformat record.field('dc:relation')
              .first_value
              .map { |fmt| Heidrun::MappingTools::File.extension_to_mimetype(fmt.value) }
  end

  originalRecord class: DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource class: DPLA::MAP::SourceResource do
    collection class: DPLA::MAP::Collection,
               each: record.field('dc:source'),
               as: :coll do
      title coll
    end

    creator class: DPLA::MAP::Agent,
            each: record.field('dc:creator'),
            as: :creator do
      providedLabel creator
    end

    date class: DPLA::MAP::TimeSpan,
         each: record.field('dc:date').first_value,
         as: :created do
      providedLabel created
    end

    description record.field('dc:description')

    dcformat record.field('dc:format')

    language class: DPLA::MAP::Controlled::Language,
             each: record.field('dc:language'),
             as: :lang do
      providedLabel lang
    end

    spatial class: DPLA::MAP::Place,
            each: record.field('dc:coverage'),
            as: :place do
      providedLabel place
    end

    rights record.field('dc:rights')

    subject class: DPLA::MAP::Concept,
            each: record.field('dc:subject'),
            as: :subject do
      providedLabel subject
    end

    title record.field('dc:title')

    dctype record.field('dc:type')
  end
end
