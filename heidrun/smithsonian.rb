# coding: utf-8

CREATOR_LABEL_VALUES = [
  'Architect',
  'Artist',
  'Artists/Makers',
  'Attributed to',
  'Author',
  'Cabinet Maker',
  'Ceramist',
  'Circle of',
  'Co-Designer',
  'Creator',
  'Decorator',
  'Designer',
  'Draftsman',
  'Editor',
  'Embroiderer',
  'Engraver',
  'Etcher',
  'Executor',
  'Follower of',
  'Graphic Designer',
  'Instrumentiste',
  'Inventor',
  'Landscape Architect',
  'Landscape Designer',
  'Maker',
  'Model Maker/maker',
  'Modeler',
  'Painter',
  'Photographer',
  'Possible attribution',
  'Possibly',
  'Possibly by',
  'Print Maker',
  'Printmaker',
  'Probably',
  'School of',
  'Sculptor',
  'Studio of',
  'Workshop of',
  'Weaver',
  'Writer',
  'animator',
  'architect',
  'artist',
  'artist.',
  'artist?',
  'artist attribution',
  'author',
  'author.',
  'author?',
  'authors?',
  'caricaturist',
  'cinematographer',
  'composer',
  'composer, lyricist',
  'composer; lyrcist',
  'composer; lyricist',
  'composer; performer',
  'composer; recording artist',
  'composer?',
  'creator',
  'creators',
  'designer',
  'developer',
  'director',
  'editor',
  'engraver',
  'ethnographer',
  'fabricator',
  'filmmaker',
  'filmmaker, anthropologist',
  'garden designer',
  'graphic artist',
  'illustrator',
  'inventor',
  'landscape Architect',
  'landscape architect',
  'landscape architect, photographer',
  'landscape designer',
  'lantern slide maker',
  'lithographer',
  'lyicist',
  'lyicrist',
  'lyricist',
  'lyricist; composer',
  'maker',
  'maker (possibly)',
  'maker or owner',
  'maker; inventor',
  'original artist',
  'performer',
  'performer; composer; lyricist',
  'performer; recording artist',
  'performers',
  'performing artist; recipient',
  'performing artist; user',
  'photgrapher',
  'photograher',
  'photographer',
  'photographer and copyright claimant',
  'photographer and/or colorist',
  'photographer or collector',
  'photographer?',
  'photographerl',
  'photographerphotographer',
  'photographers',
  'photographers?',
  'photographer}',
  'photographic firm',
  'photogrpaher',
  'playwright',
  'poet',
  'possible maker',
  'printer',
  'printmaker',
  'producer',
  'recordig artist',
  'recording artist',
  'recording artist; composer',
  'recordist',
  'recordng artist',
  'sculptor',
  'shipbuilder',
  'shipbuilders',
  'shipping firm',
  'weaver',
  'weaver or owner'
]

def creator?(value)
  CREATOR_LABEL_VALUES.include?(value)
end

clean_language = lambda do |i|
  i.value.gsub(/ languages?/i, '')
end

is_shown_at_uri = lambda do |i|
  "http://collections.si.edu/search/results.htm?q=record_ID%3A#{i.value}&repo=DPLA"
end

extract_format = lambda do |record|
  format = record['freetext'].field('physicalDescription')
                             .match_attribute(:label) { |label|
    ['Physical description', 'Medium'].include?(label)
  }

  format.concat(record['indexedStructured'].field('object_type'))
end

# Number of records found ...
# Accession #         633
# Catalog #             0
# Accession Number 490639
# accession number  66758
# Catalog Number        0
# catalog number    67004
identifier_map = lambda do |record|
  identifier = record['freetext'].field('identifier')
                                 .match_attribute(:label) { |label|
                                   ['Accession #', 'Accession Number',
                                    'accession number',
                                    'Catalog #', 'Catalog Number',
                                    'catalog number'].include?(label)
                                 }

  identifier.concat(record['descriptiveNonRepeating'].field('record_ID'))
end

# "Credit line" should be "Credit Line"
rights_map = lambda do |record|
  rights = record['descriptiveNonRepeating']
    .field('online_media', 'media', '@rights')

  if rights.empty?
    rights = record['freetext'].field('creditLine')
      .match_attribute(:label, 'Credit Line')
  end

  rights.concat(record['freetext'].field('objectRights')
                  .match_attribute(:label, 'Rights'))
end

# dcterms:subject
#   <freetext category="topic" label="Topic">;
#   <freetext category="culture" label="Nationality">;
#   <topic>;<name>;<culture>;<tax_kingdom>; <tax_phylum>; <tax_division>;
#   <tax_class>; <tax_order>; <tax_family>;  <tax_sub-family>;
#   <scientific_name>; <common_name>;<strat_group>; <strat_formation>;
#   <strat_member>
#
#   n at least one record
#   (http://content9.qa.dp.la/qa/compare?id=825ca339b107da76b17a1ba49f3e92fe ),
#   there are @label values of "subject" and "event" which seem like they
#   should also be mapped to Subject.
#
# This produces duplicate subjects on some records
#   - an enrichment will be required to de-dup
subject_map = lambda do |record|
  subjects = record['freetext'].field('topic')
    .match_attribute(:label, 'Topic')

  subjects.concat(record['freetext'].field('culture')
                    .match_attribute(:label, 'Nationality'))

  # seems some of these can occur in freetext or indexedStructured
  # so playing it safe by looking for all in both
  subject_elements = ['topic', 'name', 'culture',
                      'tax_kingdom', 'tax_phylum',
                      'tax_division', 'tax_class',
                      'tax_order', 'tax_family',
                      'scientific_name', 'common_name',
                      'strat_group', 'strat_formation',
                      'strat_member']
  subjects.concat(record['freetext'].fields(*subject_elements))
  subjects.concat(record['indexedStructured'].fields(*subject_elements))

  # only <freetext><name> has label="subject"
  # sometimes it's label="Subject"
  #
  # I wonder if this is subject as in subject/object
  # rather than subject/topic and so shouldn't be included?
  #
  # also, there are others that have label="subject"
  # but they are <freetext><topic> so we're already
  # getting them above
  #
  # also, all cases of label="event" are in <freetext><topic>s
  subjects.concat(record['freetext']
                    .field('name')
                    .match_attribute(:label) { |label|
                      ['subject', 'Subject'].include?(label)
                    })
end

Krikri::Mapper.define(:smithsonian,
                      :parser => Krikri::SmithsonianParser) do
  # edm:provider
  #   Smithsonian Institution
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/smithsonian'
    label 'Smithsonian Institution'
  end

  dataProvider :class => DPLA::MAP::Agent do
    label record.field('descriptiveNonRepeating', 'data_source')
  end

  # edm:preview
  #   <online_media><media @thumbnail>
  preview :class => DPLA::MAP::WebResource,
          :each => record.field('descriptiveNonRepeating',
                                'online_media', 'media')
                         .match_attribute(:thumbnail)
                         .map { |f| f.node.attribute('thumbnail').value },
          :as => :thumbnail_uri do
    uri thumbnail_uri
  end

  hasView :class => DPLA::MAP::WebResource do
    rights record.field('indexedStructured', 'online_media_rights')
  end

  # edm:isShownAt
  #   http://collections.si.edu/search/results.htm? \
  #     q=record_ID%3A[<record_ID>[[value]]</record_ID>]&repo=DPLA
  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('descriptiveNonRepeating', 'record_ID')
              .map(&is_shown_at_uri)
  end

  # dpla:originalRecord
  #   DPLA
  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  # dpla:SourceResource
  sourceResource :class => DPLA::MAP::SourceResource do
    # dcterms:isPartOf
    #   <freetext category="setName" label="[n]">
    collection :class => DPLA::MAP::Collection,
               :each => record.field('freetext', 'setName'),
               :as => :collection do
      title collection
    end

    # dcterms:contributor
    #  <name label="associated person">
    contributor :class => DPLA::MAP::Agent,
                :each => record.field('freetext', 'name')
                               .match_attribute(:label, 'associated person'),
                :as => :contributor do
      providedLabel contributor
    end

    # dcterms:creator
    #   <freetext category="name" label="[value]">
    creator :class => DPLA::MAP::Agent,
            :each => record.field('freetext', 'name')
                           .match_attribute(:label) { |label| creator?(label) },
            :as => :creator do
      providedLabel creator
    end

    # dc:date
    #   <freetext category="date" label="[value]">
    #   *Take earliest date
    # Gretchen says (re only the earliest date):
    #   So the mapping need to map all dates to both `sourceResource.date`
    #   AND `sourceResource.temporal` and then we'll run enrichment on date
    #   in the next step.
    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('freetext', 'date'),
         :as => :date do
      providedLabel date
    end

    temporal :class => DPLA::MAP::TimeSpan,
         :each => record.field('freetext', 'date'),
         :as => :temporal do
      providedLabel temporal
    end

    # dcterms:description
    #   <freetext category="notes" label="[n]">[value]
    #   *Each instance of "notes" should be a separate value.
    description record.field('freetext', 'notes')

    # dcterms:extent
    #   <freetext category="physicalDescription" label="Dimensions">
    extent record.field('freetext', 'physicalDescription')
                 .match_attribute(:label, 'Dimensions')

    # dc:format
    #   <freetext category="physicalDescription" label="Physical description">
    #   <freetext category="physicalDescription" label="Medium">;
    #   <object_type>
    #
    # JB - actually I'm seeing this in indexedStructured
    # but the spec doesn't seem to care about the parent anyway
    dcformat record.map(&extract_format).flatten

    # dcterms:identifier
    #   <freetext category="identifier" label="Accession #">
    #   <freetext category="identifier" label="Catalog #">
    #   <record_ID>
    identifier record.map(&identifier_map).flatten

    # dcterms:language
    #   <language> (not iso-6393 format)
    # TODO: This will need an enrichment to convert to iso-6393
    language record.field('indexedStructured', 'language').map(&clean_language)

    # dcterms:spatial
    #   <geoLocation><L5 type=[City | Town]></geoLocation >;
    #   <geoLocation><L3 type=[State | Province]></geoLocation>;
    #   <geoLocation><L4 type=[County | Island]></geoLocation >;
    #   <geoLocation>
    #     <Other type =[eg: Neighborhood, Street, Desert, Park, etc.]>
    #   </geoLocation>;
    #   <geoLocation><L2 type=[Country | Nation]></geoLocation>;
    #   <geoLocation><points label=[text] dates="yyyy-yyyy"><point>
    #     <latitude type=[decimal | degrees]>
    #     <longitude type=[decimal | degrees]></point></geoLocation>;
    #   # IF NO GEOGRAPHIC HIERARCHY PROVIDED THEN:
    #      <freetext category="place" label="[n]">[value];
    #   <place>[value];
    #   <place label=""Origin"">[value] *Duplicate values should be ignored."
    spatial :class => DPLA::MAP::Place,
            :each => record.if
                           .field('indexedStructured', 'geoLocation')
                           .fields('L2', 'L3', 'L4', 'L5', 'points', 'Other')
                           .else { |r| r.field('freetext', 'place') },
            :as => :place do
      providedLabel place
      lat place.field('point', 'latitude')
      long place.field('point', 'longitude')
    end

    # dcterms:publisher
    #   <freetext category="publisher" label="publisher">
    publisher :class => DPLA::MAP::Agent,
              :each => record.field('freetext', 'publisher')
                             .match_attribute(:label, 'Publisher'),
              :as => :publisher do
      providedLabel publisher
    end
    # assuming a typo in the spec, seeing - label="Publisher"

    # dc:rights
    #   <media ... rights="[value]">
    #     OTHERWISE <freetext category="creditLine" label="Credit line">;
    #   <freetext category="objectRights" label="Rights">
    rights record.map(&rights_map).flatten

    # dcterms:subject
    #   <freetext category="topic" label="Topic">;
    #   <freetext category="culture" label="Nationality">;
    #   <topic>;<name>;<culture>;<tax_kingdom>; <tax_phylum>; <tax_division>;
    #   <tax_class>; <tax_order>; <tax_family>;  <tax_sub-family>;
    #   <scientific_name>; <common_name>;<strat_group>; <strat_formation>;
    #   <strat_member>
    #
    #   n at least one record
    #   http://content9.qa.dp.la/qa/compare?id=825ca339b107da76b17a1ba49f3e92fe
    #   there are @label values of "subject" and "event" which seem like they
    #   should also be mapped to Subject.
    subject :class => DPLA::MAP::Concept,
            :each => record.map(&subject_map).flatten,
            :as => :subject do
      providedLabel subject
    end

    # dcterms:temporal
    #   <date>; <geo_age-era>; <geo_age-system>; <geo_age-series>;
    #   <geo_age-stage>
    temporal :class => DPLA::MAP::TimeSpan,
             :each => record.field('indexedStructured')
                            .fields('date', 'geo_age-era', 'geo_age-system',
                                    'geo_age-series', 'geo_age-stage'),
             :as => :time do
      providedLabel time
    end

    # dcterms:title
    #   <title label="Title"> ;
    #   <title label="Object Name">;
    #   <title label="Title (Spanish)">
    title record.field('descriptiveNonRepeating', 'title')
                .match_attribute(:label) { |label|
                  ['Title', 'Object Name', 'Title (Spanish)'].include?(label)
                }

    # dcterms:type
    #   <online media type>. If it does not match a DCMI type, map it to image
    dctype record.field('indexedStructured', 'online_media_type')
    # TODO: should defaulting to 'Image' be handled as an enrichment? - JB
    # DCMI Types: Collection, Dataset, Event, Image, InteractiveResource,
    #             MovingImage, PhysicalObject, Service, Software, Sound,
    #             StillImage, Text
  end
end
