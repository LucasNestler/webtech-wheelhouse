class PagesController < ApplicationController
    def home
    end

    def services
        @jobs = [
            { name: "Chain Replacement", price: "$25" },
            { name: "Flat Tyre Repair", price: "$20" },
            { name: "Brake Adjustment", price: "$15" },
            { name: "Gear Adjustment", price: "$30" },
            { name: "Flat Tyre Repair", price: "$20" },
            { name: "Chain Replacement", price: "$25" },
            { name: "Derailleur / Shifting Adjustment", price: "$30" },
            { name: "Wheel True (Straightening)", price: "$35" },
            { name: "Brake Cable & Housing Replacement", price: "$35" },
            { name: "Hydraulic Brake Bleed", price: "$40" },
            { name: "Headset Service & Adjustment", price: "$45" },
            { name: "Bottom Bracket Service", price: "$50" }
            ]
            
    end

    def visit
    end

    def about
    end
end