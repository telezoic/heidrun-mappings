module MappingTools

  module MARC
    module_function

    def genre(opts)
      genres = []
      args = [genres, opts]
      assign_language(*args) || assign_musical_score(*args) ||
        assign_manuscript(*args) || assign_maps(*args) ||
        assign_projected(*args) || assign_two_d(*args) ||
        assign_nonmusical_sound(*args) || assign_musical_sound(*args)
      genres << 'Government Document' if government_document?(opts[:cf_008])
      genres
    end

    def assign_language(genres, opts)
      if language_material?(opts[:leader])
        if monograph?(opts[:leader])
          genres << 'Book'
        elsif serial?(opts[:leader])
          if newspapers?(opts[:cf_008])
            genres << 'Newspapers'
          else
            genres << 'Serial'
          end
        elsif mono_component_part?(opts[:leader])
          genres << 'Book'
        else
          genres << 'Serial'
        end
        true
      else
        false
      end
    end

    def assign_musical_score(genres, opts)
      if notated_music?(opts[:leader]) || manu_notated_music?(opts[:leader])
        genres << 'Musical Score'
        true
      else
        false
      end
    end

    def assign_manuscript(genres, opts)
      if manu_lang_material?(opts[:leader])
        genres << 'Manuscript'
        true
      else
        false
      end
    end

    def assign_maps(genres, opts)
      if cart_material?(opts[:leader]) || manu_cart_material?(opts[:leader])
        genres << 'Maps'
        true
      else
        false
      end
    end

    # projected media
    def assign_projected(genres, opts)
      if projected_medium?(opts[:leader])
        if slide?(opts[:cf_007]) || transparency?(opts[:cf_007])
          genres << 'Photograph / Pictorial Works'
          true
        elsif film_video?(opts[:cf_007])
          genres << 'Film / Video'
          true
        else
          false
        end
      else
        false
      end
    end

    # two-dimensional nonprojectable graphic
    def assign_two_d(genres, opts)
      if two_d_nonproj_graphic?(opts[:leader])
        genres << 'Photograph / Pictorial Works'
        true
      else
        false
      end
    end

    def assign_nonmusical_sound(genres, opts)
      if nonmusical_sound?(opts[:leader])
        genres << 'Nonmusic Audio'
        true
      else
        false
      end
    end

    def assign_musical_sound(genres, opts)
      if musical_sound?(opts[:leader])
        genres << 'Music'
        true
      else
        false
      end
    end

    def language_material?(s)
      s[6] == 'a'
    end

    def monograph?(s)
      s[7] == 'm'
    end

    def newspapers?(s)
      s[21] == 'n'
    end

    def serial?(s)
      s[7] == 's'
    end

    # monographic component part
    def mono_component_part?(s)
      s[7] == 'a'
    end

    def notated_music?(s)
      s[6] == 'c'
    end

    # manuscript notated music
    def manu_notated_music?(s)
      s[6] == 'd'
    end

    # manuscript language material
    def manu_lang_material?(s)
      s[6] == 't'
    end

    # cartographic material
    def cart_material?(s)
      s[6] == 'e'
    end

    # manuscript cartographic material
    def manu_cart_material?(s)
      s[6] == 'f'
    end

    def projected_medium?(s)
      s[6] == 'g'
    end

    def slide?(s)
      s[1] == 's'
    end

    def transparency?(s)
      s[1] == 't'
    end

    def film_video?(s)
      %w(c d f o).include?(s[1])
    end

    # two-dimensional non-projectable graphic
    def two_d_nonproj_graphic?(s)
      s[6] == 'k'
    end

    # nonmusical sound recording
    def nonmusical_sound?(s)
      s[6] == 'i'
    end

    # musical sound recording
    def musical_sound?(s)
      s[6] == 'j'
    end

    def government_document?(s)
      %w(a c f i l m o s).include?(s[28])
    end
  end
end