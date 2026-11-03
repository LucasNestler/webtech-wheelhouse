module Api
  module V1
    class ServicesController < BaseController
      skip_before_action :require_token, only: [ :index, :show ]

      def index
        repairs_counts = RepairLineItem.group(:service_id).distinct.count(:repair_order_id)

        render json: Service.by_name.map { |service|
          service_document(service, repairs_counts.fetch(service.id, 0))
        }
      end

      def show
        service = Service.find(params[:id])

        render json: service_document(service, service.repair_orders.distinct.count)
      end

      def create
        service = Service.new(service_params)

        if service.save
          render json: service_document(service, 0), status: :created, location: api_v1_service_url(service)
        else
          render_errors service.errors.full_messages, :unprocessable_entity
        end
      rescue ActiveRecord::RangeError
        render_errors [ "Default price is too large" ], :unprocessable_entity
      end

      private

      def service_document(service, repairs_count)
        {
          id: service.id,
          name: service.name,
          price: money(service.default_price),
          repairs_count: repairs_count
        }
      end

      def service_params
        attributes = params.expect(service: [ :name, :default_price ])
        # PostgreSQL cannot store a null byte, and Rails raises before it gets there.
        raise ActionController::BadRequest if attributes[:name].to_s.include?("\0")

        attributes
      end
    end
  end
end
