class PagesController < ApplicationController
    def home
      authorize :page
    end

    def visit
      authorize :page
    end

    def about
      authorize :page
    end
end
