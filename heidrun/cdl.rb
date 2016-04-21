# In the Solr API there are two fields that relate to computing the URL for
# thumbnail image:
#   reference_image_md5: MD5 of the reference image CDL saved on harvest
#   reference_image_dimensions: Pixel width:height
#
# To get a thumbnail with this information, use this syntax:
#   https://thumbnails.calisphere.org/{mode}/{width}x{height}/{md5}
#
#  e.g.
#   https://thumbnails.calisphere.org/clip/1536:1024/39e015bc8fd770a69775811891784282
cdl_preview = lambda do |r|
  base_url = 'https://thumbnails.calisphere.org/clip/'
  # dimensions = r['reference_image_dimensions'].first.value
  md5_hash = r['reference_image_md5'].first.value
  image_url = nil

  if !md5_hash.nil? # && !dimensions.nil?
    image_url = base_url + '150x150/' + md5_hash
    # image_url = base_url + dimensions.gsub(':','x') + '/' + md5_hash
  end
  image_url
end

# if campus_name exists then dataProivder is campus name, else set to
# repository_name. If neither is set then return nil
cdl_provider = lambda do |r|
  campus_name = r['campus_name']
  repo_name = r['repository_name']
  provider = nil
  if !campus_name.nil?
    provider = campus_name
  elsif !repo_name.nil?
    provider = repo_name
  end
  provider
end

# California Digital Library Mapping
#
Krikri::Mapper.define(:cdl, parser: Krikri::JsonParser ) do
  provider class: DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/cdl'
    label 'California Digital Library'
  end

  originalRecord class: DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    alternative record.field('alternative_title_ss')

    collection :class => DPLA::MAP::Collection,
      :each => record.field('collection_name'),
      :as => :coll do
        title coll
    end

    contributor :class => DPLA::MAP::Agent,
      :each => record.field('contributor_ss'),
      :as => :contrib do
        providedLabel contrib
    end

    creator :class => DPLA::MAP::Agent,
      :each => record.field('creator_ss'),
      :as => :creator do
        providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan,
      :each => record.field('date_ss'),
      :as => :created do
      providedLabel created
    end

    description record.field('description_ss')

    extent record.field('extent_ss')

    dcformat record.field('format_ss')

    genre record.field('genre_ss')

    identifier record.field('identifier_ss')

    language :class => DPLA::MAP::Controlled::Language,
      :each => record.field('language_ss'),
      :as => :lang do
        prefLabel lang
    end

    spatial :class => DPLA::MAP::Place,
      :each => record.field('coverage_ss'),
      :as => :place do
        providedLabel place
    end

    publisher record.field('publisher_ss')

    relation record.field('relation_ss')

    rights record.fields('rights_ss', 'rights_note_ss', 'rights_date_ss')

    rightsHolder record.field('rights_holder_ss')

    subject :class => DPLA::MAP::Concept,
      :each => record.field('subject_ss'),
      :as => :subject do
        providedLabel subject
    end

    temporal class: DPLA::MAP::TimeSpan,
             each: record.field('temporal_ss'),
             as: :date_string do
      providedLabel date_string
    end

    title record.field('title_ss')

    dctype record.field('type_ss')
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.map( &cdl_provider ).flatten
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('url_item')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.map( &cdl_preview ).flatten
  end
end


