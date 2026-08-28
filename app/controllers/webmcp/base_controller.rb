module Webmcp
  class BaseController < ApplicationController
    class InvalidParameter < StandardError; end

    allow_unauthenticated_access

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Resource not found" }, status: :not_found
    end

    rescue_from InvalidParameter do |error|
      render json: { error: error.message }, status: :unprocessable_content
    end

    private

    def result_limit
      return 10 if params[:limit].blank?

      limit = Integer(params[:limit], exception: false)
      raise InvalidParameter, "limit must be an integer between 1 and 20" unless limit&.between?(1, 20)

      limit
    end

    def usd_cents_parameter(name)
      return if params[name].blank?

      amount = BigDecimal(params[name].to_s)
      raise InvalidParameter, "#{name} must be a non-negative number" unless amount.finite? && amount >= 0

      (amount * 100).round.to_i
    rescue ArgumentError
      raise InvalidParameter, "#{name} must be a non-negative number"
    end

    def usd_amount(cents)
      cents.present? ? cents / 100.0 : nil
    end

    def numeric_average(value)
      value&.to_f&.round(1)
    end
  end
end
