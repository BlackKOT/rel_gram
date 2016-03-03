module RelGram
  class RelGramController < ActionController::Base
    def index
      @structure = RelGram::Structure.new.get_structure
    end
  end
end
