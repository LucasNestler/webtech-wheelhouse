class PagesController < ApplicationController
    def home
    end

    def services
        @services = Service.where(active: true).order(:name)
            
    end

    def visit
    end

    def about
    end
end