## SMITHSONIAN ## LANGUAGE_MAP = {
## SMITHSONIAN ##   'multiple languages' => 'mul',
## SMITHSONIAN ## }
## SMITHSONIAN ## 
## SMITHSONIAN ## DATA_PROVIDER_MAP = {
## SMITHSONIAN ##   'GETTY_ROSETTA' => 'Getty Research Institute',
## SMITHSONIAN ##   'GETTY_OCP' => 'Getty Research Institute',
## SMITHSONIAN ## }
## SMITHSONIAN ## 
## SMITHSONIAN ## 
## SMITHSONIAN ## build_url = lambda { |p|
## SMITHSONIAN ##   source = p.root['control/sourceid'].first.value
## SMITHSONIAN ##   id = p.root['control/recordid'].first.value
## SMITHSONIAN ## 
## SMITHSONIAN ##   case source
## SMITHSONIAN ##   when 'GETTY_ROSETTA'
## SMITHSONIAN ##     "http://primo.getty.edu/primo_library/libweb/action/dlDisplay.do?vid=GRI&afterPDS=true&institution=01GRI&docId=" + id
## SMITHSONIAN ##   when 'GETTY_OCP'
## SMITHSONIAN ##     "http://primo.getty.edu/primo_library/libweb/action/dlDisplay.do?vid=GRI-OCP&afterPDS=true&institution=01GRI&docId=" + id
## SMITHSONIAN ##   end
## SMITHSONIAN ## }


Krikri::Mapper.define(:smithsonian,
                      :parser => Krikri::SmithsonianParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/smithsonian'
    label 'Smithsonian Institution'
  end

  collection :class => DPLA::MAP::Collection, :each => record.fields(['display', 'lds31'], ['display', 'lds32']), :as => :coll do
    title coll
  end



## SMITHSONIAN ##   dataProvider :class => DPLA::MAP::Agent do
## SMITHSONIAN ##     uri 'http://dp.la/api/contributor/getty'
## SMITHSONIAN ##     label record.field('control', 'sourceid').first_value.map { |i| DATA_PROVIDER_MAP.fetch(i.value, i.value) }
## SMITHSONIAN ##   end
## SMITHSONIAN ## 
## SMITHSONIAN ##   isShownAt :class => DPLA::MAP::WebResource do
## SMITHSONIAN ##     uri build_url
## SMITHSONIAN ##   end
## SMITHSONIAN ## 
## SMITHSONIAN ##   # FIXME: Thumbnails are currently looking strange in the data.  Issue on the Getty side, or something else amiss?
## SMITHSONIAN ##   # <thumbnail>$$Tgetty_rosetta_thumb</thumbnail>
## SMITHSONIAN ##   # preview :class => DPLA::MAP::WebResource do
## SMITHSONIAN ##   #   uri record.field('links', 'thumbnail')
## SMITHSONIAN ##   # end
## SMITHSONIAN ## 
## SMITHSONIAN ##   sourceResource :class => DPLA::MAP::SourceResource do
## SMITHSONIAN ## 
## SMITHSONIAN ##     title record.fields(['display', 'title'], ['display', 'lds03']).map { |v| v.value.split(";").map(&:strip) }.flatten
## SMITHSONIAN ## 
## SMITHSONIAN ## 
## SMITHSONIAN ## 
## SMITHSONIAN ##     contributor :class => DPLA::MAP::Agent,
## SMITHSONIAN ##                 :each => record.field('display', 'contributor').map { |i| i.value.split(";").map(&:strip)}.flatten,
## SMITHSONIAN ##                 :as => :contrib do
## SMITHSONIAN ##       providedLabel contrib
## SMITHSONIAN ##     end
## SMITHSONIAN ## 
## SMITHSONIAN ##     creator :class => DPLA::MAP::Agent,
## SMITHSONIAN ##             :each => record.field('display', 'creator'),
## SMITHSONIAN ##             :as => :creator do
## SMITHSONIAN ##       providedLabel creator
## SMITHSONIAN ##     end
## SMITHSONIAN ## 
## SMITHSONIAN ##     date :class => DPLA::MAP::TimeSpan,
## SMITHSONIAN ##          :each => record.field('display', 'creationdate').first_value,
## SMITHSONIAN ##          :as => :created do
## SMITHSONIAN ##       providedLabel created
## SMITHSONIAN ##     end
## SMITHSONIAN ## 
## SMITHSONIAN ##     description record.fields(['display', 'lds04'], ['display', 'lds28'], ['display', 'rights'])
## SMITHSONIAN ## 
## SMITHSONIAN ##     extent record.field('display', 'format')
## SMITHSONIAN ## 
## SMITHSONIAN ##     dcformat record.field('display', 'lds09')
## SMITHSONIAN ## 
## SMITHSONIAN ##     genre record.field('display', 'lds26')
## SMITHSONIAN ## 
## SMITHSONIAN ##     dctype record.field('display', 'lds26')
## SMITHSONIAN ## 
## SMITHSONIAN ##     identifier record.field('display', 'lds14').map { |v| v.value.split(";").map(&:strip) }.flatten
## SMITHSONIAN ## 
## SMITHSONIAN ##     language :class => DPLA::MAP::Controlled::Language,
## SMITHSONIAN ##              :each => record.field('display', 'language').map { |i| val = i.value.downcase; LANGUAGE_MAP.fetch(val, val) },
## SMITHSONIAN ##              :as => :lang do
## SMITHSONIAN ##       prefLabel lang
## SMITHSONIAN ##     end
## SMITHSONIAN ## 
## SMITHSONIAN ##     publisher :class => DPLA::MAP::Agent,
## SMITHSONIAN ##               :each => record.field('display', 'publisher').map { |i| i.value.split(";").map(&:strip)}.flatten,
## SMITHSONIAN ##               :as => :publisher do
## SMITHSONIAN ##       providedLabel publisher
## SMITHSONIAN ##     end
## SMITHSONIAN ## 
## SMITHSONIAN ##     relation record.fields(['links', 'lln04'], ['display', 'ispartof']).map { |v| v.value.split(";").map(&:strip) }.flatten
## SMITHSONIAN ## 
## SMITHSONIAN ##     rights record.field('display', 'lds27')
## SMITHSONIAN ## 
## SMITHSONIAN ##     # PrimoNMBib/record/display/subject (split on semi-colons)
## SMITHSONIAN ##     subject :class => DPLA::MAP::Concept,
## SMITHSONIAN ##             :each => record.field('display', 'subject').map { |v| v.value.split(";").map(&:strip) }.flatten,
## SMITHSONIAN ##             :as => :subject do
## SMITHSONIAN ##       providedLabel subject
## SMITHSONIAN ##     end
## SMITHSONIAN ##   end

end
