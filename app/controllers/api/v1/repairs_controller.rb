module Api
  module V1
    class RepairsController < BaseController
      def index
        repairs = preloaded_repairs.by_promised_date

        if params.key?(:state)
          unless RepairOrder.statuses.key?(params[:state])
            return render_errors [ "state must be one of: #{RepairOrder.statuses.keys.join(", ")}." ], :bad_request
          end

          repairs = repairs.where(status: params[:state])
        end

        render json: repairs.map { |repair| repair_document(repair) }
      end

      def show
        render json: repair_document(preloaded_repairs.find(params[:id]))
      end

      private

      def preloaded_repairs
        RepairOrder.includes(bike: :customer, repair_line_items: :service)
      end

      def repair_document(repair)
        bike = repair.bike
        lines = repair.repair_line_items

        {
          id: repair.id,
          state: repair.status,
          came_in_on: repair.created_at.to_date,
          promised_on: repair.promised_on,
          picked_up_on: repair.picked_up_at&.to_date,
          bike: { brand: bike.make, model: bike.model, serial_number: bike.serial_number },
          customer: { name: bike.customer.name },
          lines: lines.map { |line| { service: line.service.name, price: money(line.charged_price) } },
          # Added up in Ruby: RepairOrder#total would run one query per repair.
          total: money(lines.sum(&:charged_price)),
          overdue: repair.overdue?,
          customer_answer: customer_answer(repair)
        }
      end

      def customer_answer(repair)
        case repair.quote_accepted
        when true then "approved"
        when false then "rejected"
        else "pending"
        end
      end
    end
  end
end
