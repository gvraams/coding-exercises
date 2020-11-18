class Api::V1::Base < ApplicationController
  def fetch_record_or_return_false(record, message)
    return record if record.present?

    message ||= "This record doesn't seem to exist anymore"

    render json: { message: message }, status: :not_found
    return false
  end
end
