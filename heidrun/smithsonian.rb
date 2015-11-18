Krikri::Mapper.define(:smithsonian,
                      :parser => Krikri::SmithsonianParser) do

  # edm:provider
  #   Smithsonian Institution
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/smithsonian'
    label 'Smithsonian Institution'
  end

  # edm:preview
  #   <online_media><media @thumbnail>
  # TODO check this one
  preview :class => DPLA::MAP::WebResource,
          :each => record.field('online_media', 'media')
                         .match_attribute(:thumbnail),
          :as => :thumbnail do
     uri thumbnail.attribute('thumbnail')
  end

  # edm:isShownAt
  #   http://collections.si.edu/search/results.htm?q=record_ID%3A[<record_ID>[[value]]</record_ID>]&repo=DPLA
  # TODO build uri string
  #isShownAt :class => DPLA::MAP::WebResource do
  #  uri
  #end

  # dpla:originalRecord
  #   DPLA
  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  # dpla:SourceResource
  sourceResource :class => DPLA::MAP::SourceResource do

    # dcterms:isPartOf
    #   <freetext category=”setName” label=“[n]”>
    collection record.field('freetext', 'setName')

    # dcterms:contributor
    #  <name label="associated person">
    contributor :class => DPLA::MAP::Agent,
                :each => record.field('freetext', 'name').match_attribute(:label, 'associated person'),
                :as => :contributor do
      providedLabel contributor
    end

    # dcterms:creator
    #   <freetext category=”name” label=“[value]”>
    creator :class => DPLA::MAP::Agent,
            :each => record.field('freetext', 'name').match_attribute(:label) { |label| isCreator?(label) },
            :as => :creator do
      providedLabel creator
    end

    # dc:date
    #   <freetext category=”date” label=“[value]”>
    #   *Take earliest date
    # TODO only take earliest in a better way?
    date :class => DPLA::MAP::TimeSpan do
      providedLabel record.field('freetext', 'date').map(&:value).sort.first_value
    end

    # dcterms:description
    #   <freetext category="notes" label=“[n]”>[value]
    #   *Each instance of "notes" should be a separate value.
    description record.field('freetext', 'notes')

    # dcterms:extent
    #   <freetext category=”physicalDescription” label=“Dimensions”>
    extent record.field('freetext', 'physicalDescription').match_attribute(:label,'Dimensions')

    # dc:format
    #   <freetext category=”physicalDescription” label=“Physical description”>
    #   <freetext category=”physicalDescription” label=“Medium”>;
    #   <object_type>
    dcformat record.field('freetext', 'physicalDescription')
                   .match_attribute(:label) { |label| ['Physical description', 'Medium'].include?(label) }
    # TODO concat dcformat with: record.field('freetext', 'object_type')

    # dcterms:identifier
    #   <freetext category=”identifier” label=“Accession #”>
    #   <freetext category=”identifier” label=“Catalog #”>
    #   <record_ID>
    identifier record.field('freetext', 'identifier')
                     .match_attribute(:label) { |label| ['Accession #', 'Catalog #'].include?(label) }
                     .map(&:values)
                     .concat(record.field('record_ID').map(&:values))
    # TODO concat identifer with record_ID fields

    # dcterms:language
    #   <language> (not iso-6393 format)
    language record.field('language')

    # dcterms:spatial
    #   <geoLocation><L5 type=[City | Town]></geoLocation >;
    #   <geoLocation><L3 type=[State | Province]></geoLocation>;
    #   <geoLocation><L4 type=[County | Island]></geoLocation >;
    #   <geoLocation><Other type = [anything: examples = Neighborhood, Street, Desert, Park, etc.]></geoLocation>;
    #   <geoLocation><L2 type=[Country | Nation]></geoLocation>;
    #   <geoLocation><points label=[text] dates=”yyyy-yyyy”><point><latitude type=[decimal | degrees]><longitude type=[decimal | degrees]></point></geoLocation>;
    #   # IF NO GEOGRAPHIC HIERARCHY PROVIDED THEN: <freetext category=”place” label=“[n]”>[value];
    #   <place>[value]; <place label=""Origin"">[value] *Duplicate values should be ignored."
    # TODO check for all geoLocation fields and revert to place if there aren't any
    spatial :class => DPLA::MAP::Place,
            :each => record.field('geoLocation', 'L5')
                           .match_attribute(:type) {|type| ['City', 'Town'].include?(type)},
            :as => :place do
      providedLabel place
    end

    # dcterms:publisher
    #   <freetext category=”publisher” label=“publisher”>
    publisher :class => DPLA::MAP::Agent,
              :each => record.field('freetext', 'publisher')
                             .match_attribute(:label, 'publisher'),
              :as => :publisher do
      providedLabel publisher
    end

    # dc:rights
    #   <media ... rights="[value]"> OTHERWISE <freetext category=”creditLine” label=“Credit line”>;
    #   <freetext category=”objectRights” label=“Rights”>
    # TODO
    #rights

    # dcterms:subject
    #   <freetext category=”topic” label=“Topic”>;
    #   <freetext category=”culture” label=“Nationality”>;
    #   <topic>;<name>;<culture>;<tax_kingdom>; <tax_phylum>; <tax_division>; <tax_class>; <tax_order>;
    #   <tax_family>;  <tax_sub-family>; <scientific_name>; <common_name>;<strat_group>; <strat_formation>;
    #   <strat_member>
    #   n at least one record (http://content9.qa.dp.la/qa/compare?id=825ca339b107da76b17a1ba49f3e92fe ),
    #   there are @label values of "subject" and "event" which seem like they should also be mapped to Subject.
    # TODO
    #subject :class => DPLA::MAP::Concept,
    #        :each => ?,
    #        :as => :subject do
    #  providedLabel subject
    #end

    # dcterms:temporal
    #   <date>; <geo_age-era>; <geo_age-system>; <geo_age-series>; <geo_age-stage>
    # TODO
    #temporal :class => DPLA::MAP::TimeSpan,
    #         :each => ?,
    #         :as => :time do
    #  providedLabel time
    #end

    # dcterms:title
    #   <title label=”Title”> ;
    #   <title label=”Object Name”>;
    #   <title label=”Title (Spanish)”>
    title record.field('title')
                .match_attribute(:label) { |label| ['Title', 'Object Name', 'Title (Spanish)'].include?(label) }

    # dcterms:type
    #   <online media type>. If it does not match a DCMI type, map it to image
    # TODO default to image if no online_media_type element
    dctype record.field('indexedStructured', 'online_media_type')
  end

# TODO a few more mappings
# dc:rights <online_media_rights>
# edm:dataProvider  <data_source>
# dcterms:title <freetext category=”setName” label=“[n]”> *Note not all sets have names as of 2013-11-22
end


CREATOR_LABEL_VALUES = [
    "Architect",
    "Artist",
    "Artists/Makers",
    "Attributed to",
    "Author",
    "Cabinet Maker",
    "Ceramist",
    "Circle of",
    "Co-Designer",
    "Creator",
    "Decorator",
    "Designer",
    "Draftsman",
    "Editor",
    "Embroiderer",
    "Engraver",
    "Etcher",
    "Executor",
    "Follower of",
    "Graphic Designer",
    "Instrumentiste",
    "Inventor",
    "Landscape Architect",
    "Landscape Designer",
    "Maker",
    "Model Maker/maker",
    "Modeler",
    "Painter",
    "Photographer",
    "Possible attribution",
    "Possibly",
    "Possibly by",
    "Print Maker",
    "Printmaker",
    "Probably",
    "School of",
    "Sculptor",
    "Studio of",
    "Workshop of",
    "Weaver",
    "Writer",
    "animator",
    "architect",
    "artist",
    "artist.",
    "artist?",
    "artist attribution",
    "author",
    "author.",
    "author?",
    "authors?",
    "caricaturist",
    "cinematographer",
    "composer",
    "composer, lyricist",
    "composer; lyrcist",
    "composer; lyricist",
    "composer; performer",
    "composer; recording artist",
    "composer?",
    "creator",
    "creators",
    "designer",
    "developer",
    "director",
    "editor",
    "engraver",
    "ethnographer",
    "fabricator",
    "filmmaker",
    "filmmaker, anthropologist",
    "garden designer",
    "graphic artist",
    "illustrator",
    "inventor",
    "landscape Architect",
    "landscape architect",
    "landscape architect, photographer",
    "landscape designer",
    "lantern slide maker",
    "lithographer",
    "lyicist",
    "lyicrist",
    "lyricist",
    "lyricist; composer",
    "maker",
    "maker (possibly)",
    "maker or owner",
    "maker; inventor",
    "original artist",
    "performer",
    "performer; composer; lyricist",
    "performer; recording artist",
    "performers",
    "performing artist; recipient",
    "performing artist; user",
    "photgrapher",
    "photograher",
    "photographer",
    "photographer and copyright claimant",
    "photographer and/or colorist",
    "photographer or collector",
    "photographer?",
    "photographerl",
    "photographerphotographer",
    "photographers",
    "photographers?",
    "photographer}",
    "photographic firm",
    "photogrpaher",
    "playwright",
    "poet",
    "possible maker",
    "printer",
    "printmaker",
    "producer",
    "recordig artist",
    "recording artist",
    "recording artist; composer",
    "recordist",
    "recordng artist",
    "sculptor",
    "shipbuilder",
    "shipbuilders",
    "shipping firm",
    "weaver",
    "weaver or owner",
]

def isCreator?(value)
  CREATOR_LABEL_VALUES.include?(value)
end
